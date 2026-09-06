import 'package:flutter/material.dart';
import '../../../data/admin_data.dart';
import '../../../data/moderator_data.dart';
import '../../../data/session_store.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/on_go_bottom_nav.dart';
import '../sign_in_screen.dart';
import 'tabs/queue_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/accounts_tab.dart';
import 'tabs/settings_tab.dart';

class ModeratorHomeScreen extends StatefulWidget {
  const ModeratorHomeScreen({super.key});

  @override
  State<ModeratorHomeScreen> createState() => _ModeratorHomeScreenState();
}

class _ModeratorHomeScreenState extends State<ModeratorHomeScreen> {
  int _index = 0;

  final _tabs = const [
    QueueTab(),
    HistoryTab(),
    AccountsTab(),
    SettingsTab(),
  ];

  void _openQueue() => setState(() => _index = 0);

  /// The moderator's settings live in the Settings tab, so the drawer
  /// entry switches to it rather than pushing a separate screen.
  void _openSettings() {
    Navigator.pop(context);
    setState(() => _index = 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: OnGoAppBar(
        subtitle: 'Moderator Panel',
        notificationAction: AnimatedBuilder(
          animation: ModerationStore.instance,
          builder: (context, _) => NotificationBell(
            count: ModerationStore.instance.pending.length,
            onTap: _openQueue,
          ),
        ),
      ),
      drawer: _ModeratorDrawer(onOpenSettings: _openSettings),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: OnGoBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          OnGoNavItem(icon: Icons.watch_later_outlined, label: 'Queue'),
          OnGoNavItem(icon: Icons.history, label: 'History'),
          OnGoNavItem(icon: Icons.people_outline, label: 'Accounts'),
          OnGoNavItem(icon: Icons.settings_outlined, label: 'Setting'),
        ],
      ),
    );
  }
}

class _ModeratorDrawer extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _ModeratorDrawer({required this.onOpenSettings});

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
                        child: Text(m.initials, style: TextStyle(color: AppColors.textdark, fontWeight: FontWeight.w700, fontSize: 12)),
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
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadii.xl)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(20),
              child: Text(
                'Moderator',
                style: TextStyle(color: AppColors.textlight, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              horizontalTitleGap: 12,
              minLeadingWidth: 20,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
              leading: Icon(Icons.swap_horiz, size: 20, color: AppColors.textdark),
              title: Text('Switch Account', style: TextStyle(color: AppColors.textdark, fontWeight: FontWeight.w500, fontSize: 14)),
              onTap: () => _showSwitchAccount(context),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              horizontalTitleGap: 12,
              minLeadingWidth: 20,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
              leading: Icon(Icons.settings_outlined, size: 20, color: AppColors.textdark),
              title: Text('Settings', style: TextStyle(color: AppColors.textdark, fontWeight: FontWeight.w500, fontSize: 14)),
              onTap: onOpenSettings,
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              horizontalTitleGap: 12,
              minLeadingWidth: 20,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
              leading: Icon(Icons.logout, size: 20, color: AppColors.error),
              title: Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500, fontSize: 14)),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}