import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_model.dart';
import '../models/benchmark_result.dart';
import 'download_service.dart';
import 'inference_service.dart';

class BenchmarkProgress {
  final double progress;
  final Duration elapsed;
  final String stage;

  const BenchmarkProgress(this.progress, this.elapsed, this.stage);
}

class BenchmarkService {
  static const String _resultsKey = 'benchmark_results';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final DownloadService _downloadService;
  final InferenceService _inferenceService;

  BenchmarkService({
    DownloadService? downloadService,
    InferenceService? inferenceService,
  })  : _downloadService = downloadService ?? DownloadService(),
        _inferenceService = inferenceService ?? InferenceService();

  Future<List<BenchmarkResult>> loadResults() async =>
      decodeBenchmarkResults(await _preferences.getString(_resultsKey));

  Future<void> deleteResult(String id) async {
    final List<BenchmarkResult> results = await loadResults();
    results.removeWhere((result) => result.id == id);
    await _preferences.setString(_resultsKey, encodeBenchmarkResults(results));
  }

  Future<void> clearResults() => _preferences.remove(_resultsKey);

  Future<void> saveResult(BenchmarkResult result) async {
    final List<BenchmarkResult> results = await loadResults();
    await _preferences.setString(_resultsKey,
        encodeBenchmarkResults(<BenchmarkResult>[result, ...results]));
  }

  Future<BenchmarkResult> run(
    AIModel model,
    BenchmarkConfig config, {
    required void Function(BenchmarkProgress progress) onProgress,
  }) async {
    final bool exists =
        await (await _downloadService.localModelFile(model)).exists();
    if (!exists) throw StateError('Download a model first to run a benchmark.');

    final bool loaded = await _inferenceService.loadModel(model);
    if (!loaded) throw StateError('Unable to load the selected local model.');

    final String prompt = List<String>.filled(
            math.max(1, config.promptTokens), 'benchmark prompt token')
        .join(' ');
    final List<double> promptRates = <double>[];
    final List<double> generationRates = <double>[];
    final Stopwatch totalTimer = Stopwatch()..start();
    onProgress(BenchmarkProgress(0.08, totalTimer.elapsed, 'Model loaded'));

    for (int repetition = 0; repetition < config.repetitions; repetition++) {
      final Stopwatch generationTimer = Stopwatch()..start();
      Duration? firstTokenElapsed;
      int generatedCharacters = 0;
      await _inferenceService.generateResponseStream(
        prompt,
        (String token) {
          firstTokenElapsed ??= generationTimer.elapsed;
          generatedCharacters += token.length;
        },
        maxTokens: config.generationTokens,
      );
      generationTimer.stop();

      final Duration firstToken = firstTokenElapsed ?? generationTimer.elapsed;
      final int promptTokenEstimate = _estimateTokens(prompt);
      final int generatedTokenEstimate =
          math.max(1, _estimateTokens('x' * math.max(1, generatedCharacters)));
      promptRates.add(promptTokenEstimate /
          math.max(0.001, firstToken.inMicroseconds / 1000000));
      generationRates.add(generatedTokenEstimate /
          math.max(0.001, generationTimer.elapsedMicroseconds / 1000000));
      onProgress(BenchmarkProgress(
          0.08 + (0.92 * (repetition + 1) / config.repetitions),
          totalTimer.elapsed,
          'Completed repetition ${repetition + 1} of ${config.repetitions}'));
    }

    totalTimer.stop();
    return BenchmarkResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      modelId: model.id,
      modelName: model.name,
      completedAt: DateTime.now(),
      config: config,
      promptTokensPerSecond: _average(promptRates),
      generationTokensPerSecond: _average(generationRates),
      totalMilliseconds: totalTimer.elapsedMilliseconds,
      peakMemoryPercent: null,
    );
  }

  int _estimateTokens(String text) => math.max(1, (text.length / 4).round());

  double _average(List<double> values) =>
      values.reduce((double total, double value) => total + value) /
      values.length;
}
