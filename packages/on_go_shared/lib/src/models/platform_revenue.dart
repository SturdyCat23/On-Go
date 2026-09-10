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

/// The three job urgencies, as the revenue ledger buckets them.
///
/// The mobile app carries urgency as a plain string on a request; this is the
/// closed set the ledger stores, so a typo cannot invent a fourth column in
/// the Admin charts. Convert at the boundary with [fromJobUrgency].
enum RevenueUrgency {
  normal('Normal'),
  urgent('Urgent'),
  emergency('Emergency');

  const RevenueUrgency(this.label);

  /// How this urgency is written on screen.
  final String label;

  /// The bucket a job's urgency string falls in. Anything unrecognised counts
  /// as [normal] — the same default the mobile app applies to an urgency it
  /// doesn't know, so the two never disagree about where a job belongs.
  static RevenueUrgency fromJobUrgency(String urgency) {
    switch (urgency) {
      case 'Emergency':
        return RevenueUrgency.emergency;
      case 'Urgent':
        return RevenueUrgency.urgent;
      default:
        return RevenueUrgency.normal;
    }
  }

  static RevenueUrgency fromName(String name) =>
      values.firstWhere((v) => v.name == name, orElse: () => RevenueUrgency.normal);
}

/// One urgency's share of a month: what it earned and how many payments it was.
class UrgencyTotals {
  /// Platform fees booked for this urgency, in pesos.
  ///
  /// Normal jobs carry no priority fee today, so their revenue is legitimately
  /// zero while their [transactions] are not. That is the fee model, not a
  /// gap in the data — which is why the console reads volume and revenue as
  /// two separate figures rather than inferring one from the other.
  final double revenue;

  /// Completed client payments of this urgency.
  final int transactions;

  const UrgencyTotals({this.revenue = 0, this.transactions = 0});

  UrgencyTotals addPayment({required double fee}) =>
      UrgencyTotals(revenue: revenue + fee, transactions: transactions + 1);

  Map<String, dynamic> toJson() => {'revenue': revenue, 'transactions': transactions};

  factory UrgencyTotals.fromJson(Map<String, dynamic> json) => UrgencyTotals(
        revenue: readDouble(json['revenue']),
        transactions: readInt(json['transactions']),
      );
}

/// One stretch of time's revenue, split by urgency — a month or a year.
///
/// The Admin charts plot periods, not months: the Overview reads a year of
/// months and the Income screen reads several years. Both draw the same three
/// series from the same four members, so one set of chart widgets serves both
/// rather than a near-copy per screen.
abstract interface class RevenuePeriod {
  /// How the period reads in a callout — 'Mar 2026', or '2026'.
  String get periodLabel;

  /// How it reads under the chart, where there is far less room.
  String get axisLabel;

  /// Everything booked in the period, all urgencies together.
  double get revenue;

  /// Completed client payments in the period, fee-bearing or not.
  int get transactions;

  double revenueFor(RevenueUrgency urgency);

  int transactionsFor(RevenueUrgency urgency);
}

/// One month's platform revenue, as the Admin income screens read it.
class MonthlyIncome implements RevenuePeriod {
  /// One of [revenueMonthLabels].
  final String month;

  final int year;

  /// Platform fees booked this month, in pesos.
  @override
  final double revenue;

  /// Completed client payments this month, fee-bearing or not.
  @override
  final int transactions;

  /// The same month split three ways, so the Admin charts can plot Normal,
  /// Urgent and Emergency as their own series. [revenue] and [transactions]
  /// stay the month's totals and are what every existing figure reads — this
  /// is a breakdown OF them, never a replacement.
  final Map<RevenueUrgency, UrgencyTotals> byUrgency;

  const MonthlyIncome({
    required this.month,
    required this.year,
    required this.revenue,
    required this.transactions,
    this.byUrgency = const {},
  });

  /// 1-12, derived from [month]. Used to order the ledger chronologically.
  int get monthNumber => revenueMonthLabels.indexOf(month) + 1;

  @override
  String get periodLabel => '$month $year';

  @override
  String get axisLabel => month;

  /// This urgency's share of the month — zeroes rather than null for one that
  /// saw no payments, so a chart can plot every series without checking.
  UrgencyTotals totalsFor(RevenueUrgency urgency) =>
      byUrgency[urgency] ?? const UrgencyTotals();

  @override
  double revenueFor(RevenueUrgency urgency) => totalsFor(urgency).revenue;

  @override
  int transactionsFor(RevenueUrgency urgency) => totalsFor(urgency).transactions;

  MonthlyIncome addPayment({required double fee, required RevenueUrgency urgency}) =>
      MonthlyIncome(
        month: month,
        year: year,
        revenue: revenue + fee,
        transactions: transactions + 1,
        byUrgency: {
          ...byUrgency,
          urgency: totalsFor(urgency).addPayment(fee: fee),
        },
      );

  Map<String, dynamic> toJson() => {
        'month': month,
        'year': year,
        'revenue': revenue,
        'transactions': transactions,
        'byUrgency': {
          for (final entry in byUrgency.entries) entry.key.name: entry.value.toJson(),
        },
      };

  factory MonthlyIncome.fromJson(Map<String, dynamic> json) {
    final raw = readObject(json['byUrgency']);
    final revenue = readDouble(json['revenue']);
    final transactions = readInt(json['transactions']);

    // A payload from before the ledger was split has no breakdown. Reading it
    // as three empty buckets would draw flat zero lines under a non-zero
    // total; counting the month as Normal is the least wrong reading, and the
    // one that keeps the series adding up to what is printed above them.
    final byUrgency = raw.isNotEmpty
        ? {
            for (final entry in raw.entries)
              RevenueUrgency.fromName(entry.key):
                  UrgencyTotals.fromJson(readObject(entry.value)),
          }
        : {
            RevenueUrgency.normal:
                UrgencyTotals(revenue: revenue, transactions: transactions),
          };

    return MonthlyIncome(
      month: readString(json['month']),
      year: readInt(json['year']),
      revenue: revenue,
      transactions: transactions,
      byUrgency: byUrgency,
    );
  }
}

/// One calendar year's platform revenue, split by urgency.
///
/// Always derived from the months rather than stored — see
/// [PlatformRevenueSummary.yearlyTotals]. A year that is also written down
/// somewhere is a year that can disagree with the months it is made of.
class YearlyIncome implements RevenuePeriod {
  final int year;

  @override
  final double revenue;

  @override
  final int transactions;

  final Map<RevenueUrgency, UrgencyTotals> byUrgency;

  const YearlyIncome({
    required this.year,
    required this.revenue,
    required this.transactions,
    this.byUrgency = const {},
  });

  /// Adds up [months], which must all belong to the same year.
  factory YearlyIncome.from(int year, Iterable<MonthlyIncome> months) {
    var revenue = 0.0;
    var transactions = 0;
    final byUrgency = <RevenueUrgency, UrgencyTotals>{};

    for (final month in months) {
      revenue += month.revenue;
      transactions += month.transactions;
      for (final urgency in RevenueUrgency.values) {
        final running = byUrgency[urgency] ?? const UrgencyTotals();
        final add = month.totalsFor(urgency);
        byUrgency[urgency] = UrgencyTotals(
          revenue: running.revenue + add.revenue,
          transactions: running.transactions + add.transactions,
        );
      }
    }

    return YearlyIncome(
      year: year,
      revenue: revenue,
      transactions: transactions,
      byUrgency: byUrgency,
    );
  }

  @override
  String get periodLabel => '$year';

  @override
  String get axisLabel => '$year';

  UrgencyTotals totalsFor(RevenueUrgency urgency) =>
      byUrgency[urgency] ?? const UrgencyTotals();

  @override
  double revenueFor(RevenueUrgency urgency) => totalsFor(urgency).revenue;

  @override
  int transactionsFor(RevenueUrgency urgency) => totalsFor(urgency).transactions;

  Map<String, dynamic> toJson() => {
        'year': year,
        'revenue': revenue,
        'transactions': transactions,
        'byUrgency': {
          for (final entry in byUrgency.entries) entry.key.name: entry.value.toJson(),
        },
      };
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

  /// One urgency's revenue across [year] — what the Income screen's Yearly
  /// Revenue bars add up to for that series.
  double revenueForYearBy(RevenueUrgency urgency, int year) => months
      .where((m) => m.year == year)
      .fold(0, (sum, m) => sum + m.revenueFor(urgency));

  /// One urgency's completed payments across [year] — the figure each of the
  /// Income screen's three rings reports.
  int transactionsForYearBy(RevenueUrgency urgency, int year) => months
      .where((m) => m.year == year)
      .fold(0, (sum, m) => sum + m.transactionsFor(urgency));

  /// Every year the ledger has seen a payment in, oldest first.
  List<int> get years {
    final seen = <int>{for (final month in months) month.year};
    return seen.toList()..sort();
  }

  /// The ledger totalled a year at a time, oldest first — what the Income
  /// screen's Yearly Revenue chart plots. Derived from [months] on every read,
  /// so it cannot drift from the months it is made of.
  List<YearlyIncome> get yearlyTotals => [
        for (final year in years)
          YearlyIncome.from(year, months.where((m) => m.year == year)),
      ];

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

  /// The job's urgency, so the ledger can bucket the payment. Reported rather
  /// than inferred from [platformFee]: the fee is a price and prices change,
  /// and a ₱0 fee would otherwise be indistinguishable between a Normal job
  /// and an Urgent one whose charge was waived.
  final RevenueUrgency urgency;

  const CompletedPaymentReport({
    required this.requestId,
    required this.platformFee,
    required this.paidAt,
    this.urgency = RevenueUrgency.normal,
  });

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'platformFee': platformFee,
        'paidAt': writeDate(paidAt),
        'urgency': urgency.name,
      };

  factory CompletedPaymentReport.fromJson(Map<String, dynamic> json) => CompletedPaymentReport(
        requestId: readString(json['requestId']),
        platformFee: readDouble(json['platformFee']),
        paidAt: readDate(json['paidAt']),
        urgency: RevenueUrgency.fromName(readString(json['urgency'])),
      );
}
