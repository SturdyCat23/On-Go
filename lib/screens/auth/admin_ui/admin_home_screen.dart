import 'package:flutter/material.dart';
import '../../../data/moderator_data.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_widgets.dart';
import '../sign_in_screen.dart';
import 'notifications/admin_notifications_screen.dart';
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.monitor_heart_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: 'Mods'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add_alt), label: 'Add Mod'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Audit'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Income'),
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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Admin',
                style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.primary),
              title: const Text('Log Out'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}