import 'dart:convert';

class BenchmarkConfig {
  final int promptTokens;
  final int generationTokens;
  final int contextSize;
  final int batchSize;
  final int cpuThreads;
  final int gpuLayers;
  final int repetitions;

  const BenchmarkConfig({
    this.promptTokens = 512,
    this.generationTokens = 128,
    this.contextSize = 2048,
    this.batchSize = 512,
    this.cpuThreads = 4,
    this.gpuLayers = 0,
    this.repetitions = 3,
  });

  Map<String, Object> toJson() => <String, Object>{
        'promptTokens': promptTokens,
        'generationTokens': generationTokens,
        'contextSize': contextSize,
        'batchSize': batchSize,
        'cpuThreads': cpuThreads,
        'gpuLayers': gpuLayers,
        'repetitions': repetitions,
      };
}

class BenchmarkResult {
  final String id;
  final String modelId;
  final String modelName;
  final DateTime completedAt;
  final BenchmarkConfig config;
  final double promptTokensPerSecond;
  final double generationTokensPerSecond;
  final int totalMilliseconds;
  final double? peakMemoryPercent;

  const BenchmarkResult({
    required this.id,
    required this.modelId,
    required this.modelName,
    required this.completedAt,
    required this.config,
    required this.promptTokensPerSecond,
    required this.generationTokensPerSecond,
    required this.totalMilliseconds,
    this.peakMemoryPercent,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'modelId': modelId,
        'modelName': modelName,
        'completedAt': completedAt.toIso8601String(),
        'config': config.toJson(),
        'promptTokensPerSecond': promptTokensPerSecond,
        'generationTokensPerSecond': generationTokensPerSecond,
        'totalMilliseconds': totalMilliseconds,
        'peakMemoryPercent': peakMemoryPercent,
      };

  factory BenchmarkResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> config =
        (json['config'] as Map<dynamic, dynamic>).cast<String, dynamic>();
    return BenchmarkResult(
      id: json['id'] as String,
      modelId: json['modelId'] as String,
      modelName: json['modelName'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      config: BenchmarkConfig(
        promptTokens: config['promptTokens'] as int,
        generationTokens: config['generationTokens'] as int,
        contextSize: config['contextSize'] as int,
        batchSize: config['batchSize'] as int,
        cpuThreads: config['cpuThreads'] as int,
        gpuLayers: config['gpuLayers'] as int,
        repetitions: config['repetitions'] as int,
      ),
      promptTokensPerSecond: (json['promptTokensPerSecond'] as num).toDouble(),
      generationTokensPerSecond:
          (json['generationTokensPerSecond'] as num).toDouble(),
      totalMilliseconds: json['totalMilliseconds'] as int,
      peakMemoryPercent: (json['peakMemoryPercent'] as num?)?.toDouble(),
    );
  }
}

String encodeBenchmarkResults(List<BenchmarkResult> results) =>
    jsonEncode(results.map((result) => result.toJson()).toList());

List<BenchmarkResult> decodeBenchmarkResults(String? value) {
  if (value == null || value.isEmpty) return <BenchmarkResult>[];
  final List<dynamic> decoded = jsonDecode(value) as List<dynamic>;
  return decoded
      .map((item) =>
          BenchmarkResult.fromJson((item as Map<dynamic, dynamic>).cast()))
      .toList();
}
