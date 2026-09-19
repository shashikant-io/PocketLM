import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_model.dart';

// ModelService catalog aur locally downloaded models ki state manage karta hai.
class ModelService {
  static const String _downloadedKey = 'downloaded_model_ids';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final Set<String> _downloadedIds = <String>{};

  static final List<AIModel> availableModels = <AIModel>[
    AIModel(
        id: 'gemma-3-4b',
        name: 'Gemma 3 4B',
        version: '3',
        format: 'GGUF',
        quantization: 'Q4_K_M',
        size: 2370000000,
        sizeLabel: '2.37 GB',
        category: '8k Context',
        downloadUrl:
            'https://huggingface.co/lmstudio-community/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf'),
    AIModel(
        id: 'gemma-4-e2b',
        name: 'Gemma 4 E2B',
        version: '4',
        format: 'GGUF',
        quantization: 'Q4_K_M',
        size: 4030000000,
        sizeLabel: '4.03 GB',
        category: 'Multimodal Ex',
        downloadUrl:
            'https://huggingface.co/lmstudio-community/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf'),
    AIModel(
        id: 'bonsai-8b',
        name: 'Bonsai 8B',
        version: '1',
        format: 'GGUF',
        quantization: 'Q4_K_M',
        size: 1160000000,
        sizeLabel: '1.16 GB',
        category: 'Code & Logic',
        downloadUrl:
            'https://huggingface.co/lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf'),
    AIModel(
        id: 'phi-4-mini',
        name: 'Phi-4 Mini',
        version: '4',
        format: 'GGUF',
        quantization: 'Q4_K_M',
        size: 2330000000,
        sizeLabel: '2.33 GB',
        category: 'Fast Reasoning',
        downloadUrl:
            'https://huggingface.co/microsoft/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-q4.gguf'),
    AIModel(
        id: 'bonsai-4b',
        name: 'Bonsai 4B',
        version: '1',
        format: 'GGUF',
        quantization: 'Q4_K_M',
        size: 572270000,
        sizeLabel: '572.27 MB',
        category: 'Lightweight Agent',
        downloadUrl:
            'https://huggingface.co/lmstudio-community/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf'),
    AIModel(
        id: 'gemma-3-1b',
        name: 'Gemma 3 1B',
        version: '3',
        format: 'GGUF',
        quantization: 'Q4_K_M',
        size: 806060000,
        sizeLabel: '806.06 MB',
        category: 'Ultra Fast',
        downloadUrl:
            'https://huggingface.co/lmstudio-community/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf'),
    AIModel(
        id: 'qwen-2.5-3b',
        name: 'Qwen 2.5 3B',
        version: '2.5',
        format: 'GGUF',
        quantization: 'Q4_K_M',
        size: 1810000000,
        sizeLabel: '1.81 GB',
        category: 'General & Coding',
        downloadUrl:
            'https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf'),
    AIModel(
        id: 'tinyllama-1.1b',
        name: 'TinyLlama 1.1B',
        version: '1.1',
        format: 'GGUF',
        quantization: 'Q4_K_M',
        size: 637240000,
        sizeLabel: '637.24 MB',
        category: 'Extremely Compact',
        downloadUrl:
            'https://huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf'),
  ];

  Future<void> initialize() async {
    final List<String> savedIds =
        await _preferences.getStringList(_downloadedKey) ?? <String>[];
    _downloadedIds
      ..clear()
      ..addAll(savedIds);
  }

  bool isDownloaded(AIModel model) => _downloadedIds.contains(model.id);

  AIModel? get firstDownloadedModel {
    for (final AIModel model in availableModels) {
      if (isDownloaded(model)) return model;
    }
    return null;
  }

  Future<void> markDownloaded(AIModel model) async {
    _downloadedIds.add(model.id);
    await _preferences.setStringList(_downloadedKey, _downloadedIds.toList());
  }

  Future<void> removeDownloaded(AIModel model) async {
    _downloadedIds.remove(model.id);
    await _preferences.setStringList(_downloadedKey, _downloadedIds.toList());
  }
}
