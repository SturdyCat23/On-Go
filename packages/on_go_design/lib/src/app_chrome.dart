import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The product's app bar: a menu button that opens the drawer, the "On Go"
/// wordmark with a subtitle naming the shell, an optional secondary action,
/// and a notification bell.
///
/// Shared by the mobile app and, on a phone-sized window, the admin console —
/// so an admin opening the console on their phone gets the same bar a client
/// gets in the app, not a lookalike.
class OnGoAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The line under "On Go" — 'Service Anywhere', 'Admin Panel',
  /// 'Moderator Panel'.
  final String subtitle;

  final bool showMenuButton;

  /// An extra action left of the bell (the client's "Uploaded" button).
  final Widget? secondaryAction;

  /// The bell. Null renders no bell at all — every caller that wants one
  /// passes it, because what the count means and where the tap goes is the
  /// caller's business, not this widget's.
  final Widget? notificationAction;

  const OnGoAppBar({
    super.key,
    this.subtitle = 'Service Anywhere',
    this.showMenuButton = true,
    this.secondaryAction,
    this.notificationAction,
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
              icon: Icon(Icons.menu, color: AppColors.textlight),
              onPressed: () => Scaffold.of(context).openDrawer(),
            )
          : const SizedBox(width: 48),
      title: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'On Go',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textlight),
            ),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textlight),
            ),
          ],
        ),
      ),
      actions: [
        ?secondaryAction,
        ?notificationAction,
      ],
    );
  }
}

/// The bell, with a count badge once there is something to count.
class NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  // Null means "use the active theme's color", resolved at build time so a
  // theme change repaints the bell.
  final Color? badgeColor;
  final Color? iconColor;

  const NotificationBell({
    super.key,
    required this.count,
    this.onTap,
    this.badgeColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none, color: iconColor ?? AppColors.textlight),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 10,
            // The badge sits over the middle of the icon, and an opaque
            // Container would swallow a tap there instead of letting the
            // IconButton behind it fire. It is decoration, not a target.
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppColors.warning,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textdark.withValues(alpha: 0.12),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textlight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
