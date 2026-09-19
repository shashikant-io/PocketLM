import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Header frontend wale PocketLM title aur offline status ko preserve karta hai.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenu;

  const AppHeader({super.key, required this.title, required this.onMenu});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface.withValues(alpha: 0.96),
      elevation: 0,
      leading: IconButton(
        onPressed: onMenu,
        icon: const Icon(Icons.menu_rounded),
        color: AppColors.onSurfaceVariant,
      ),
      titleSpacing: 0,
      title: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: SvgPicture.asset('assets/model_logos/pocketlm_logo.svg',
                  fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        ],
      ),
      actions: <Widget>[
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceHigh),
          ),
          child: Row(
            children: <Widget>[
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text(AppStrings.offlineStatus,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
