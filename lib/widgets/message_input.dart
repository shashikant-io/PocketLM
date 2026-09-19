import 'package:flutter/material.dart';

import '../utils/constants.dart';

// Rounded composer frontend ke bottom chat input jaisa behave karta hai.
class MessageInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback? onStop;
  final bool isGenerating;
  final bool enabled;
  final String hintText;

  const MessageInput(
      {super.key,
      required this.onSend,
      this.onStop,
      this.isGenerating = false,
      this.enabled = true,
      this.hintText = 'What would you like to know...'});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final String value = _controller.text.trim();
    if (!widget.enabled || value.isEmpty) return;
    widget.onSend(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  isDense: true),
            ),
          ),
          IconButton(
            onPressed: widget.enabled
                ? (widget.isGenerating ? widget.onStop : _send)
                : null,
            style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            icon: Icon(
                widget.isGenerating ? Icons.stop_rounded : Icons.send_rounded,
                size: 18),
          ),
        ],
      ),
    );
  }
}
