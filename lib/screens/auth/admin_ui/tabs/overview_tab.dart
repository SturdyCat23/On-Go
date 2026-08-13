import 'package:flutter/material.dart';
import '../../../../data/admin_data.dart';
import '../../../../data/moderator_data.dart';
import '../../../../theme/app_theme.dart';
import '../widgets/admin_widgets.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final _admin = AdminStore.instance;
  final _moderation = ModerationStore.instance;

  static const double _chartHeight = 150;
  int? _touchIndex;

  @override
  void initState() {
    super.initState();
    _admin.addListener(_onChange);
    _moderation.addListener(_onChange);
  }

  @override
  void dispose() {
    _admin.removeListener(_onChange);
    _moderation.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final income = _admin.income;
    final maxActions = _admin.moderators.isEmpty
        ? 1
        : _admin.moderators.map((x) => x.actionsHandled).reduce((a, b) => a > b ? a : b);

    final throughput = [..._admin.moderators]..sort((a, b) => b.actionsHandled.compareTo(a.actionsHandled));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            AdminStatCard(icon: Icons.groups, iconColor: AppColors.purple, value: '${_admin.activeModCount}', label: 'Active Mods'),
            AdminStatCard(icon: Icons.watch_later_outlined, iconColor: AppColors.yellow, value: '${_moderation.pending.length}', label: 'Queue'),
            AdminStatCard(
              icon: Icons.attach_money,
              iconColor: AppColors.green,
              value: income.isEmpty ? '\$0' : '\$${(income.last.revenue / 1000).toStringAsFixed(1)}K',
              label: income.isEmpty ? 'Revenue' : '${income.last.month} Revenue',
            ),
            AdminStatCard(icon: Icons.check_circle_outline, iconColor: AppColors.primary, value: '${_moderation.approved.length}', label: 'Accounts'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Revenue — ${income.isEmpty ? '' : income.first.year}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const Text('YTD', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        if (income.isEmpty)
          const SizedBox(
            height: _chartHeight,
            child: Center(child: Text('No revenue data yet', style: TextStyle(color: AppColors.textGrey, fontSize: 12))),
          )
        else
          _buildLineChart(income),
        const SizedBox(height: 24),
        const Text('MODERATOR THROUGHPUT', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (throughput.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No moderators yet', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          )
        else
          ...throughput.map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.borderGrey.withValues(alpha: 0.5),
                        child: Text(m.initials, style: const TextStyle(fontSize: 10, color: AppColors.textDark, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxActions == 0 ? 0 : m.actionsHandled / maxActions,
                              minHeight: 6,
                              backgroundColor: AppColors.borderGrey.withValues(alpha: 0.4),
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${m.actionsHandled}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildLineChart(List<MonthlyIncome> income) {
    final maxRevenue = (income.map((m) => m.revenue).reduce((a, b) => a > b ? a : b)) * 1.15;
    final idx = _touchIndex;
    final point = idx == null ? null : income[idx];

    double? pointY;
    if (idx != null) {
      final frac = maxRevenue == 0 ? 0.0 : (income[idx].revenue / maxRevenue).clamp(0.0, 1.0);
      pointY = _chartHeight - frac * (_chartHeight - 10);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminYAxisLabels(maxValue: maxRevenue, height: _chartHeight),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final segment = income.length > 1 ? w / (income.length - 1) : w;

                    void handleTouch(Offset local) {
                      final raw = income.length > 1 ? (local.dx / segment).round() : 0;
                      final clamped = raw.clamp(0, income.length - 1);
                      if (clamped != _touchIndex) setState(() => _touchIndex = clamped);
                    }

                    void clearTouch() {
                      if (_touchIndex != null) setState(() => _touchIndex = null);
                    }

                    Widget? tooltip;
                    if (idx != null && point != null && pointY != null) {
                      final pointX = segment * idx;
                      const tooltipWidth = 118.0;
                      final maxLeft = (w - tooltipWidth) > 0 ? (w - tooltipWidth) : 0.0;
                      final tooltipLeft = (pointX - tooltipWidth / 2).clamp(0.0, maxLeft);
                      final tooltipTop = (pointY - 54).clamp(0.0, _chartHeight);
                      tooltip = Positioned(
                        left: tooltipLeft,
                        top: tooltipTop,
                        child: IgnorePointer(child: AdminChartTooltip(label: point.month, value: point.revenue)),
                      );
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => handleTouch(d.localPosition),
                      onTapUp: (_) => clearTouch(),
                      onTapCancel: clearTouch,
                      onPanStart: (d) => handleTouch(d.localPosition),
                      onPanUpdate: (d) => handleTouch(d.localPosition),
                      onPanEnd: (_) => clearTouch(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            height: _chartHeight,
                            width: double.infinity,
                            child: CustomPaint(painter: _LineChartPainter(income: income, maxRevenue: maxRevenue, highlightIndex: idx)),
                          ),
                          // ignore: use_null_aware_elements
                          if (tooltip != null) tooltip,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 46),
            ...income.asMap().entries.map((e) => Expanded(
                  child: Text(
                    e.value.month,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: e.key == idx ? AdminChartColors.blue : AppColors.textGrey,
                      fontWeight: e.key == idx ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                )),
          ],
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<MonthlyIncome> income;
  final double maxRevenue;
  final int? highlightIndex;

  _LineChartPainter({required this.income, required this.maxRevenue, required this.highlightIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (income.isEmpty) return;

    final gridPaint = Paint()
      ..color = AppColors.borderGrey.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = AdminChartColors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AdminChartColors.blue.withValues(alpha: 0.18), AdminChartColors.blue.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dx = size.width / (income.length - 1).clamp(1, income.length);
    final points = <Offset>[];
    for (var i = 0; i < income.length; i++) {
      final x = dx * i;
      final frac = maxRevenue == 0 ? 0.0 : (income[i].revenue / maxRevenue).clamp(0.0, 1.0);
      final y = size.height - frac * (size.height - 10);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      linePath.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    if (highlightIndex != null) {
      final highlight = points[highlightIndex!.clamp(0, points.length - 1)];
      _drawDashedLine(canvas, Offset(highlight.dx, highlight.dy), Offset(highlight.dx, size.height));

      canvas.drawCircle(highlight, 5, Paint()..color = AdminChartColors.blue);
      canvas.drawCircle(
        highlight,
        5,
        Paint()
          ..color = AppColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final totalLength = (end - start).distance;
    if (totalLength == 0) return;
    final dashCount = (totalLength / (dashWidth + dashSpace)).floor();
    final paint = Paint()
      ..color = AppColors.borderGrey
      ..strokeWidth = 1;
    final dir = (end - start) / totalLength;
    var current = start;
    for (var i = 0; i < dashCount; i++) {
      final next = current + dir * dashWidth;
      canvas.drawLine(current, next, paint);
      current = next + dir * dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.income != income || oldDelegate.maxRevenue != maxRevenue || oldDelegate.highlightIndex != highlightIndex;
}