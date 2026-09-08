import 'package:flutter/material.dart';

import '../backend/console_backend.dart';
import '../theme/console_theme.dart';
import 'console_formats.dart';

/// The two revenue charts, ported from the Admin panel this console replaced
/// and re-fitted for a mouse: they highlight on hover rather than on a drag,
/// which is the interaction a desktop user expects.
///
/// Both read the same [MonthlyIncome] list and share the axis and the callout,
/// so the Overview line and the Income bars cannot drift apart.

/// The left-hand '₱Xk' axis labels.
class RevenueAxis extends StatelessWidget {
  final double maxValue;
  final double height;
  final int steps;

  const RevenueAxis({
    super.key,
    required this.maxValue,
    required this.height,
    this.steps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps + 1, (i) {
          final value = maxValue * (steps - i) / steps;
          // One unit for the whole axis, picked from the top of the scale, so
          // small real amounts read as ₱150 rather than a column of ₱0k.
          final label = maxValue >= 1000
              ? '₱${(value / 1000).toStringAsFixed(0)}k'
              : '₱${value.toStringAsFixed(0)}';
          return Text(label, style: Theme.of(context).textTheme.bodySmall);
        }),
      ),
    );
  }
}

/// The floating callout naming the highlighted month and its revenue.
class RevenueCallout extends StatelessWidget {
  final String label;
  final double value;
  final int transactions;

  const RevenueCallout({
    super.key,
    required this.label,
    required this.value,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: ConsoleColors.text,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w700,
                  color: ConsoleColors.canvas.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '₱${value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ConsoleColors.canvas,
                ),
              ),
              Text(
                transactions == 1 ? '1 payment' : '$transactions payments',
                style: TextStyle(
                  fontSize: 11,
                  color: ConsoleColors.canvas.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        CustomPaint(size: const Size(12, 6), painter: _CalloutTail(ConsoleColors.text)),
      ],
    );
  }
}

class _CalloutTail extends CustomPainter {
  const _CalloutTail(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CalloutTail old) => old.color != color;
}

/// Monthly revenue as a line, for the Admin Overview.
class RevenueLineChart extends StatefulWidget {
  final List<MonthlyIncome> income;
  final double height;

  const RevenueLineChart({super.key, required this.income, this.height = 170});

  @override
  State<RevenueLineChart> createState() => _RevenueLineChartState();
}

class _RevenueLineChartState extends State<RevenueLineChart> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    final income = widget.income;
    final maxRevenue =
        income.map((m) => m.revenue).reduce((a, b) => a > b ? a : b) * 1.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RevenueAxis(maxValue: maxRevenue, height: widget.height),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final segment =
                        income.length > 1 ? width / (income.length - 1) : width;

                    void hover(Offset local) {
                      final raw =
                          income.length > 1 ? (local.dx / segment).round() : 0;
                      final clamped = raw.clamp(0, income.length - 1);
                      if (clamped != _hovered) setState(() => _hovered = clamped);
                    }

                    return MouseRegion(
                      onHover: (event) => hover(event.localPosition),
                      onExit: (_) => setState(() => _hovered = null),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => hover(d.localPosition),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _LineChartPainter(
                                  income: income,
                                  maxRevenue: maxRevenue,
                                  highlight: _hovered,
                                  line: ConsoleColors.brand,
                                  grid: ConsoleColors.border,
                                  surface: ConsoleColors.surface,
                                ),
                              ),
                            ),
                            ..._callout(income, maxRevenue, segment, width),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _MonthAxisLabels(income: income, highlight: _hovered),
      ],
    );
  }

  List<Widget> _callout(
    List<MonthlyIncome> income,
    double maxRevenue,
    double segment,
    double width,
  ) {
    final index = _hovered;
    if (index == null) return const [];

    final point = income[index];
    final fraction =
        maxRevenue == 0 ? 0.0 : (point.revenue / maxRevenue).clamp(0.0, 1.0);
    final pointY = widget.height - fraction * (widget.height - 12);

    const calloutWidth = 130.0;
    final maxLeft = (width - calloutWidth).clamp(0.0, double.infinity);
    return [
      Positioned(
        left: (segment * index - calloutWidth / 2).clamp(0.0, maxLeft),
        top: (pointY - 78).clamp(0.0, widget.height),
        child: IgnorePointer(
          child: RevenueCallout(
            label: '${point.month} ${point.year}',
            value: point.revenue,
            transactions: point.transactions,
          ),
        ),
      ),
    ];
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.income,
    required this.maxRevenue,
    required this.highlight,
    required this.line,
    required this.grid,
    required this.surface,
  });

  final List<MonthlyIncome> income;
  final double maxRevenue;
  final int? highlight;
  final Color line;
  final Color grid;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    if (income.isEmpty) return;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final dx = income.length > 1 ? size.width / (income.length - 1) : size.width;
    final points = <Offset>[];
    for (var i = 0; i < income.length; i++) {
      final fraction =
          maxRevenue == 0 ? 0.0 : (income[i].revenue / maxRevenue).clamp(0.0, 1.0);
      points.add(Offset(dx * i, size.height - fraction * (size.height - 12)));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final mid = Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final fill = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: 0.20), line.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final index = highlight;
    if (index != null) {
      final point = points[index.clamp(0, points.length - 1)];
      _dashedLine(canvas, point, Offset(point.dx, size.height), grid);
      canvas.drawCircle(point, 5, Paint()..color = line);
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..color = surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _dashedLine(Canvas canvas, Offset start, Offset end, Color color) {
    const dash = 4.0;
    const gap = 3.0;
    final length = (end - start).distance;
    if (length == 0) return;
    final direction = (end - start) / length;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var current = start;
    for (var i = 0; i < (length / (dash + gap)).floor(); i++) {
      final next = current + direction * dash;
      canvas.drawLine(current, next, paint);
      current = next + direction * gap;
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.income != income ||
      old.maxRevenue != maxRevenue ||
      old.highlight != highlight ||
      old.line != line;
}

/// Monthly revenue as bars, for the Income screen.
class RevenueBarChart extends StatefulWidget {
  final List<MonthlyIncome> income;
  final double height;

  const RevenueBarChart({super.key, required this.income, this.height = 190});

  @override
  State<RevenueBarChart> createState() => _RevenueBarChartState();
}

class _RevenueBarChartState extends State<RevenueBarChart> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    final income = widget.income;
    final maxRevenue =
        income.map((m) => m.revenue).reduce((a, b) => a > b ? a : b) * 1.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RevenueAxis(maxValue: maxRevenue, height: widget.height),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final slot = width / income.length;

                    void hover(Offset local) {
                      final index =
                          (local.dx / slot).floor().clamp(0, income.length - 1);
                      if (index != _hovered) setState(() => _hovered = index);
                    }

                    return MouseRegion(
                      onHover: (event) => hover(event.localPosition),
                      onExit: (_) => setState(() => _hovered = null),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => hover(d.localPosition),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(child: _bars(income, maxRevenue)),
                            ..._callout(income, maxRevenue, slot, width),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _MonthAxisLabels(income: income, highlight: _hovered),
      ],
    );
  }

  Widget _bars(List<MonthlyIncome> income, double maxRevenue) {
    return Stack(
      children: [
        for (var i = 0; i <= 4; i++)
          Positioned(
            left: 0,
            right: 0,
            top: widget.height * i / 4,
            child: Container(height: 1, color: ConsoleColors.border),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final entry in income.asMap().entries)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: widget.height *
                          (maxRevenue == 0
                              ? 0.0
                              : (entry.value.revenue / maxRevenue).clamp(0.03, 1.0)),
                      decoration: BoxDecoration(
                        color: entry.key == _hovered
                            ? ConsoleColors.brandStrong
                            : ConsoleColors.brand.withValues(alpha: 0.85),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _callout(
    List<MonthlyIncome> income,
    double maxRevenue,
    double slot,
    double width,
  ) {
    final index = _hovered;
    if (index == null) return const [];

    final point = income[index];
    final barHeight = widget.height *
        (maxRevenue == 0 ? 0.0 : (point.revenue / maxRevenue).clamp(0.03, 1.0));

    const calloutWidth = 130.0;
    final maxLeft = (width - calloutWidth).clamp(0.0, double.infinity);
    return [
      Positioned(
        left: (slot * index + slot / 2 - calloutWidth / 2).clamp(0.0, maxLeft),
        top: (widget.height - barHeight - 80).clamp(0.0, widget.height),
        child: IgnorePointer(
          child: RevenueCallout(
            label: '${point.month} ${point.year}',
            value: point.revenue,
            transactions: point.transactions,
          ),
        ),
      ),
    ];
  }
}

/// The month names under either chart.
///
/// Twelve of them do not fit across a phone, so on a narrow screen only every
/// nth label is printed — the highlighted one always is, because that is the
/// one being read.
class _MonthAxisLabels extends StatelessWidget {
  const _MonthAxisLabels({required this.income, required this.highlight});

  final List<MonthlyIncome> income;
  final int? highlight;

  @override
  Widget build(BuildContext context) {
    final stride = context.layout.monthLabelStride(income.length);

    return Row(
      children: [
        const SizedBox(width: 54),
        for (final entry in income.asMap().entries)
          Expanded(
            child: Text(
              entry.key % stride == 0 || entry.key == highlight
                  ? entry.value.month
                  : '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 11,
                color: entry.key == highlight
                    ? ConsoleColors.brand
                    : ConsoleColors.textMuted,
                fontWeight:
                    entry.key == highlight ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}

/// What the revenue screens show before a single payment has been reported.
class RevenueEmptyChart extends StatelessWidget {
  final double height;
  final String message;

  const RevenueEmptyChart({
    super.key,
    this.height = 170,
    this.message = 'No payments reported yet.',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 26, color: ConsoleColors.textMuted),
            const SizedBox(height: 10),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// The line under the revenue tiles explaining where the number comes from.
String revenueSourceNote(int year) =>
    'Booked from client payments the mobile app reports. Since Jan $year.';

/// Formats a year-on-year comparison, or says there is nothing to compare to
/// yet — never a stand-in percentage.
({String label, bool positive})? revenueTrend({
  required double thisYear,
  required double lastYear,
  required int year,
}) {
  if (lastYear <= 0) return null;
  final change = (thisYear - lastYear) / lastYear * 100;
  return (
    label: '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}% vs ${year - 1}',
    positive: change >= 0,
  );
}

/// Peso formatting, re-exported here so a chart caller needs one import.
String formatChartPeso(double value) => formatPeso(value);
