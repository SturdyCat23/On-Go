import 'package:flutter/material.dart';
import '../../../data/moderator_data.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/on_go_bottom_nav.dart';
import 'menu/moderator_menu_drawer.dart';
import 'tabs/queue_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/accounts_tab.dart';
import 'tabs/profile_tab.dart';

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
    ProfileTab(),
  ];

  void _openQueue() => setState(() => _index = 0);

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
      drawer: const ModeratorMenuDrawer(),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: OnGoBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          OnGoNavItem(icon: Icons.watch_later_outlined, label: 'Queue'),
          OnGoNavItem(icon: Icons.history, label: 'History'),
          OnGoNavItem(icon: Icons.people_outline, label: 'Accounts'),
          OnGoNavItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}
