import 'package:flutter/material.dart';

import '../models/ai_model.dart';
import '../services/download_service.dart';
import '../services/model_service.dart';
import '../utils/constants.dart';
import '../widgets/model_card.dart';

// Models screen catalog ko list karta hai aur selected model local storage mein rakhta hai.
class ModelsScreen extends StatefulWidget {
  final ModelService modelService;

  const ModelsScreen({super.key, required this.modelService});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  final DownloadService _downloadService = DownloadService();
  final Map<String, double> _progress = <String, double>{};
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    widget.modelService.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _download(AIModel model) async {
    setState(() {
      _downloadingId = model.id;
      _progress[model.id] = 0;
    });
    try {
      await _downloadService.downloadModel(model,
          onProgress: (int received, int total) {
        if (!mounted) return;
        setState(() => _progress[model.id] = total > 0 ? received / total : 0);
      });
      await widget.modelService.markDownloaded(model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${model.name} saved locally.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Model download failed. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        const Text('Available Models',
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface)),
        const SizedBox(height: 6),
        const Text('Download a model to start chatting with SLM locally.',
            style: TextStyle(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 20),
        ...ModelService.availableModels.map((model) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ModelCard(
                model: model,
                isDownloaded: widget.modelService.isDownloaded(model),
                isDownloading: _downloadingId == model.id,
                progress: _progress[model.id] ?? 0,
                onDownload: () => _download(model),
              ),
            )),
      ],
    );
  }
}
