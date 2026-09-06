import 'package:flutter/material.dart';
import '../../../data/app_session.dart';
import '../../../data/quote_store.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/on_go_bottom_nav.dart';
import 'jobs/jobs_screen.dart';
import 'notifications/mechanic_notifications_screen.dart';
import 'earning/earning_screen.dart';
import 'qr/qr_screen.dart';
import 'rank/mechanic_leaderboard_screen.dart';
import 'profile/mechanic_profile_screen.dart';
import 'menu/mechanic_menu_drawer.dart';

class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    AppSession.instance.setRole(AppRole.mechanic, viewerName: QuoteNotificationStore.currentMechanicName);
  }

  void _goToTab(int index) => setState(() => _currentIndex = index);

  Future<void> _openNotifications() async {
    QuoteNotificationStore.instance.markMechanicNotificationsSeen();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MechanicNotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const JobsScreen(),
      EarningScreen(onViewAll: () => _goToTab(3)),
      const QrScreen(),
      const MechanicLeaderboardScreen(),
      const MechanicProfileScreen(standalone: false),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: OnGoAppBar(
        notificationAction: AnimatedBuilder(
          animation: QuoteNotificationStore.instance,
          builder: (context, _) => NotificationBell(
            count: QuoteNotificationStore.instance.mechanicNotificationCount,
            onTap: _openNotifications,
          ),
        ),
      ),
      drawer: const MechanicMenuDrawer(),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: OnGoBottomNav(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        items: const [
          OnGoNavItem(icon: Icons.work_outline, activeIcon: Icons.work, label: 'Jobs'),
          OnGoNavItem(icon: Icons.payments_outlined, activeIcon: Icons.payments, label: 'Earning'),
          OnGoNavItem(icon: Icons.qr_code_scanner, label: 'QR'),
          OnGoNavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Rank'),
          OnGoNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}