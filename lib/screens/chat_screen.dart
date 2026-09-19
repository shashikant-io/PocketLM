import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/ai_model.dart';
import '../services/inference_service.dart';
import '../services/model_service.dart';
import '../utils/constants.dart';
import '../widgets/chat_message.dart';
import '../widgets/message_input.dart';

// Chat screen empty state se loaded local model conversation tak ka main flow hai.
class ChatScreen extends StatefulWidget {
  final ModelService modelService;
  final VoidCallback onOpenModels;

  const ChatScreen(
      {super.key, required this.modelService, required this.onOpenModels});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final InferenceService _inferenceService = InferenceService();
  final List<_ChatEntry> _messages = <_ChatEntry>[];
  static const Set<String> _stopCommands = <String>{
    'stop',
    'cancel',
    'ruk',
    'ruko',
    'ruk jao',
    'bas',
  };
  AIModel? _activeModel;
  bool _loading = true;
  bool _isGenerating = false;
  int _requestId = 0;
  int _nextMessageId = 0;
  int? _activeAiMessageId;

  @override
  void initState() {
    super.initState();
    _loadSavedModel();
  }

  @override
  void dispose() {
    ++_requestId;
    _activeAiMessageId = null;
    _inferenceService.dispose();
    super.dispose();
  }

  Future<void> _loadSavedModel() async {
    await widget.modelService.initialize();
    final AIModel? model = widget.modelService.firstDownloadedModel;
    if (model != null) await _inferenceService.loadModel(model);
    if (mounted)
      setState(() {
        _activeModel = model;
        _loading = false;
      });
  }

  Future<void> _sendMessage(String prompt) async {
    final String question = prompt.trim();
    if (_activeModel == null || question.isEmpty) return;

    if (_isGenerating && _stopCommands.contains(question.toLowerCase())) {
      await _stopGeneration();
      return;
    }

    final int requestId = ++_requestId;
    await _inferenceService.stopGeneration();
    if (!mounted || requestId != _requestId) return;
    final int aiMessageId = ++_nextMessageId;
    setState(() {
      _isGenerating = true;
      _activeAiMessageId = aiMessageId;
      _messages.add(_ChatEntry(
          id: ++_nextMessageId, text: question, isUser: true));
      _messages.add(
          _ChatEntry(id: aiMessageId, text: '', isUser: false));
    });
    try {
      await _inferenceService.generateResponseStream(question, (String token) {
        if (!mounted || requestId != _requestId) return;
        setState(() {
          final _ChatEntry? aiMessage = _findMessage(aiMessageId);
          if (aiMessage == null || aiMessage.id != _activeAiMessageId) return;
          aiMessage.text += token;
        });
      });
    } catch (error) {
      if (mounted && requestId == _requestId) {
        setState(() {
          final _ChatEntry? aiMessage = _findMessage(aiMessageId);
          if (aiMessage != null && aiMessage.id == _activeAiMessageId) {
            aiMessage.text = error.toString();
          }
        });
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() {
          _isGenerating = false;
          _activeAiMessageId = null;
        });
      }
    }
  }

  Future<void> _stopGeneration() async {
    ++_requestId;
    _activeAiMessageId = null;
    await _inferenceService.stopGeneration();
    if (mounted) setState(() => _isGenerating = false);
  }

  _ChatEntry? _findMessage(int messageId) {
    for (final _ChatEntry message in _messages) {
      if (message.id == messageId) return message;
    }
    return null;
  }

  Widget _emptyState() {
    return Center(
        child: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
          Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                  color: AppColors.primaryFixed, shape: BoxShape.circle),
              child: ClipOval(
                child: SvgPicture.asset(
                  'assets/model_logos/pocketlm_logo.svg',
                  fit: BoxFit.cover))),
          const SizedBox(height: 24),
          const Text(AppStrings.noModels,
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface)),
          const SizedBox(height: 8),
          const Text(AppStrings.emptyChatDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: widget.onOpenModels,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download Model'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 13))),
          const SizedBox(height: 24),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceHigh)),
              child: const Row(children: <Widget>[
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'Hi, Model not loaded. Please initialize the model to start conversation.'))
              ])),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    return Column(children: <Widget>[
      Expanded(
          child: _activeModel == null && _messages.isEmpty
              ? _emptyState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  children: <Widget>[
                      if (_activeModel != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text('${_activeModel!.name} • Local RAM',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant))),
                      ..._messages.map((entry) => ChatMessage(
                            text: entry.text,
                            isUser: entry.isUser,
                          )),
                      if (_isGenerating)
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary))),
                    ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: MessageInput(
              onSend: _sendMessage,
              onStop: _stopGeneration,
              isGenerating: _isGenerating,
              enabled: _activeModel != null,
              hintText: _activeModel == null
                  ? 'Initialize a model to chat...'
                  : 'What would you like to know...')),
    ]);
  }
}

class _ChatEntry {
  final int id;
  String text;
  final bool isUser;

  _ChatEntry({required this.id, required this.text, required this.isUser});
}
