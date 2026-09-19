import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ai_model.dart';

// DownloadService model file ko app ke private local storage mein save karta hai.
class DownloadService {
  final Dio _dio = Dio();

  Future<File> downloadModel(AIModel model,
      {required void Function(int received, int total) onProgress}) async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory modelsDirectory = Directory('${appDirectory.path}/models');
    await modelsDirectory.create(recursive: true);
    final String filePath = '${modelsDirectory.path}/${model.id}.gguf';
    await _dio.download(model.downloadUrl, filePath,
        onReceiveProgress: onProgress, deleteOnError: true);
    return File(filePath);
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
