import 'package:flutter/material.dart';
import '../../../../data/admin_data.dart';
import '../../../../theme/app_theme.dart';
import '../widgets/admin_widgets.dart';

class IncomeTab extends StatefulWidget {
  const IncomeTab({super.key});

  @override
  State<IncomeTab> createState() => _IncomeTabState();
}

class _IncomeTabState extends State<IncomeTab> {
  final _admin = AdminStore.instance;

  static const double _chartHeight = 150;
  int? _touchIndex;

  @override
  void initState() {
    super.initState();
    _admin.addListener(_onChange);
  }

  @override
  void dispose() {
    _admin.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final income = _admin.income;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminStatCard(
                  icon: Icons.attach_money,
                  iconColor: AppColors.green,
                  value: '\$${(_admin.ytdRevenue / 1000).toStringAsFixed(0)}K',
                  label: 'YTD Revenue',
                  trend: '+12% vs last year',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatCard(
                  icon: Icons.receipt_long,
                  iconColor: AppColors.purple,
                  value: '${_admin.ytdTransactions}',
                  label: 'Transactions',
                  trend: 'All payment events',
                  trendColor: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Monthly Revenue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          if (income.isEmpty)
            const SizedBox(
              height: _chartHeight,
              child: Center(child: Text('No revenue data yet', style: TextStyle(color: AppColors.textGrey, fontSize: 12))),
            )
          else
            _buildBarChart(income),
          const SizedBox(height: 24),
          const Text('MONTHLY BREAKDOWN', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...income.reversed.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.6))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${m.month} ${m.year}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('\$${m.revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${m.transactions} tx', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<MonthlyIncome> income) {
    final maxRevenue = (income.map((m) => m.revenue).reduce((a, b) => a > b ? a : b)) * 1.15;
    final idx = _touchIndex;

    double? barHeight;
    if (idx != null) {
      final frac = maxRevenue == 0 ? 0.0 : (income[idx].revenue / maxRevenue).clamp(0.02, 1.0);
      barHeight = _chartHeight * frac;
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
                    final slot = w / income.length;

                    void handleTouch(Offset local) {
                      final raw = (local.dx / slot).floor();
                      final clamped = raw.clamp(0, income.length - 1);
                      if (clamped != _touchIndex) setState(() => _touchIndex = clamped);
                    }

                    void clearTouch() {
                      if (_touchIndex != null) setState(() => _touchIndex = null);
                    }

                    Widget? tooltip;
                    if (idx != null && barHeight != null) {
                      final point = income[idx];
                      final barCenterX = slot * idx + slot / 2;
                      const tooltipWidth = 118.0;
                      final maxLeft = (w - tooltipWidth) > 0 ? (w - tooltipWidth) : 0.0;
                      final tooltipLeft = (barCenterX - tooltipWidth / 2).clamp(0.0, maxLeft);
                      final tooltipTop = (_chartHeight - barHeight - 56).clamp(0.0, _chartHeight);
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
                            child: Stack(
                              children: [
                                ...List.generate(5, (i) {
                                  final y = _chartHeight * i / 4;
                                  return Positioned(
                                    left: 0,
                                    right: 0,
                                    top: y,
                                    child: Container(height: 1, color: AppColors.borderGrey.withValues(alpha: 0.4)),
                                  );
                                }),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: income.asMap().entries.map((e) {
                                    final isSelected = e.key == idx;
                                    final h = _chartHeight * (maxRevenue == 0 ? 0.0 : (e.value.revenue / maxRevenue).clamp(0.02, 1.0));
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            height: h,
                                            decoration: BoxDecoration(
                                              color: isSelected ? AppColors.borderGrey : AdminChartColors.blue,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          ?tooltip,
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