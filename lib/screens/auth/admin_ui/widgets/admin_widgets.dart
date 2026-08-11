import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';

/// White top bar used across all Admin screens: blue square logo,
/// screen title + role dropdown, notification bell with unread badge, avatar.
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String roleLabel;
  final int notificationCount;
  final String avatarInitials;

  const AdminAppBar({
    super.key,
    required this.title,
    this.roleLabel = 'ADMIN',
    this.notificationCount = 0,
    this.avatarInitials = 'AP',
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(right: 6, left: 12),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary,
          child: Text(avatarInitials, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(roleLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 16),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(icon: const Icon(Icons.notifications_none, color: AppColors.primary), onPressed: () {}),
            if (notificationCount > 0)
              Positioned(
                right: 8,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text('$notificationCount',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Small stat card used on the Overview & Income tabs.
class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? trend;
  final Color? trendColor;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.trend,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5, color: AppColors.textGrey)),
          if (trend != null) ...[
            const SizedBox(height: 2),
            Text(trend!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: trendColor ?? AppColors.green, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

/// Shared accent color for the revenue line & bar charts (blue, distinct
/// from the red/green/purple/yellow already defined on AppColors).
class AdminChartColors {
  static const Color blue = Color(0xFF3D6BFF);
}

/// Small floating callout bubble used to annotate the highlighted point on
/// the Overview line chart and the Income bar chart.
class AdminChartTooltip extends StatelessWidget {
  final String label;
  final double value;
  const AdminChartTooltip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('Revenue : \$${value.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: AdminChartColors.blue, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Left-hand "$Xk" axis labels shared by the revenue line & bar charts.
class AdminYAxisLabels extends StatelessWidget {
  final double maxValue;
  final double height;
  final int steps;
  const AdminYAxisLabels({super.key, required this.maxValue, required this.height, this.steps = 4});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps + 1, (i) {
          final v = maxValue * (steps - i) / steps;
          return Text('\$${(v / 1000).toStringAsFixed(0)}k',
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey));
        }),
      ),
    );
  }
}