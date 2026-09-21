import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ai_model.dart';

// DownloadService model file ko app ke private local storage mein save karta hai.
class DownloadService {
  final Dio _dio = Dio();
  static const int _chunkCount = 8;
  static const int _maxChunkRetries = 3;
  static final Map<String, Future<File>> _activeDownloads =
      <String, Future<File>>{};

  Future<File> downloadModel(AIModel model,
      {required void Function(int received, int total) onProgress}) {
    final String key = '${model.id}:${model.downloadUrl}';
    final Future<File>? active = _activeDownloads[key];
    if (active != null) return active;
    final Future<File> download = _downloadModel(model, onProgress);
    _activeDownloads[key] = download;
    download.then<void>((_) => _activeDownloads.remove(key),
        onError: (Object error, StackTrace stackTrace) {
      _activeDownloads.remove(key);
    });
    return download;
  }

  Future<File> _downloadModel(
      AIModel model, void Function(int received, int total) onProgress) async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory modelsDirectory = Directory('${appDirectory.path}/models');
    await modelsDirectory.create(recursive: true);
    final String filePath = '${modelsDirectory.path}/${model.id}.gguf';
    final _RangeInfo? rangeInfo = await _probeRangeSupport(model.downloadUrl);
    if (rangeInfo == null) {
      // Server Range support nahi karta, isliye normal Dio stream use karo.
      await _dio.download(model.downloadUrl, filePath,
          onReceiveProgress: onProgress, deleteOnError: true);
      return File(filePath);
    }

    final File finalFile = File(filePath);
    if (await finalFile.exists() &&
        await finalFile.length() == rangeInfo.total) {
      onProgress(rangeInfo.total, rangeInfo.total);
      return finalFile;
    }
    if (await finalFile.exists()) await finalFile.delete();

    final int chunkSize = (rangeInfo.total + _chunkCount - 1) ~/ _chunkCount;
    final List<_Chunk> chunks = List<_Chunk>.generate(_chunkCount, (int index) {
      final int start = index * chunkSize;
      final int end = math.min(rangeInfo.total - 1, start + chunkSize - 1);
      return _Chunk(index, start, end,
          File('${modelsDirectory.path}/.${model.id}.part-$index'));
    });
    final Map<int, int> progressByChunk = <int, int>{};
    // Sirf poore chunks ko completed maano; adhoora temp data discard hoga.
    for (final _Chunk chunk in chunks) {
      if (await chunk.file.exists() &&
          await chunk.file.length() == chunk.length) {
        progressByChunk[chunk.index] = chunk.length;
      } else if (await chunk.file.exists()) {
        await chunk.file.delete();
      }
    }
    _reportProgress(progressByChunk, rangeInfo.total, onProgress);
    await Future.wait(chunks.map((chunk) async {
      if (progressByChunk[chunk.index] == chunk.length) return;
      await _downloadChunk(model.downloadUrl, chunk, progressByChunk,
          rangeInfo.total, onProgress);
    }));

    final int downloadedSize = progressByChunk.values.fold(0, (a, b) => a + b);
    if (downloadedSize != rangeInfo.total) {
      throw StateError('Downloaded model size does not match server size.');
    }

    final File mergeFile = File('$filePath.download');
    if (await mergeFile.exists()) await mergeFile.delete();
    final RandomAccessFile output = await mergeFile.open(mode: FileMode.write);
    try {
      for (final _Chunk chunk in chunks) {
        final List<int> bytes = await chunk.file.readAsBytes();
        if (bytes.length != chunk.length) {
          throw StateError('Chunk ${chunk.index} size is invalid.');
        }
        await output.writeFrom(bytes);
      }
    } finally {
      await output.close();
    }
    // Final GGUF tabhi publish karo jab merge ke baad exact size verify ho.
    if (await mergeFile.length() != rangeInfo.total) {
      await mergeFile.delete();
      throw StateError('Merged model size does not match server size.');
    }
    await mergeFile.rename(filePath);
    for (final _Chunk chunk in chunks) {
      if (await chunk.file.exists()) await chunk.file.delete();
    }
    onProgress(rangeInfo.total, rangeInfo.total);
    return finalFile;
  }

  Future<_RangeInfo?> _probeRangeSupport(String url) async {
    try {
      final Response<void> head = await _dio.head<void>(url);
      if (head.headers.value('accept-ranges')?.toLowerCase() != 'bytes') {
        return null;
      }
      // HEAD ke baad ek byte ka real probe karke 206 aur total size confirm karo.
      final Response<List<int>> probe = await _dio.request<List<int>>(url,
          options: Options(
              method: 'GET',
              responseType: ResponseType.bytes,
              headers: <String, String>{'Range': 'bytes=0-0'},
              validateStatus: (status) => status == 206));
      final RegExpMatch? match = RegExp(r'^bytes\s+0-0/(\d+)$')
          .firstMatch(probe.headers.value('content-range') ?? '');
      return match == null ? null : _RangeInfo(int.parse(match.group(1)!));
    } on DioException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _downloadChunk(
      String url,
      _Chunk chunk,
      Map<int, int> progressByChunk,
      int total,
      void Function(int received, int total) onProgress) async {
    final File tempFile = File('${chunk.file.path}.download');
    Object? lastError;
    for (int attempt = 1; attempt <= _maxChunkRetries; attempt++) {
      try {
        if (await tempFile.exists()) await tempFile.delete();
        await _dio.download(url, tempFile.path,
            options: Options(headers: <String, String>{
              'Range': 'bytes=${chunk.start}-${chunk.end}'
            }, validateStatus: (status) => status == 206),
            deleteOnError: false, onReceiveProgress: (int received, int _) {
          progressByChunk[chunk.index] = received;
          _reportProgress(progressByChunk, total, onProgress);
        });
        if (await tempFile.length() != chunk.length) {
          throw StateError('Chunk ${chunk.index} received an invalid size.');
        }
        await tempFile.rename(chunk.file.path);
        progressByChunk[chunk.index] = chunk.length;
        _reportProgress(progressByChunk, total, onProgress);
        return;
      } catch (error) {
        lastError = error;
        progressByChunk[chunk.index] = 0;
        _reportProgress(progressByChunk, total, onProgress);
        if (await tempFile.exists()) await tempFile.delete();
      }
    }
    throw StateError(
        'Chunk ${chunk.index} failed after $_maxChunkRetries tries: $lastError');
  }

  void _reportProgress(Map<int, int> progressByChunk, int total,
      void Function(int received, int total) onProgress) {
    final int received = progressByChunk.values.fold(0, (a, b) => a + b);
    onProgress(math.min(received, total), total);
  }

  Future<File> localModelFile(AIModel model) async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    return File('${appDirectory.path}/models/${model.id}.gguf');
  }

  Future<void> deleteModel(AIModel model) async {
    final File file = await localModelFile(model);
    if (await file.exists()) await file.delete();
  }
}

class _RangeInfo {
  final int total;

  const _RangeInfo(this.total);
}

class _Chunk {
  final int index;
  final int start;
  final int end;
  final File file;

  const _Chunk(this.index, this.start, this.end, this.file);

  int get length => end - start + 1;
}
