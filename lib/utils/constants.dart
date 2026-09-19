import 'package:flutter/material.dart';

// App ke common colors aur text yahan rakhe gaye hain taaki UI consistent rahe.
class AppColors {
  static const Color primary = Color(0xFF5735AE);
  static const Color primaryContainer = Color(0xFF7050C8);
  static const Color primaryFixed = Color(0xFFE8DDFF);
  static const Color surface = Color(0xFFFAF9FD);
  static const Color surfaceLow = Color(0xFFF4F3F7);
  static const Color surfaceHigh = Color(0xFFE8E8EC);
  static const Color outline = Color(0xFF7A7584);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF494553);
}

class AppStrings {
  static const String appName = 'PocketLM';
  static const String offlineStatus = '100% Offline';
  static const String privateStatus = '100% Offline & Private';
  static const String noModels = 'No Models Available';
  static const String emptyChatDescription =
      'Download a model to start chatting with SLM offline and privately.';
}
