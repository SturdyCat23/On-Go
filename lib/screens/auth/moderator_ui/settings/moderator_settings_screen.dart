import 'package:flutter/material.dart';

import '../../../../data/admin_data.dart';
import '../../../../data/session_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/password_strength.dart';
import '../../../shared/change_background_screen.dart';
import '../../../shared/theme_screen.dart';

/// Moderator settings, reached from the drawer the way the Client and
/// Mechanic shells reach theirs.
///
/// Appearance, Notifications and Security used to sit in the Settings tab on
/// the bottom bar; that tab is the Profile tab now, so they live here.
class ModeratorSettingsScreen extends StatefulWidget {
  const ModeratorSettingsScreen({super.key});

  @override
  State<ModeratorSettingsScreen> createState() => _ModeratorSettingsScreenState();
}

class _ModeratorSettingsScreenState extends State<ModeratorSettingsScreen> {
  /// Nothing acts on this toggle yet — there is no notification store behind
  /// it. It is static so the choice survives leaving and reopening the screen,
  /// which is what the Settings tab gave it before (it stayed alive inside the
  /// shell's IndexedStack).
  static bool _newSubmitted = true;

  final _session = SessionStore.instance;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onChange);
  }

  @override
  void dispose() {
    _session.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _changePassword() async {
    final mod = _session.currentModerator;
    if (mod == null) return;

    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              PasswordStrengthMeter(password: newController.text),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                if (newController.text.length < 6) {
                  setDialogState(() => errorText = 'New password must be at least 6 characters');
                  return;
                }
                if (newController.text != confirmController.text) {
                  setDialogState(() => errorText = 'Passwords do not match');
                  return;
                }
                final ok = AdminStore.instance.changeModeratorPassword(
                  mod.id,
                  oldPassword: oldController.text,
                  newPassword: newController.text,
                );
                if (!ok) {
                  setDialogState(() => errorText = 'Current password is incorrect');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated'), duration: AppDurations.snackBar),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mod = _session.currentModerator;
    final labelStyle = TextStyle(
      fontSize: 11,
      color: AppColors.textdark.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
    );

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
          Text('APPEARANCE', style: labelStyle),
          const ThemesSettingsTile(),
          // Only moderators the admin granted the permission to can open this.
          ChangeBackgroundSettingsTile(enabled: _session.currentPermissions.canChangeBackground),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 16),
          Text('NOTIFICATIONS', style: labelStyle),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New pending approvals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('when accounts are submitted',
                        style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Switch(
                value: _newSubmitted,
                onChanged: (v) => setState(() => _newSubmitted = v),
                activeTrackColor: AppColors.primary,
                activeThumbColor: AppColors.surface,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 16),
          Text('SECURITY', style: labelStyle),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_outline, color: AppColors.textdark),
            title: Text('Change Password', style: TextStyle(fontSize: 15, color: AppColors.textdark)),
            subtitle: Text(
              mod == null ? 'No moderator account signed in' : 'Update the password for this account',
              style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
            ),
            trailing: Icon(Icons.chevron_right, color: AppColors.textdark.withValues(alpha: 0.55)),
            onTap: mod == null ? null : _changePassword,
          ),
        ],
      ),
    );
  }
}
