import 'credential_document.dart';
import 'enums.dart';
import 'json.dart';

/// One account waiting on — or already through — human review.
///
/// Filed by the mobile app when someone finishes registration, listed and
/// decided on in the console, and read back by the mobile app to unlock the
/// mechanic's job actions. It is the one record both surfaces hold an opinion
/// about, which is why it is immutable here: a decision produces a NEW request
/// via [copyWith] rather than mutating one in place, so a stale copy can never
/// masquerade as current.
class AccountVerificationRequest {
  final String id;

  /// Sequential, human-friendly handle a reviewer can read out ('User - 00001').
  /// Assigned by whoever owns the queue, never by the submitting client.
  final String userNumber;

  final String name;
  final String email;
  final AccountRole role;
  final DateTime submittedAt;

  /// File names as the registration flow reported them. Kept as a fallback
  /// label for requests whose uploads this surface cannot reach — [documents]
  /// is the real thing.
  final List<String> documentNames;

  /// The uploads themselves, when this surface can reach them.
  final List<CredentialDocument> documents;

  final ApprovalStatus status;

  /// Why it was rejected. Null unless [status] is [ApprovalStatus.rejected].
  final String? reason;

  final DateTime? reviewedAt;

  /// Display name of the moderator (or admin) who decided it.
  final String? reviewerName;

  /// Flagged by a moderator for an admin to settle. Escalation decides
  /// nothing on its own — the request stays pending until someone rules.
  final bool escalated;

  const AccountVerificationRequest({
    required this.id,
    required this.userNumber,
    required this.name,
    required this.email,
    required this.role,
    required this.submittedAt,
    this.documentNames = const [],
    this.documents = const [],
    this.status = ApprovalStatus.pending,
    this.reason,
    this.reviewedAt,
    this.reviewerName,
    this.escalated = false,
  });

  /// How many files the reviewer has to look at, preferring real uploads over
  /// the names the registration flow reported.
  int get documentCount => documents.isNotEmpty ? documents.length : documentNames.length;

  bool get isPending => status == ApprovalStatus.pending;

  List<CredentialDocument> documentsOfKind(CredentialKind kind) =>
      documents.where((doc) => doc.kind == kind).toList(growable: false);

  AccountVerificationRequest copyWith({
    ApprovalStatus? status,
    String? reason,
    bool clearReason = false,
    DateTime? reviewedAt,
    String? reviewerName,
    bool? escalated,
    List<CredentialDocument>? documents,
  }) {
    return AccountVerificationRequest(
      id: id,
      userNumber: userNumber,
      name: name,
      email: email,
      role: role,
      submittedAt: submittedAt,
      documentNames: documentNames,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      reason: clearReason ? null : (reason ?? this.reason),
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewerName: reviewerName ?? this.reviewerName,
      escalated: escalated ?? this.escalated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userNumber': userNumber,
        'name': name,
        'email': email,
        'role': role.wireName,
        'submittedAt': writeDate(submittedAt),
        'documentNames': documentNames,
        'documents': documents.map((doc) => doc.toJson()).toList(),
        'status': status.wireName,
        'reason': reason,
        'reviewedAt': writeDateOrNull(reviewedAt),
        'reviewerName': reviewerName,
        'escalated': escalated,
      };

  factory AccountVerificationRequest.fromJson(Map<String, dynamic> json) =>
      AccountVerificationRequest(
        id: readString(json['id']),
        userNumber: readString(json['userNumber']),
        name: readString(json['name']),
        email: readString(json['email']),
        role: AccountRole.fromWire(readString(json['role'])),
        submittedAt: readDate(json['submittedAt']),
        documentNames: readStringList(json['documentNames']),
        documents: readObjectList(json['documents'])
            .map(CredentialDocument.fromJson)
            .toList(growable: false),
        status: ApprovalStatus.fromWire(readString(json['status'])),
        reason: readStringOrNull(json['reason']),
        reviewedAt: readDateOrNull(json['reviewedAt']),
        reviewerName: readStringOrNull(json['reviewerName']),
        escalated: json['escalated'] == true,
      );
}

/// What the mobile app sends to open a verification request.
///
/// Everything the queue needs and nothing it does not: no id and no
/// [AccountVerificationRequest.userNumber], because those are assigned by
/// whoever owns the queue, and no status, because a submission is pending by
/// definition.
class SubmitVerificationRequest {
  final String name;
  final String email;
  final AccountRole role;
  final List<String> documentNames;

  const SubmitVerificationRequest({
    required this.name,
    required this.email,
    required this.role,
    this.documentNames = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'role': role.wireName,
        'documentNames': documentNames,
      };

  factory SubmitVerificationRequest.fromJson(Map<String, dynamic> json) =>
      SubmitVerificationRequest(
        name: readString(json['name']),
        email: readString(json['email']),
        role: AccountRole.fromWire(readString(json['role'])),
        documentNames: readStringList(json['documentNames']),
      );
}

/// A moderator's (or an admin's) verdict on one request.
class ModerationDecision {
  final ModerationAction action;

  /// Why, for [ModerationAction.rejected]. Ignored for the other actions.
  final String? reason;

  /// Who decided. The backend will take this from the caller's token rather
  /// than trusting the body; it is carried here so the console's local,
  /// pre-backend implementation records the same field.
  final String actorName;

  /// The moderator account to credit the action to. Null when an admin
  /// resolved an escalation — admins have no throughput counter.
  final String? actorId;

  const ModerationDecision({
    required this.action,
    required this.actorName,
    this.reason,
    this.actorId,
  });

  Map<String, dynamic> toJson() => {
        'action': action.wireName,
        'reason': reason,
        'actorName': actorName,
        'actorId': actorId,
      };

  factory ModerationDecision.fromJson(Map<String, dynamic> json) => ModerationDecision(
        action: ModerationAction.fromWire(readString(json['action'])),
        reason: readStringOrNull(json['reason']),
        actorName: readString(json['actorName']),
        actorId: readStringOrNull(json['actorId']),
      );
}

/// One entry in the console's activity feed, written whenever a request is
/// approved, rejected or escalated. This is what the Admin escalations screen
/// reads.
class ModerationActivity {
  final String id;
  final ModerationAction action;
  final String requestId;
  final String accountName;
  final AccountRole role;
  final String moderatorName;
  final DateTime occurredAt;
  final String? reason;

  const ModerationActivity({
    required this.id,
    required this.action,
    required this.requestId,
    required this.accountName,
    required this.role,
    required this.moderatorName,
    required this.occurredAt,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action.wireName,
        'requestId': requestId,
        'accountName': accountName,
        'role': role.wireName,
        'moderatorName': moderatorName,
        'occurredAt': writeDate(occurredAt),
        'reason': reason,
      };

  factory ModerationActivity.fromJson(Map<String, dynamic> json) => ModerationActivity(
        id: readString(json['id']),
        action: ModerationAction.fromWire(readString(json['action'])),
        requestId: readString(json['requestId']),
        accountName: readString(json['accountName']),
        role: AccountRole.fromWire(readString(json['role'])),
        moderatorName: readString(json['moderatorName']),
        occurredAt: readDate(json['occurredAt']),
        reason: readStringOrNull(json['reason']),
      );
}
