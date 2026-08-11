import 'package:flutter/material.dart';
import '../../../widgets/app_widgets.dart';
import '../../../data/quote_store.dart';
import 'home/need_help_screen.dart';
import 'home/quotes_screen.dart';
import 'active/active_request_screen.dart';
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

  void _goToTab(int index) => setState(() => _currentIndex = index);

  /// Bell tap: open the quotes list. If the client accepts a quote there,
  /// jump to the Active tab to show the confirmed mechanic.
  Future<void> _openQuotes() async {
    QuoteNotificationStore.instance.markSeen();
    final accepted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const QuotesScreen()),
    );
    if (accepted == true) {
      _goToTab(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      NeedHelpScreen(onRequestUploaded: () => _goToTab(1)),
      const ActiveRequestScreen(),
      const ServiceHistoryScreen(),
      const LeaderboardScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: OnGoAppBar(onNotificationTap: _openQuotes),
      drawer: const ClientMenuDrawer(),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Active',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Rank',
          ),
        ],
      ),
    );
  }
}