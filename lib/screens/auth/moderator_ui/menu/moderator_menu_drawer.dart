import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../data/admin_data.dart';
import '../../../../data/session_store.dart';
import '../../../../theme/app_theme.dart';
import '../../sign_in_screen.dart';
import '../profile/moderator_profile_info_screen.dart';
import '../settings/moderator_settings_screen.dart';

/// The moderator drawer, built like the Client and Mechanic ones: a header
/// with the signed-in account, then Profile, Settings and Sign Out. Switch
/// Account is kept here too — it has no equivalent in the other shells.
class ModeratorMenuDrawer extends StatefulWidget {
  const ModeratorMenuDrawer({super.key});

  @override
  State<ModeratorMenuDrawer> createState() => _ModeratorMenuDrawerState();
}

class _ModeratorMenuDrawerState extends State<ModeratorMenuDrawer> {
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

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  Future<String?> _promptPassword(BuildContext context, String moderatorName) {
    final controller = TextEditingController();
    bool obscure = true;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Sign in as $moderatorName'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                onPressed: () => setDialogState(() => obscure = !obscure),
              ),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSwitchAccount(BuildContext context) {
    final admin = AdminStore.instance;
    final session = SessionStore.instance;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([admin, session]),
          builder: (context, _) {
            final mods = admin.moderators;
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Switch Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                if (mods.isEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Text(
                      'No moderator accounts yet. Add one from the Admin panel.',
                      style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55), fontSize: 13),
                    ),
                  )
                else
                  ...mods.map((m) {
                    final active = session.currentModerator?.id == m.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.textdark.withValues(alpha: 0.2),
                        backgroundImage: m.photoPath == null ? null : FileImage(File(m.photoPath!)),
                        child: m.photoPath == null
                            ? Text(m.initials,
                                style: TextStyle(color: AppColors.textdark, fontWeight: FontWeight.w700, fontSize: 12))
                            : null,
                      ),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(m.email, style: const TextStyle(fontSize: 12)),
                      trailing: active ? Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: active
                          ? null
                          : () async {
                              final password = await _promptPassword(context, m.name);
                              if (password == null) return;
                              final ok = session.switchTo(m.id, password);
                              if (ok) {
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Incorrect password'), duration: AppDurations.snackBar),
                                );
                              }
                            },
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mod = _session.currentModerator;
    final photo = mod?.photoPath;
    final displayName = (mod == null || mod.name.isEmpty) ? 'Moderator' : mod.name;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadii.xl)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surface.withValues(alpha: 0.25),
                  backgroundImage: photo == null ? null : FileImage(File(photo)),
                  child: photo == null ? Icon(Icons.person_outline, color: AppColors.textlight, size: 32) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.textlight, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        mod?.role ?? 'No account',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textlight.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              children: [
                _DrawerItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ModeratorProfileInfoScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.swap_horiz,
                  label: 'Switch Account',
                  onTap: () => _showSwitchAccount(context),
                ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ModeratorSettingsScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Log Out',
                  destructive: true,
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.textdark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      horizontalTitleGap: 12,
      minLeadingWidth: 20,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      leading: Icon(icon, size: 20, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14)),
      onTap: onTap,
    );
  }
}
