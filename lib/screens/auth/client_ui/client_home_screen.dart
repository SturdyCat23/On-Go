import 'package:flutter/material.dart';
import '../../../data/app_session.dart';
import '../../../data/review_store.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/on_go_bottom_nav.dart';
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
      bottomNavigationBar: OnGoBottomNav(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        items: const [
          OnGoNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          OnGoNavItem(icon: Icons.work_outline, activeIcon: Icons.work, label: 'Jobs'),
          OnGoNavItem(icon: Icons.history, label: 'History'),
          OnGoNavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Leaderboard'),
        ],
      ),
    );
  }
}