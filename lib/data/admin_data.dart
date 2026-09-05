import 'package:flutter/foundation.dart';

enum ModStatus { active, inactive }

class ModeratorPermissions {
  final bool canApprove;
  final bool canReject;
  final bool canEscalate;

  const ModeratorPermissions({
    this.canApprove = true,
    this.canReject = true,
    this.canEscalate = false,
  });
}

class ModeratorAccount {
  final String id;
  String name;
  final String email;
  String password;
  final String role; // 'Moderator'
  ModStatus status;
  final DateTime addedDate;
  int actionsHandled;
  ModeratorPermissions permissions;

  ModeratorAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.addedDate,
    this.status = ModStatus.active,
    this.actionsHandled = 0,
    this.permissions = const ModeratorPermissions(),
  });

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .map((p) => p.isNotEmpty ? p[0] : '')
      .take(2)
      .join()
      .toUpperCase();
}

enum AuditAction { added, removed, promoted }

extension AuditActionLabel on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.added:
        return 'added';
      case AuditAction.removed:
        return 'removed';
      case AuditAction.promoted:
        return 'promoted';
    }
  }
}

class AuditEntry {
  final String moderatorName;
  final AuditAction action;
  final String role;
  final String actorName;
  final DateTime date;
  final String? reason;

  AuditEntry({
    required this.moderatorName,
    required this.action,
    required this.role,
    required this.actorName,
    required this.date,
    this.reason,
  });
}

/// One month's ONGO platform revenue. [revenue] and [transactions] are
/// mutable because live platform fees (see
/// [AdminStore.recordPlatformRevenue]) accumulate into the month they were
/// collected in rather than replacing the entry.
class MonthlyIncome {
  final String month;
  final int year;
  double revenue;
  int transactions;

  MonthlyIncome({
    required this.month,
    required this.year,
    required this.revenue,
    required this.transactions,
  });
}

/// The name recorded as the actor on Admin-side audit entries. Placeholder
/// until Admin accounts are real — there is no Admin profile to read a name
/// from yet.
const String adminActorName = 'Admin';

/// Singleton in-memory store backing the Admin shell.
///
/// Starts completely empty: moderators, the audit log and the income ledger
/// all fill up from real activity only — moderators from Add Mod, revenue
/// from client payments that actually went through
/// ([recordCompletedPayment]). Nothing here is seeded or sampled.
class AdminStore extends ChangeNotifier {
  AdminStore._internal();
  static final AdminStore instance = AdminStore._internal();

  final List<ModeratorAccount> _moderators = [];
  final List<AuditEntry> _auditLog = [];
  final List<MonthlyIncome> _income = [];

  /// Running total of the priority fees (Urgent +₱50 / Emergency +₱100)
  /// collected from clients at checkout, and how many payments carried one.
  /// Already included in [_income]; kept separately only so the Admin UI can
  /// call out how much of the revenue came from priority fees.
  double _priorityFeeRevenue = 0;
  int _priorityFeeCount = 0;

  List<ModeratorAccount> get moderators => List.unmodifiable(_moderators);
  List<AuditEntry> get auditLog => List.unmodifiable(_auditLog);
  List<MonthlyIncome> get income => List.unmodifiable(_income);

  int get activeModCount =>
      _moderators.where((m) => m.status == ModStatus.active).length;

  /// Platform revenue booked so far this calendar year — the sum of the
  /// priority fees on every payment that actually completed since January.
  double get ytdRevenue => revenueForYear(DateTime.now().year);

  /// Successful payments so far this calendar year, fee-bearing or not.
  int get ytdTransactions => transactionsForYear(DateTime.now().year);

  double revenueForYear(int year) =>
      _income.where((m) => m.year == year).fold(0, (sum, m) => sum + m.revenue);

  int transactionsForYear(int year) =>
      _income.where((m) => m.year == year).fold(0, (sum, m) => sum + m.transactions);

  double get priorityFeeRevenue => _priorityFeeRevenue;
  int get priorityFeeCount => _priorityFeeCount;

  static const List<String> _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Books ONE successful client payment into the month [at] falls in,
  /// creating that month's row if this is the first payment in it. The
  /// payment always counts as a transaction; [platformFee] (0 for Normal
  /// jobs) is what it adds to revenue.
  ///
  /// This is the ONLY way anything enters the Admin revenue figures — it is
  /// called by [QuoteNotificationStore.clientConfirmPayment] once a client
  /// payment actually succeeds, never when a job is merely created or priced.
  /// The fee is the client-side priority charge only; a mechanic's payout
  /// never passes through here.
  void recordCompletedPayment({required double platformFee, DateTime? at}) {
    final fee = platformFee > 0 ? platformFee : 0.0;
    final when = at ?? DateTime.now();
    final month = _monthLabels[when.month - 1];

    final existing = _income.where((m) => m.month == month && m.year == when.year);
    if (existing.isNotEmpty) {
      existing.first.revenue += fee;
      existing.first.transactions++;
    } else {
      _income.insert(
        _insertIndexFor(when),
        MonthlyIncome(month: month, year: when.year, revenue: fee, transactions: 1),
      );
    }

    if (fee > 0) {
      _priorityFeeRevenue += fee;
      _priorityFeeCount++;
    }
    notifyListeners();
  }

  /// Keeps [_income] in chronological order so the revenue charts read left
  /// to right no matter which month a payment lands in.
  int _insertIndexFor(DateTime when) {
    for (var i = 0; i < _income.length; i++) {
      final entry = _income[i];
      final entryMonth = _monthLabels.indexOf(entry.month) + 1;
      if (entry.year > when.year || (entry.year == when.year && entryMonth > when.month)) {
        return i;
      }
    }
    return _income.length;
  }

  void addModerator({
    required String name,
    required String email,
    required String password,
    String role = 'Moderator',
    ModeratorPermissions permissions = const ModeratorPermissions(),
  }) {
    _moderators.add(ModeratorAccount(
      id: 'mod_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      password: password,
      role: role,
      addedDate: DateTime.now(),
      permissions: permissions,
    ));
    _auditLog.insert(
      0,
      AuditEntry(
        moderatorName: name,
        action: AuditAction.added,
        role: role,
        actorName: adminActorName,
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void removeModerator(String id, {String? reason}) {
    final mod = _moderators.firstWhere((m) => m.id == id);
    _moderators.removeWhere((m) => m.id == id);
    _auditLog.insert(
      0,
      AuditEntry(
        moderatorName: mod.name,
        action: AuditAction.removed,
        role: mod.role,
        actorName: adminActorName,
        date: DateTime.now(),
        reason: reason,
      ),
    );
    notifyListeners();
  }

  /// Lets a moderator edit their own display name from Settings.
  void updateModeratorProfile(String id, {String? name}) {
    final mod = _moderators.firstWhere((m) => m.id == id);
    if (name != null && name.trim().isNotEmpty) {
      mod.name = name.trim();
    }
    notifyListeners();
  }

  /// Lets Admin change a moderator's approve/reject/escalate permissions
  /// after the fact, from the Mods tab.
  void updateModeratorPermissions(String id, ModeratorPermissions permissions) {
    final mod = _moderators.firstWhere((m) => m.id == id);
    mod.permissions = permissions;
    notifyListeners();
  }

  /// Verifies [oldPassword] before setting [newPassword]. Returns false
  /// (and leaves the password untouched) if the old password doesn't match.
  bool changeModeratorPassword(String id, {required String oldPassword, required String newPassword}) {
    final mod = _moderators.firstWhere((m) => m.id == id);
    if (mod.password != oldPassword) return false;
    mod.password = newPassword;
    notifyListeners();
    return true;
  }

  /// Checks credentials for the Switch Account flow.
  bool verifyPassword(String id, String password) {
    final match = _moderators.where((m) => m.id == id);
    if (match.isEmpty) return false;
    return match.first.password == password;
  }

  /// Bumps a moderator's throughput count. Called by [ModerationStore]
  /// whenever that moderator approves, rejects, or escalates a request —
  /// this is what drives Overview's "Moderator Throughput" and the Mods
  /// tab's "HANDLED" figure.
  void recordModeratorAction(String moderatorId) {
    final match = _moderators.where((m) => m.id == moderatorId);
    if (match.isEmpty) return;
    match.first.actionsHandled++;
    notifyListeners();
  }

}
