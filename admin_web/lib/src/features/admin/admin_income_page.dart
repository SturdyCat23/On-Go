import 'package:flutter/material.dart';

import '../../app/console_shell.dart';
import '../../backend/console_backend.dart';
import '../../theme/console_theme.dart';
import '../../widgets/console_formats.dart';
import '../../widgets/console_widgets.dart';
import '../../widgets/revenue_charts.dart';

/// What the platform has earned.
///
/// Read-only, and it has to be: the console cannot book a peso. Every figure
/// here came from the mobile app reporting a payment that a client actually
/// completed, which is the whole reason [PlatformRevenueApi] has a write side
/// on one surface and a read side on the other.
class AdminIncomePage extends StatelessWidget {
  const AdminIncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return ConsoleShell(
      child: StreamBuilder<PlatformRevenueSummary>(
        stream: ConsoleBackend.instance.revenue.watchSummary(),
        builder: (context, snapshot) {
          final revenue = snapshot.data ?? const PlatformRevenueSummary();
          final months = revenue.months;
          final thisYear = revenue.revenueForYear(year);
          final transactions = revenue.transactionsForYear(year);
          final trend = revenueTrend(
            thisYear: thisYear,
            lastYear: revenue.revenueForYear(year - 1),
            year: year,
          );

          return ListView(
            padding: consolePagePadding(context),
            children: [
              // Side by side even on a phone, as the Income tab had them.
              ConsoleResponsiveGrid(
                columns: 2,
                children: [
                  ConsoleStatTile(
                    icon: Icons.payments_outlined,
                    accent: ConsoleColors.success,
                    value: formatPeso(thisYear),
                    label: 'YTD Revenue',
                    footnote: trend?.label ?? revenueSourceNote(year),
                    footnoteColor: trend == null
                        ? null
                        : trend.positive
                            ? ConsoleColors.success
                            : ConsoleColors.danger,
                  ),
                  ConsoleStatTile(
                    icon: Icons.receipt_long_outlined,
                    accent: ConsoleColors.info,
                    value: '$transactions',
                    label: 'Transactions',
                    footnote: transactions == 1
                        ? '1 completed payment'
                        : '$transactions completed payments',
                  ),
                ],
              ),
              if (revenue.priorityFeeCount > 0) ...[
                const SizedBox(height: 16),
                _PriorityFeeNote(
                  amount: revenue.priorityFeeRevenue,
                  count: revenue.priorityFeeCount,
                ),
              ],
              SizedBox(height: context.layout.sectionSpacing),
              ConsoleCard(
                title: 'Monthly revenue',
                subtitle: 'Platform fees booked per month',
                child: months.isEmpty
                    ? RevenueEmptyChart(
                        height: context.layout.chartHeight,
                        message:
                            'Months appear here as the mobile app reports client payments.',
                      )
                    : RevenueBarChart(
                        income: months,
                        height: context.layout.chartHeight,
                      ),
              ),
              SizedBox(height: context.layout.sectionSpacing),
              ConsoleCard(
                title: 'Monthly breakdown',
                subtitle: 'Most recent first',
                padding: months.isEmpty ? EdgeInsets.zero : const EdgeInsets.all(4),
                child: months.isEmpty
                    ? const ConsoleEmptyState(
                        icon: Icons.table_rows_outlined,
                        title: 'No months to show',
                        message:
                            'The ledger fills in from payments the mobile app reports '
                            'once the API connects the two applications.',
                      )
                    : Column(
                        children: [
                          for (final month in months.reversed)
                            _MonthRow(month: month),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PriorityFeeNote extends StatelessWidget {
  const _PriorityFeeNote({required this.amount, required this.count});

  final double amount;
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ConsoleColors.success.withValues(alpha: 0.07),
        borderRadius: ConsoleMetrics.borderRadiusLarge,
        border: Border.all(color: ConsoleColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt, size: 18, color: ConsoleColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₱${amount.toStringAsFixed(0)} from priority fees',
                  style: text.titleSmall?.copyWith(color: ConsoleColors.success),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count paid ${count == 1 ? 'job' : 'jobs'} carried an Urgent '
                  '(+₱50) or Emergency (+₱100) charge. Already counted in the '
                  'totals above.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month});

  final MonthlyIncome month;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text('${month.month} ${month.year}', style: text.titleSmall),
          ),
          Text(
            '${month.transactions} ${month.transactions == 1 ? 'payment' : 'payments'}',
            style: text.bodySmall,
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 90,
            child: Text(
              '₱${month.revenue.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: text.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
