import 'package:flutter/material.dart';

import '../utils/constants.dart';

// Chat bubble user aur local assistant messages ko alag visual treatment deta hai.
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(18),
          border: isUser ? null : Border.all(color: AppColors.surfaceHigh),
        ),
        child: Text(text,
            style: TextStyle(
                color: isUser ? Colors.white : AppColors.onSurface,
                height: 1.35)),
      ),
    );
  }
}
