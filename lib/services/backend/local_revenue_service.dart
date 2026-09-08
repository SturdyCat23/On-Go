import 'dart:async';

import 'package:on_go_shared/on_go_shared.dart';

/// This device's record of the payments it has completed.
///
/// The Admin income screens live in the console and read the real ledger from
/// the backend. All the mobile app owes that ledger is a report per successful
/// payment, which is what [reportCompletedPayment] takes. Until there is
/// somewhere to send it, the report is kept here rather than dropped, so the
/// call site behaves the same on the day it starts going over the wire.
///
/// [fetchSummary] therefore answers for this device only, and no mobile screen
/// reads it — it is here because the interface is shared, and because a
/// summary of what this phone reported is a genuinely useful thing to inspect
/// while debugging.
class LocalRevenueService implements PlatformRevenueApi {
  final List<MonthlyIncome> _months = [];
  final Set<String> _bookedRequestIds = {};
  double _priorityFeeRevenue = 0;
  int _priorityFeeCount = 0;

  final StreamController<PlatformRevenueSummary> _changes =
      StreamController<PlatformRevenueSummary>.broadcast();

  PlatformRevenueSummary get _summary => PlatformRevenueSummary(
        months: List<MonthlyIncome>.unmodifiable(_months),
        priorityFeeRevenue: _priorityFeeRevenue,
        priorityFeeCount: _priorityFeeCount,
      );

  @override
  Future<void> reportCompletedPayment(CompletedPaymentReport payment) async {
    // A job can only be paid once, so a retry must not double-count it.
    if (!_bookedRequestIds.add(payment.requestId)) return;

    final fee = payment.platformFee > 0 ? payment.platformFee : 0.0;
    final month = revenueMonthLabelFor(payment.paidAt);
    final year = payment.paidAt.year;

    final index = _months.indexWhere((m) => m.month == month && m.year == year);
    if (index >= 0) {
      _months[index] = _months[index].addPayment(fee: fee);
    } else {
      _months.insert(
        _insertIndexFor(payment.paidAt),
        MonthlyIncome(month: month, year: year, revenue: fee, transactions: 1),
      );
    }

    if (fee > 0) {
      _priorityFeeRevenue += fee;
      _priorityFeeCount++;
    }
    if (!_changes.isClosed) _changes.add(_summary);
  }

  /// Keeps the ledger in chronological order no matter which month a payment
  /// lands in, so a chart built from it reads left to right.
  int _insertIndexFor(DateTime when) {
    for (var i = 0; i < _months.length; i++) {
      final entry = _months[i];
      if (entry.year > when.year ||
          (entry.year == when.year && entry.monthNumber > when.month)) {
        return i;
      }
    }
    return _months.length;
  }

  @override
  Future<PlatformRevenueSummary> fetchSummary() async => _summary;

  @override
  Stream<PlatformRevenueSummary> watchSummary() async* {
    yield _summary;
    yield* _changes.stream;
  }
}
