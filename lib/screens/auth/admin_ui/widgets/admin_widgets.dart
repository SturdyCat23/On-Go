import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';

/// Peso label for the Admin revenue figures. Real fee revenue starts small,
/// so exact pesos are shown until the number passes a thousand.
String formatAdminPeso(double value) {
  if (value.abs() < 1000) return '₱${value.toStringAsFixed(0)}';
  return '₱${(value / 1000).toStringAsFixed(1)}K';
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5, color: AppColors.textdark.withValues(alpha: 0.55))),
          if (trend != null) ...[
            const SizedBox(height: 2),
            Text(trend!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: trendColor ?? AppColors.success, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textdark, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('Revenue : ₱${value.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Left-hand "₱Xk" axis labels shared by the revenue line & bar charts.
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
          // One unit for the whole axis, picked from the top of the scale —
          // small real amounts read as ₱150, not a column of ₱0k.
          final label = maxValue >= 1000 ? '₱${(v / 1000).toStringAsFixed(0)}k' : '₱${v.toStringAsFixed(0)}';
          return Text(label, style: TextStyle(fontSize: 10, color: AppColors.textdark.withValues(alpha: 0.55)));
        }),
      ),
    );
  }
}
