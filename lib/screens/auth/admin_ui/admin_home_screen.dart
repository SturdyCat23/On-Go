import 'package:flutter/material.dart';
import '../../../data/moderator_data.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/on_go_bottom_nav.dart';
import '../sign_in_screen.dart';
import 'notifications/admin_notifications_screen.dart';
import 'settings/admin_settings_screen.dart';
import 'tabs/overview_tab.dart';
import 'tabs/mods_tab.dart';
import 'tabs/add_mod_tab.dart';
import 'tabs/audit_tab.dart';
import 'tabs/income_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  Future<void> _openNotifications() async {
    ModerationStore.instance.markActivitySeen();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
    );
  }

  final _tabs = const [
    OverviewTab(),
    ModsTab(),
    AddModTab(),
    AuditTab(),
    IncomeTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: OnGoAppBar(
        subtitle: 'Admin Panel',
        notificationAction: AnimatedBuilder(
          animation: ModerationStore.instance,
          builder: (context, _) => NotificationBell(
            count: ModerationStore.instance.unseenActivityCount,
            onTap: _openNotifications,
          ),
        ),
      ),
      drawer: const _AdminDrawer(),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: OnGoBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          OnGoNavItem(icon: Icons.monitor_heart_outlined, label: 'Overview'),
          OnGoNavItem(icon: Icons.shield_outlined, label: 'Mods'),
          OnGoNavItem(icon: Icons.person_add_alt, label: 'Add Mod'),
          OnGoNavItem(icon: Icons.history, label: 'Audit'),
          OnGoNavItem(icon: Icons.bar_chart, label: 'Income'),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
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
                'Admin',
                style: TextStyle(color: AppColors.textlight, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              horizontalTitleGap: 12,
              minLeadingWidth: 20,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
              leading: Icon(Icons.settings_outlined, size: 20, color: AppColors.textdark),
              title: Text('Settings', style: TextStyle(color: AppColors.textdark, fontWeight: FontWeight.w500, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen()));
              },
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