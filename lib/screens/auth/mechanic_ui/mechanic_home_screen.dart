import 'package:flutter/material.dart';
import '../../../data/quote_store.dart';
import '../../../widgets/app_widgets.dart';
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

  void _goToTab(int index) => setState(() => _currentIndex = index);

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MechanicNotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const JobsScreen(),
      const EarningScreen(),
      const QrScreen(),
      const MechanicLeaderboardScreen(),
      const MechanicProfileViewScreen(name: '',),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), activeIcon: Icon(Icons.payments), label: 'Earning'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'QR'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Rank'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}