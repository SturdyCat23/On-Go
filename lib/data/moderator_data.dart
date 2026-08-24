import 'package:flutter/foundation.dart';
import 'admin_data.dart';
import 'session_store.dart';

enum AccountRole { mechanic, business }

extension AccountRoleLabel on AccountRole {
  String get label => this == AccountRole.mechanic ? 'Mechanic' : 'Business';
}

enum ApprovalStatus { pending, approved, rejected }

class AccountRequest {
  final String id;
  final String name;
  final String email;
  final String userNumber;
  final AccountRole role;
  final DateTime submittedAt;
  final List<String> documents;
  ApprovalStatus status;
  String? reason;
  DateTime? reviewedAt;
  String? reviewerName;
  bool escalated;

  AccountRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.userNumber,
    required this.role,
    required this.submittedAt,
    this.documents = const [],
    this.status = ApprovalStatus.pending,
    this.reason,
    this.reviewedAt,
    this.reviewerName,
    this.escalated = false,
  });

  int get documentCount => documents.length;
}

enum ModAction { approved, rejected, escalated }

extension ModActionLabel on ModAction {
  String get label {
    switch (this) {
      case ModAction.approved:
        return 'approved';
      case ModAction.rejected:
        return 'rejected';
      case ModAction.escalated:
        return 'escalated';
    }
  }
}

/// One entry in the admin-facing activity feed — created automatically
/// whenever a moderator approves, rejects, or escalates an account request.
class ModeratorActivity {
  final String id;
  final ModAction action;
  final String accountId;
  final String accountName;
  final AccountRole role;
  final String moderatorName;
  final DateTime date;
  final String? reason;

  ModeratorActivity({
    required this.id,
    required this.action,
    required this.accountId,
    required this.accountName,
    required this.role,
    required this.moderatorName,
    required this.date,
    this.reason,
  });
}

/// Singleton in-memory store for the moderator flows (Queue / History /
/// Accounts) and the admin-facing activity feed (Notifications). Also the
/// single source of truth for account-approval status — mechanic
/// registration files a request here via [submitRequest], and
/// MechanicAccountStore reads that request's [AccountRequest.status] live
/// to decide whether job actions are unlocked.
class ModerationStore extends ChangeNotifier {
  ModerationStore._internal() {
    _seed();
  }
  static final ModerationStore instance = ModerationStore._internal();

  final List<AccountRequest> _requests = [];
  final List<ModeratorActivity> _activity = [];
  int _lastSeenActivityCount = 0;

  List<AccountRequest> get all => List.unmodifiable(_requests);
  List<AccountRequest> get pending =>
      _requests.where((r) => r.status == ApprovalStatus.pending).toList();
  List<AccountRequest> get approved =>
      _requests.where((r) => r.status == ApprovalStatus.approved).toList();
  List<AccountRequest> get rejected =>
      _requests.where((r) => r.status == ApprovalStatus.rejected).toList();
  List<AccountRequest> get escalated =>
      _requests.where((r) => r.escalated).toList();

  /// Most recent first — this is what Admin's Notifications screen shows.
  List<ModeratorActivity> get activity => _activity.reversed.toList();

  int get unseenActivityCount => _activity.length - _lastSeenActivityCount;

  void markActivitySeen() {
    _lastSeenActivityCount = _activity.length;
    notifyListeners();
  }

  AccountRequest? findRequest(String id) {
    final match = _requests.where((r) => r.id == id);
    return match.isEmpty ? null : match.first;
  }

  /// Files a new Pending approval request — called by registration flows
  /// (currently: mechanic registration). Shows up in the Moderator Queue
  /// tab immediately via [pending]. Returns the new request's id so the
  /// caller can track its status afterwards.
  String submitRequest({
    required String name,
    required String email,
    required AccountRole role,
    List<String> documents = const [],
  }) {
    final id = 'req_${DateTime.now().millisecondsSinceEpoch}';
    final userNumber = 'User - ${(_requests.length + 1).toString().padLeft(5, '0')}';
    _requests.add(AccountRequest(
      id: id,
      name: name,
      email: email,
      userNumber: userNumber,
      role: role,
      submittedAt: DateTime.now(),
      documents: documents,
    ));
    notifyListeners();
    return id;
  }

  void approve(String id, {String? actorName, String? actorId}) {
    final r = _requests.firstWhere((r) => r.id == id);
    final actor = actorName ?? SessionStore.instance.currentModeratorName;
    final resolvedActorId = actorId ?? (actorName == null ? SessionStore.instance.currentModerator?.id : null);
    r.status = ApprovalStatus.approved;
    r.reviewedAt = DateTime.now();
    r.reason = null;
    r.reviewerName = actor;
    _activity.add(ModeratorActivity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      action: ModAction.approved,
      accountId: r.id,
      accountName: r.name,
      role: r.role,
      moderatorName: actor,
      date: DateTime.now(),
    ));
    if (resolvedActorId != null) AdminStore.instance.recordModeratorAction(resolvedActorId);
    notifyListeners();
  }

  void reject(String id, String reason, {String? actorName, String? actorId}) {
    final r = _requests.firstWhere((r) => r.id == id);
    final actor = actorName ?? SessionStore.instance.currentModeratorName;
    final resolvedActorId = actorId ?? (actorName == null ? SessionStore.instance.currentModerator?.id : null);
    final finalReason = reason.isEmpty ? 'No reason given' : reason;
    r.status = ApprovalStatus.rejected;
    r.reviewedAt = DateTime.now();
    r.reason = finalReason;
    r.reviewerName = actor;
    _activity.add(ModeratorActivity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      action: ModAction.rejected,
      accountId: r.id,
      accountName: r.name,
      role: r.role,
      moderatorName: actor,
      date: DateTime.now(),
      reason: finalReason,
    ));
    if (resolvedActorId != null) AdminStore.instance.recordModeratorAction(resolvedActorId);
    notifyListeners();
  }

  void escalate(String id, {String? actorName, String? actorId}) {
    final r = _requests.firstWhere((r) => r.id == id);
    final actor = actorName ?? SessionStore.instance.currentModeratorName;
    final resolvedActorId = actorId ?? (actorName == null ? SessionStore.instance.currentModerator?.id : null);
    r.escalated = true;
    _activity.add(ModeratorActivity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      action: ModAction.escalated,
      accountId: r.id,
      accountName: r.name,
      role: r.role,
      moderatorName: actor,
      date: DateTime.now(),
      reason: 'Flagged for admin review',
    ));
    if (resolvedActorId != null) AdminStore.instance.recordModeratorAction(resolvedActorId);
    notifyListeners();
  }

  void _seed() {
    _requests.addAll([
      AccountRequest(
        id: 'req_001',
        name: 'Pedro Santos',
        email: 'pedrosantos@gmail.com',
        userNumber: 'User - 00001',
        role: AccountRole.mechanic,
        submittedAt: DateTime(2026, 7, 6, 16, 45),
        documents: const ['drivers_license.jpg', 'nbi_clearance.pdf', 'proof_of_address.jpg'],
      ),
      AccountRequest(
        id: 'req_002',
        name: 'Pedro Santos',
        email: 'pedrosantos@gmail.com',
        userNumber: 'User - 00001',
        role: AccountRole.business,
        submittedAt: DateTime(2026, 7, 6, 16, 45),
        documents: const ['business_permit.pdf', 'dti_registration.pdf'],
      ),
      AccountRequest(
        id: 'req_003',
        name: 'Juan Dela Cruz',
        email: 'juandelacruz@gmail.com',
        userNumber: 'User - 00002',
        role: AccountRole.business,
        submittedAt: DateTime(2026, 7, 7, 12, 0),
        documents: const ['business_permit.pdf', 'valid_id.jpg'],
        status: ApprovalStatus.rejected,
        reason: 'Suspicious activity',
        reviewedAt: DateTime(2026, 7, 7, 12, 30),
      ),
      AccountRequest(
        id: 'req_004',
        name: 'Pedro Santos',
        email: 'pedrosantos@gmail.com',
        userNumber: 'User - 00001',
        role: AccountRole.mechanic,
        submittedAt: DateTime(2026, 7, 7, 12, 0),
        documents: const ['drivers_license.jpg', 'nbi_clearance.pdf', 'proof_of_address.jpg'],
        status: ApprovalStatus.approved,
        reviewedAt: DateTime(2026, 7, 7, 12, 15),
      ),
    ]);
  }
}