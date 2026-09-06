import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../shared/theme_screen.dart';

/// Admin settings. The admin shell had no Settings screen before, so this one
/// starts with Appearance and is where later admin-wide preferences belong.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textlight,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'APPEARANCE',
            style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55), fontWeight: FontWeight.w600),
          ),
          const ThemesSettingsTile(),
        ],
      ),
    );
  }
}
