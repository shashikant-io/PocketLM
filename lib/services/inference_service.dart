import 'dart:io';
import 'dart:async';

import 'package:llama_flutter_android/llama_flutter_android.dart';

import '../models/ai_model.dart';
import 'download_service.dart';

class InferenceService {
  final DownloadService _downloadService;
  LlamaController? _controller;
  StreamSubscription<String>? _generationSubscription;
  Completer<void>? _generationCompletion;
  Future<void>? _stopInProgress;
  int _generationId = 0;
  AIModel? loadedModel;

  InferenceService({DownloadService? downloadService})
      : _downloadService = downloadService ?? DownloadService();

  Future<bool> loadModel(AIModel model) async {
    final File file = await _downloadService.localModelFile(model);
    if (!await file.exists()) {
      return false;
    }

    if (loadedModel?.id == model.id && _controller != null) {
      return true;
    }

    await dispose();
    final LlamaController controller = LlamaController();
    try {
      final GpuInfo gpuInfo = await controller.detectGpu();
      await controller.loadModel(
        modelPath: file.path,
        contextSize: 2048,
        threads: 4,
        gpuLayers: gpuInfo.recommendedGpuLayers,
      );
      _controller = controller;
      loadedModel = model;
      return true;
    } catch (error) {
      await controller.dispose();
      throw StateError('Model load failed: $error');
    }
  }

  Future<String> generateResponse(String prompt, {int maxTokens = 512}) async {
    final StringBuffer response = StringBuffer();
    await generateResponseStream(prompt, response.write, maxTokens: maxTokens);
    return response.toString();
  }

  Future<void> generateResponseStream(
      String prompt, void Function(String token) onToken,
      {int maxTokens = 512}) async {
    await stopGeneration();
    final LlamaController? controller = _controller;
    if (controller == null || loadedModel == null) {
      throw StateError('Pehle ek local model load karein.');
    }

    final int requestId = ++_generationId;
    final Completer<void> completion = Completer<void>();
    _generationCompletion = completion;
    late final StreamSubscription<String> subscription;
    subscription = controller.generateChat(
      messages: <ChatMessage>[
        ChatMessage(role: 'user', content: prompt),
      ],
      maxTokens: maxTokens,
      temperature: 0.7,
    ).listen(
      (String token) {
        if (requestId == _generationId) onToken(token);
      },
      onDone: () {
        if (identical(_generationSubscription, subscription)) {
          _generationSubscription = null;
        }
        if (identical(_generationCompletion, completion)) {
          _generationCompletion = null;
        }
        if (!completion.isCompleted) completion.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_generationSubscription, subscription)) {
          _generationSubscription = null;
        }
        if (identical(_generationCompletion, completion)) {
          _generationCompletion = null;
        }
        if (requestId == _generationId && !completion.isCompleted) {
          completion.completeError(StateError(
              'Local inference failed. Phone memory may be insufficient: $error'));
        } else if (!completion.isCompleted) {
          completion.complete();
        }
      },
    );
    _generationSubscription = subscription;
    try {
      await completion.future;
    } finally {
      if (identical(_generationSubscription, subscription)) {
        _generationSubscription = null;
      }
      if (identical(_generationCompletion, completion)) {
        _generationCompletion = null;
      }
    }
  }

  Future<void> stopGeneration() {
    final Future<void>? existingStop = _stopInProgress;
    if (existingStop != null) return existingStop;

    final StreamSubscription<String>? subscription = _generationSubscription;
    final Completer<void>? completion = _generationCompletion;
    final LlamaController? controller = _controller;
    _generationSubscription = null;
    _generationCompletion = null;
    ++_generationId;
    final Future<void> stop = () async {
      try {
        await controller?.stop();
      } finally {
        await subscription?.cancel();
        if (completion != null && !completion.isCompleted) {
          completion.complete();
        }
      }
    }();
    _stopInProgress = stop.whenComplete(() => _stopInProgress = null);
    return _stopInProgress!;
  }

  Future<void> dispose() async {
    await stopGeneration();
    final LlamaController? controller = _controller;
    _controller = null;
    loadedModel = null;
    if (controller != null) await controller.dispose();
  }
}
