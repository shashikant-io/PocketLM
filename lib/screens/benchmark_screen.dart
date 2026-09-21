import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ai_model.dart';
import '../models/benchmark_result.dart';
import '../services/benchmark_service.dart';
import '../services/device_info_service.dart';
import '../services/model_service.dart';
import '../utils/constants.dart';

class BenchmarkScreen extends StatefulWidget {
  final ModelService modelService;

  const BenchmarkScreen({super.key, required this.modelService});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  static const Color _background = AppColors.surface;
  static const Color _card = AppColors.surfaceLow;
  static const Color _border = AppColors.surfaceHigh;
  static const Color _muted = AppColors.onSurfaceVariant;
  static const Color _accent = AppColors.onSurface;
  static const Color _danger = Color(0xffb3261e);

  final BenchmarkService _benchmarkService = BenchmarkService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  DeviceInfo _deviceInfo = const DeviceInfo(<String, String>{});
  List<BenchmarkResult> _results = <BenchmarkResult>[];
  AIModel? _selectedModel;
  BenchmarkConfig _config = const BenchmarkConfig();
  BenchmarkProgress? _progress;
  DateTime? _startedAt;
  bool _deviceExpanded = true;
  bool _settingsExpanded = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.modelService.initialize();
    final List<BenchmarkResult> results = await _benchmarkService.loadResults();
    final DeviceInfo deviceInfo = await _deviceInfoService.read();
    if (!mounted) return;
    final List<AIModel> models = _downloadedModels;
    setState(() {
      _results = results;
      _deviceInfo = deviceInfo;
      _selectedModel = models.isEmpty ? null : models.first;
      _loading = false;
    });
  }

  List<AIModel> get _downloadedModels => ModelService.availableModels
      .where(widget.modelService.isDownloaded)
      .toList();

  Future<void> _runBenchmark() async {
    final AIModel? model = _selectedModel;
    if (model == null) {
      setState(() => _error = 'Download a model first to run a benchmark.');
      return;
    }
    final DateTime started = DateTime.now();
    setState(() {
      _error = null;
      _startedAt = started;
      _progress = const BenchmarkProgress(0, Duration.zero, 'Preparing...');
    });
    try {
      final BenchmarkResult result = await _benchmarkService.run(model, _config,
          onProgress: (BenchmarkProgress progress) {
        if (mounted) setState(() => _progress = progress);
      });
      await _benchmarkService.saveResult(result);
      if (!mounted) return;
      setState(() {
        _results = <BenchmarkResult>[result, ..._results];
        _progress = null;
        _startedAt = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _progress = null;
        _startedAt = null;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  String _value(String key) => _deviceInfo.sections[key] ?? 'Unavailable';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
          color: _background,
          child: Center(child: CircularProgressIndicator(color: _accent)));
    }
    return ColoredBox(
      color: _background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: <Widget>[
          const Text('Benchmark',
              style: TextStyle(
                  color: _accent, fontSize: 27, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Measure local model performance on this device.',
              style: TextStyle(color: _muted)),
          const SizedBox(height: 18),
          _deviceCard(),
          const SizedBox(height: 12),
          _modelSelector(),
          const SizedBox(height: 12),
          _settingsCard(),
          const SizedBox(height: 14),
          if (_progress != null) _progressCard() else _startArea(),
          if (_results.isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            _sectionHeader('Test Results', 'Clear All', _clearResults),
            const SizedBox(height: 10),
            ..._results.map(_resultCard),
          ],
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) => Container(
        decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border)),
        child: child,
      );

  Widget _deviceCard() => _panel(
        child: ExpansionTile(
          initiallyExpanded: _deviceExpanded,
          onExpansionChanged: (bool value) => _deviceExpanded = value,
          iconColor: _muted,
          collapsedIconColor: _muted,
          title: const Text('Device Information',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
          subtitle: Text(_value('deviceName'),
              style: const TextStyle(color: _muted, fontSize: 12)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: <Widget>[
            _infoGroup('BASIC INFO', <String, String>{
              'Architecture': _value('architecture'),
              'Total Memory': _value('totalMemory'),
              'Device ID': _value('deviceId'),
              'Android': _value('androidVersion'),
            }),
            _infoGroup('CPU DETAILS', <String, String>{
              'CPU Cores': _value('cpuCores'),
              'Chipset': _value('chipset'),
              'Instruction support': _value('instructionSupport'),
            }),
            _infoGroup('GPU DETAILS', <String, String>{
              'GPU Type': _value('gpuType'),
              'Renderer': _value('renderer'),
              'Vendor': _value('vendor'),
              'OpenCL Support': _value('openCl'),
            }),
            _infoGroup('HEXAGON DSP', <String, String>{'DSP': _value('dsp')}),
            _infoGroup('APP INFO', <String, String>{'App Version': '1.0'}),
          ],
        ),
      );

  Widget _infoGroup(String title, Map<String, String> values) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              ...values.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: <Widget>[
                      Expanded(
                          child: Text(entry.key,
                              style: const TextStyle(
                                  color: _muted, fontSize: 12))),
                      Flexible(
                          child: Text(entry.value,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _accent, fontSize: 12))),
                    ]),
                  )),
            ]),
      );

  Widget _modelSelector() {
    final List<AIModel> models = _downloadedModels;
    return _panel(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: models.isEmpty
                ? const Text('Download a model first to run a benchmark.',
                    style: TextStyle(color: _danger, fontSize: 13))
                : DropdownButtonHideUnderline(
                    child: DropdownButton<AIModel>(
                        value: _selectedModel,
                        isExpanded: true,
                        dropdownColor: _card,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: _muted),
                        style: const TextStyle(color: _accent, fontSize: 15),
                        items: models
                            .map((model) => DropdownMenuItem<AIModel>(
                                value: model, child: Text(model.name)))
                            .toList(),
                        onChanged: _progress == null
                            ? (AIModel? model) =>
                                setState(() => _selectedModel = model)
                            : null))));
  }

  Widget _settingsCard() => _panel(
        child: ExpansionTile(
          initiallyExpanded: _settingsExpanded,
          onExpansionChanged: (bool value) => _settingsExpanded = value,
          iconColor: _muted,
          collapsedIconColor: _muted,
          leading: const Icon(Icons.tune_rounded, color: _muted, size: 20),
          title: const Text('Advanced Settings',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
          children: <Widget>[
            _setting(
                'Prompt Tokens',
                _config.promptTokens,
                (value) => _config = BenchmarkConfig(
                    promptTokens: value,
                    generationTokens: _config.generationTokens,
                    contextSize: _config.contextSize,
                    batchSize: _config.batchSize,
                    cpuThreads: _config.cpuThreads,
                    gpuLayers: _config.gpuLayers,
                    repetitions: _config.repetitions)),
            _setting(
                'Token Generation',
                _config.generationTokens,
                (value) => _config = BenchmarkConfig(
                    promptTokens: _config.promptTokens,
                    generationTokens: value,
                    contextSize: _config.contextSize,
                    batchSize: _config.batchSize,
                    cpuThreads: _config.cpuThreads,
                    gpuLayers: _config.gpuLayers,
                    repetitions: _config.repetitions)),
            _setting(
                'Context Size',
                _config.contextSize,
                (value) => _config = BenchmarkConfig(
                    promptTokens: _config.promptTokens,
                    generationTokens: _config.generationTokens,
                    contextSize: value,
                    batchSize: _config.batchSize,
                    cpuThreads: _config.cpuThreads,
                    gpuLayers: _config.gpuLayers,
                    repetitions: _config.repetitions)),
            _setting(
                'CPU Threads',
                _config.cpuThreads,
                (value) => _config = BenchmarkConfig(
                    promptTokens: _config.promptTokens,
                    generationTokens: _config.generationTokens,
                    contextSize: _config.contextSize,
                    batchSize: _config.batchSize,
                    cpuThreads: value,
                    gpuLayers: _config.gpuLayers,
                    repetitions: _config.repetitions)),
          ],
        ),
      );

  Widget _setting(String label, int value, void Function(int) update) =>
      ListTile(
        dense: true,
        title: Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
        trailing: Wrap(children: <Widget>[
          IconButton(
              onPressed: value > 1 && _progress == null
                  ? () => setState(() => update(value - 1))
                  : null,
              icon: const Icon(Icons.remove, size: 17),
              color: _muted),
          SizedBox(
              width: 42,
              child: Center(
                  child:
                      Text('$value', style: const TextStyle(color: _accent)))),
          IconButton(
              onPressed: _progress == null
                  ? () => setState(() => update(value + 1))
                  : null,
              icon: const Icon(Icons.add, size: 17),
              color: _muted),
        ]),
      );

  Widget _startArea() => Column(children: <Widget>[
        if (_error != null)
          Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                  color: const Color(0xffffdad6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _danger.withValues(alpha: .55))),
              child: Text(_error!, style: const TextStyle(color: _danger))),
        SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: _runBenchmark,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11))),
                child: const Text('Start Test',
                    style: TextStyle(fontWeight: FontWeight.w700)))),
      ]);

  Widget _progressCard() {
    final Duration elapsed = _startedAt == null
        ? Duration.zero
        : DateTime.now().difference(_startedAt!);
    return _panel(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Running Benchmark...',
                      style: TextStyle(
                          color: _accent, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Please keep the app open',
                      style: TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                      value: _progress!.progress,
                      color: _accent,
                      backgroundColor: _border),
                  const SizedBox(height: 10),
                  Text(
                      '${(_progress!.progress * 100).round()}%  •  Elapsed ${elapsed.inSeconds}s',
                      style: const TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 14),
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      color: AppColors.surfaceHigh,
                      child: Text('[INFO] ${_progress!.stage}',
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontFamily: 'monospace',
                              fontSize: 12))),
                ])));
  }

  Widget _sectionHeader(String title, String action, VoidCallback onPressed) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title,
              style: const TextStyle(
                  color: _accent, fontSize: 19, fontWeight: FontWeight.w700)),
          TextButton(
              onPressed: onPressed,
              child: Text(action, style: const TextStyle(color: _danger))),
        ],
      );

  Widget _resultCard(BenchmarkResult result) => _panel(
        child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: <Widget>[
                    Expanded(
                        child: Text(result.modelName,
                            style: const TextStyle(
                                color: _accent, fontWeight: FontWeight.w700))),
                    IconButton(
                        onPressed: () => _deleteResult(result),
                        icon: const Icon(Icons.delete_outline,
                            color: _muted, size: 20)),
                  ]),
                  Text(result.completedAt.toLocal().toString(),
                      style: const TextStyle(color: _muted, fontSize: 11)),
                  const Divider(color: _border, height: 22),
                  Text(
                      'Prompt: ${result.config.promptTokens} • Generation: ${result.config.generationTokens} • Repetitions: ${result.config.repetitions}',
                      style: const TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 12),
                  const Text('Performance',
                      style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  Text(
                      '${result.promptTokensPerSecond.toStringAsFixed(2)} t/s prompt  •  ${result.generationTokensPerSecond.toStringAsFixed(2)} t/s generation',
                      style: const TextStyle(color: _accent)),
                  const SizedBox(height: 4),
                  Text('Total time: ${result.totalMilliseconds} ms',
                      style: const TextStyle(color: _muted, fontSize: 12)),
                ])),
      );

  Future<void> _deleteResult(BenchmarkResult result) async {
    await _benchmarkService.deleteResult(result.id);
    if (mounted)
      setState(() => _results.removeWhere((item) => item.id == result.id));
  }

  Future<void> _clearResults() async {
    await _benchmarkService.clearResults();
    if (mounted) setState(() => _results = <BenchmarkResult>[]);
  }
}
