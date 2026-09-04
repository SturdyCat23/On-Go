import 'package:flutter/material.dart';
import '../../../data/app_session.dart';
import '../../../data/review_store.dart';
import '../../../widgets/app_widgets.dart';
import 'home/need_help_screen.dart';
import 'jobs/client_jobs_screen.dart';
import 'history/service_history_screen.dart';
import 'rank/leaderboard_screen.dart';
import 'menu/client_menu_drawer.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    AppSession.instance.setRole(AppRole.client, viewerName: ReviewStore.currentClientName);
  }

  void _goToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      NeedHelpScreen(onRequestUploaded: () => _goToTab(1)),
      const ClientJobsScreen(),
      const ServiceHistoryScreen(),
      const LeaderboardScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const OnGoAppBar(
        // Bell has no function yet — kept in place for a future use.
        notificationAction: NotificationBell(count: 0, onTap: null),
      ),
      drawer: const ClientMenuDrawer(),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Rank'),
        ],
      ),
    );
  }
}