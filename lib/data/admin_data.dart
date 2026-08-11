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

class MonthlyIncome {
  final String month;
  final int year;
  final double revenue;
  final int transactions;

  MonthlyIncome({
    required this.month,
    required this.year,
    required this.revenue,
    required this.transactions,
  });
}

/// Singleton in-memory store backing the Admin shell.
class AdminStore extends ChangeNotifier {
  AdminStore._internal() {
    _seed();
  }
  static final AdminStore instance = AdminStore._internal();

  final List<ModeratorAccount> _moderators = [];
  final List<AuditEntry> _auditLog = [];
  final List<MonthlyIncome> _income = [];

  List<ModeratorAccount> get moderators => List.unmodifiable(_moderators);
  List<AuditEntry> get auditLog => List.unmodifiable(_auditLog);
  List<MonthlyIncome> get income => List.unmodifiable(_income);

  int get activeModCount =>
      _moderators.where((m) => m.status == ModStatus.active).length;
  double get ytdRevenue => _income.fold(0, (sum, m) => sum + m.revenue);
  int get ytdTransactions =>
      _income.fold(0, (sum, m) => sum + m.transactions);

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
        actorName: 'Admin Prime',
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
        actorName: 'Admin Prime',
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

  void _seed() {
    // Moderators & audit log start empty — every entry comes from Add Mod / Remove from here on.
    _income.addAll([
      MonthlyIncome(month: 'Jan', year: 2026, revenue: 42800, transactions: 1248),
      MonthlyIncome(month: 'Feb', year: 2026, revenue: 51200, transactions: 1480),
      MonthlyIncome(month: 'Mar', year: 2026, revenue: 47600, transactions: 1356),
      MonthlyIncome(month: 'Apr', year: 2026, revenue: 63400, transactions: 1712),
      MonthlyIncome(month: 'May', year: 2026, revenue: 58900, transactions: 1590),
      MonthlyIncome(month: 'Jun', year: 2026, revenue: 71600, transactions: 1904),
      MonthlyIncome(month: 'Jul', year: 2026, revenue: 38400, transactions: 940),
    ]);
  }
}