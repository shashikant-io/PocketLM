import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Drawer phase 1 mein sirf Chat aur Models workflows rakhta hai.
class AppNavigationDrawer extends StatelessWidget {
  final VoidCallback onChat;
  final VoidCallback onModels;

  const AppNavigationDrawer(
      {super.key, required this.onChat, required this.onModels});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle),
                    child: ClipOval(
                      child: SvgPicture.asset(
                        'assets/model_logos/pocketlm_logo.svg',
                        fit: BoxFit.cover))),
              title: const Text(AppStrings.appName,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ),
            Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(children: <Widget>[
                  Icon(Icons.circle, color: Colors.green, size: 10),
                  SizedBox(width: 8),
                  Text(AppStrings.privateStatus,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600))
                ])),
            ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Chat'),
                onTap: () {
                  Navigator.pop(context);
                  onChat();
                }),
            ListTile(
                leading: const Icon(Icons.psychology_outlined),
                title: const Text('Models'),
                onTap: () {
                  Navigator.pop(context);
                  onModels();
                }),
            const Divider(indent: 16, endIndent: 16),
            const Spacer(),
            const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('SLM Studio v1.0',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant)),
                      Text('On-Device Cache',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600))
                    ])),
          ],
        ),
      ),
    );
  }
}
