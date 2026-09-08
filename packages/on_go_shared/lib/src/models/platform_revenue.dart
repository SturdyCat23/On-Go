import 'json.dart';

/// The twelve month labels the revenue ledger is keyed by. Shared so the
/// mobile app, the console and the future backend all bucket a payment into
/// the same string.
const List<String> revenueMonthLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// The month label a moment falls in.
String revenueMonthLabelFor(DateTime when) => revenueMonthLabels[when.month - 1];

/// One month's platform revenue, as the Admin income screens read it.
class MonthlyIncome {
  /// One of [revenueMonthLabels].
  final String month;

  final int year;

  /// Platform fees booked this month, in pesos.
  final double revenue;

  /// Completed client payments this month, fee-bearing or not.
  final int transactions;

  const MonthlyIncome({
    required this.month,
    required this.year,
    required this.revenue,
    required this.transactions,
  });

  /// 1-12, derived from [month]. Used to order the ledger chronologically.
  int get monthNumber => revenueMonthLabels.indexOf(month) + 1;

  MonthlyIncome addPayment({required double fee}) => MonthlyIncome(
        month: month,
        year: year,
        revenue: revenue + fee,
        transactions: transactions + 1,
      );

  Map<String, dynamic> toJson() => {
        'month': month,
        'year': year,
        'revenue': revenue,
        'transactions': transactions,
      };

  factory MonthlyIncome.fromJson(Map<String, dynamic> json) => MonthlyIncome(
        month: readString(json['month']),
        year: readInt(json['year']),
        revenue: readDouble(json['revenue']),
        transactions: readInt(json['transactions']),
      );
}

/// The whole revenue picture in one response, so the Admin dashboard is one
/// round trip rather than four.
class PlatformRevenueSummary {
  /// Every month that has seen a payment, oldest first.
  final List<MonthlyIncome> months;

  /// Priority fees (Urgent +P50 / Emergency +P100) collected to date, and how
  /// many payments carried one. Already included in [months]; broken out only
  /// so the console can say how much of the revenue came from priority.
  final double priorityFeeRevenue;
  final int priorityFeeCount;

  const PlatformRevenueSummary({
    this.months = const [],
    this.priorityFeeRevenue = 0,
    this.priorityFeeCount = 0,
  });

  double revenueForYear(int year) =>
      months.where((m) => m.year == year).fold(0, (sum, m) => sum + m.revenue);

  int transactionsForYear(int year) =>
      months.where((m) => m.year == year).fold(0, (sum, m) => sum + m.transactions);

  Map<String, dynamic> toJson() => {
        'months': months.map((m) => m.toJson()).toList(),
        'priorityFeeRevenue': priorityFeeRevenue,
        'priorityFeeCount': priorityFeeCount,
      };

  factory PlatformRevenueSummary.fromJson(Map<String, dynamic> json) => PlatformRevenueSummary(
        months: readObjectList(json['months'])
            .map(MonthlyIncome.fromJson)
            .toList(growable: false),
        priorityFeeRevenue: readDouble(json['priorityFeeRevenue']),
        priorityFeeCount: readInt(json['priorityFeeCount']),
      );
}

/// One completed client payment, reported by the mobile app.
///
/// This is the ONLY thing that moves the Admin revenue figures. It is posted
/// when a client payment actually succeeds, never when a job is merely created
/// or priced. [platformFee] is the client-side priority charge; a mechanic's
/// payout never passes through here.
class CompletedPaymentReport {
  /// The job this payment settled. Carried so the backend can reject a
  /// duplicate report rather than booking the same payment twice.
  final String requestId;

  final double platformFee;
  final DateTime paidAt;

  const CompletedPaymentReport({
    required this.requestId,
    required this.platformFee,
    required this.paidAt,
  });

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'platformFee': platformFee,
        'paidAt': writeDate(paidAt),
      };

  factory CompletedPaymentReport.fromJson(Map<String, dynamic> json) => CompletedPaymentReport(
        requestId: readString(json['requestId']),
        platformFee: readDouble(json['platformFee']),
        paidAt: readDate(json['paidAt']),
      );
}
