import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
// Todo: adjust these paths to wherever they live in your project
import '../data/quote_store.dart';
import '../screens/auth/client_ui/home/quotes_screen.dart';

/// Red app bar with a menu button (opens the drawer), "On Go" branding,
/// and a notification bell. Used as the appBar for the Client & Mechanic shells.
///
/// The bell now doubles as the "Quotes" entry point: once a client uploads a
/// help request, incoming mechanic quotes show up as a badge count here, and
/// tapping the bell opens QuotesScreen so the client can compare and accept one.
class OnGoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final bool showMenuButton;
  final Widget? notificationAction;
  final VoidCallback? onNotificationTap;

  const OnGoAppBar({
    super.key,
    this.subtitle = 'Service Anywhere',
    this.showMenuButton = true,
    this.notificationAction,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
      leading: showMenuButton
          ? IconButton(
              icon: const Icon(Icons.menu, color: AppColors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          : const SizedBox(width: 48),
      title: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'On Go',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.95)),
            ),
          ],
        ),
      ),
      actions: [notificationAction ?? _buildDefaultNotification(context)],
    );
  }

  Widget _buildDefaultNotification(BuildContext context) {
    return AnimatedBuilder(
      animation: QuoteNotificationStore.instance,
      builder: (context, _) {
        final count = QuoteNotificationStore.instance.unseenCount;
        return NotificationBell(
          count: count,
          onTap: onNotificationTap ??
              () {
                QuoteNotificationStore.instance.markSeen();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuotesScreen()),
                );
              },
        );
      },
    );
  }
}

class NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final Color badgeColor;
  final Color iconColor;

  const NotificationBell({
    super.key,
    required this.count,
    this.onTap,
    this.badgeColor = AppColors.primary,
    this.iconColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none, color: iconColor),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                  boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small "★ 4.8" style rating display.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  const RatingStars({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber, size: size),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(fontSize: size - 1, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Colored tier pill (Platinum / Gold / Silver / etc).
class TierBadge extends StatelessWidget {
  final String tier;
  const TierBadge({super.key, required this.tier});

  Color get _color {
    switch (tier) {
      case 'Platinum':
        return const Color(0xFF8E9AAF);
      case 'Gold':
        return const Color(0xFFD4A017);
      case 'Silver':
        return const Color(0xFF9E9E9E);
      default:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

/// 5★→1★ rating breakdown bars with a big average score on the side.
class RatingSummaryBars extends StatelessWidget {
  final double average;
  final Map<int, double> distribution;
  final int reviewCount;

  const RatingSummaryBars({
    super.key,
    required this.average,
    required this.distribution,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final star = 5 - i;
              final value = distribution[star] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('$star',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textGrey)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor:
                              AppColors.borderGrey.withValues(alpha: 0.4),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.amber),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          children: [
            Text(
              average.toStringAsFixed(1),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Icon(
                  i < average.round() ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 14,
                ),
              ),
            ),
            Text('$reviewCount reviews',
                style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
          ],
        ),
      ],
    );
  }
}