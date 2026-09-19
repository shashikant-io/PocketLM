import 'package:flutter/material.dart';

import '../models/ai_model.dart';
import '../utils/constants.dart';

// Model card frontend ke compact card, metadata aur download state ko show karta hai.
class ModelCard extends StatelessWidget {
  final AIModel model;
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final VoidCallback onDownload;

  const ModelCard(
      {super.key,
      required this.model,
      required this.isDownloaded,
      required this.isDownloading,
      required this.progress,
      required this.onDownload});

  IconData get _modelIcon => model.id.contains('bonsai')
      ? Icons.park_outlined
      : model.id.contains('phi')
          ? Icons.circle_outlined
          : model.id.contains('qwen')
              ? Icons.hexagon_outlined
              : Icons.auto_awesome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceHigh)),
      child: Row(
        children: <Widget>[
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Icon(_modelIcon, color: AppColors.primary, size: 28)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                Text(model.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Text('${model.sizeLabel} • ${model.category}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant)),
                if (isDownloading) ...<Widget>[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                      value: progress,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryFixed),
                ],
              ])),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: isDownloading || isDownloaded ? null : onDownload,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12)),
            icon: Icon(isDownloaded ? Icons.check : Icons.download_rounded,
                size: 17),
            label: Text(
                isDownloaded
                    ? 'Saved'
                    : isDownloading
                        ? '${(progress * 100).round()}%'
                        : 'Download',
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
