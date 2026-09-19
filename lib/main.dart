import 'package:flutter/material.dart';

import 'screens/chat_screen.dart';
import 'screens/models_screen.dart';
import 'services/model_service.dart';
import 'utils/constants.dart';
import 'widgets/app_header.dart';
import 'widgets/navigation_drawer.dart';

void main() {
  runApp(const PocketLmApp());
}

// Root app phase 1 ke Chat aur Models screens ko ek shared service deta hai.
class PocketLmApp extends StatelessWidget {
  const PocketLmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.surface,
          colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary, brightness: Brightness.light)),
      home: const PocketLmShell(),
    );
  }
}

class PocketLmShell extends StatefulWidget {
  const PocketLmShell({super.key});

  @override
  State<PocketLmShell> createState() => _PocketLmShellState();
}

class _PocketLmShellState extends State<PocketLmShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ModelService _modelService = ModelService();
  bool _showModels = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppHeader(
          title: _showModels ? 'Models' : AppStrings.appName,
          onMenu: () => _scaffoldKey.currentState?.openDrawer()),
      drawer: AppNavigationDrawer(
          onChat: () => setState(() => _showModels = false),
          onModels: () => setState(() => _showModels = true)),
      body: _showModels
          ? ModelsScreen(modelService: _modelService)
          : ChatScreen(
              modelService: _modelService,
              onOpenModels: () => setState(() => _showModels = true)),
    );
  }
}
