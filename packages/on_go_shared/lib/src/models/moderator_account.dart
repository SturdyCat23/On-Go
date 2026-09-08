import 'enums.dart';
import 'json.dart';

/// What an admin has allowed one moderator to do.
///
/// Read by the console to enable or disable controls, and re-checked by the
/// backend on every write once it exists — a permission that only hides a
/// button is not a permission.
class ModeratorPermissions {
  final bool canApprove;
  final bool canReject;
  final bool canEscalate;

  /// Whether this moderator may set the mobile app's Sign In / Welcome
  /// background photo. Off by default, like [canEscalate] — the admin grants
  /// it deliberately. An admin's own access never depends on it.
  final bool canChangeBackground;

  const ModeratorPermissions({
    this.canApprove = true,
    this.canReject = true,
    this.canEscalate = false,
    this.canChangeBackground = false,
  });

  /// What a signed-out (or account-less) console session is allowed: nothing.
  static const ModeratorPermissions none = ModeratorPermissions(
    canApprove: false,
    canReject: false,
    canEscalate: false,
    canChangeBackground: false,
  );

  /// An admin resolving an escalation acts with full rights.
  static const ModeratorPermissions all = ModeratorPermissions(
    canApprove: true,
    canReject: true,
    canEscalate: true,
    canChangeBackground: true,
  );

  ModeratorPermissions copyWith({
    bool? canApprove,
    bool? canReject,
    bool? canEscalate,
    bool? canChangeBackground,
  }) {
    return ModeratorPermissions(
      canApprove: canApprove ?? this.canApprove,
      canReject: canReject ?? this.canReject,
      canEscalate: canEscalate ?? this.canEscalate,
      canChangeBackground: canChangeBackground ?? this.canChangeBackground,
    );
  }

  Map<String, dynamic> toJson() => {
        'canApprove': canApprove,
        'canReject': canReject,
        'canEscalate': canEscalate,
        'canChangeBackground': canChangeBackground,
      };

  factory ModeratorPermissions.fromJson(Map<String, dynamic> json) => ModeratorPermissions(
        canApprove: json['canApprove'] == true,
        canReject: json['canReject'] == true,
        canEscalate: json['canEscalate'] == true,
        canChangeBackground: json['canChangeBackground'] == true,
      );
}

/// A moderator account, as the console renders it.
///
/// Note what is NOT here: the password. Credentials never travel inside a
/// directory record — they go through [AuthApi] and nowhere else.
class ModeratorAccount {
  final String id;
  final String name;
  final String email;

  /// Job title shown in the console. 'Moderator' today; the field exists so a
  /// second console role can be added without a migration.
  final String role;

  final ModeratorStatus status;
  final DateTime addedAt;

  /// How many requests this moderator has approved, rejected or escalated.
  /// Drives the Overview throughput chart and the roster's HANDLED column.
  final int actionsHandled;

  final ModeratorPermissions permissions;

  /// Where the profile photo lives, or null while the account is on the
  /// default avatar. Opaque, like [CredentialDocument.uri].
  final String? photoUrl;

  const ModeratorAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.addedAt,
    this.status = ModeratorStatus.active,
    this.actionsHandled = 0,
    this.permissions = const ModeratorPermissions(),
    this.photoUrl,
  });

  bool get isActive => status == ModeratorStatus.active;

  /// Up to two initials, for the avatar fallback.
  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .map((part) => part.isNotEmpty ? part[0] : '')
      .take(2)
      .join()
      .toUpperCase();

  ModeratorAccount copyWith({
    String? name,
    ModeratorStatus? status,
    int? actionsHandled,
    ModeratorPermissions? permissions,
    String? photoUrl,
  }) {
    return ModeratorAccount(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      addedAt: addedAt,
      status: status ?? this.status,
      actionsHandled: actionsHandled ?? this.actionsHandled,
      permissions: permissions ?? this.permissions,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'status': status.wireName,
        'addedAt': writeDate(addedAt),
        'actionsHandled': actionsHandled,
        'permissions': permissions.toJson(),
        'photoUrl': photoUrl,
      };

  factory ModeratorAccount.fromJson(Map<String, dynamic> json) => ModeratorAccount(
        id: readString(json['id']),
        name: readString(json['name']),
        email: readString(json['email']),
        role: readString(json['role']),
        status: ModeratorStatus.fromWire(readString(json['status'])),
        addedAt: readDate(json['addedAt']),
        actionsHandled: readInt(json['actionsHandled']),
        permissions: json['permissions'] is Map
            ? ModeratorPermissions.fromJson(
                Map<String, dynamic>.from(json['permissions'] as Map))
            : const ModeratorPermissions(),
        photoUrl: readStringOrNull(json['photoUrl']),
      );
}

/// What an admin sends to create a moderator.
///
/// The temporary password is here because creating an account is the one
/// moment a password legitimately crosses this boundary. It is write-only —
/// nothing ever reads it back out of [ModeratorAccount].
class CreateModeratorRequest {
  final String name;
  final String email;
  final String temporaryPassword;
  final String role;
  final ModeratorPermissions permissions;

  const CreateModeratorRequest({
    required this.name,
    required this.email,
    required this.temporaryPassword,
    this.role = 'Moderator',
    this.permissions = const ModeratorPermissions(),
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'temporaryPassword': temporaryPassword,
        'role': role,
        'permissions': permissions.toJson(),
      };

  factory CreateModeratorRequest.fromJson(Map<String, dynamic> json) => CreateModeratorRequest(
        name: readString(json['name']),
        email: readString(json['email']),
        temporaryPassword: readString(json['temporaryPassword']),
        role: readString(json['role']),
        permissions: json['permissions'] is Map
            ? ModeratorPermissions.fromJson(
                Map<String, dynamic>.from(json['permissions'] as Map))
            : const ModeratorPermissions(),
      );
}

/// One change to the moderator roster, kept for the Audit log.
class AuditEntry {
  final String id;
  final String moderatorName;
  final AuditAction action;
  final String role;

  /// Who made the change — the admin's display name.
  final String actorName;

  final DateTime occurredAt;
  final String? reason;

  const AuditEntry({
    required this.id,
    required this.moderatorName,
    required this.action,
    required this.role,
    required this.actorName,
    required this.occurredAt,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'moderatorName': moderatorName,
        'action': action.wireName,
        'role': role,
        'actorName': actorName,
        'occurredAt': writeDate(occurredAt),
        'reason': reason,
      };

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        id: readString(json['id']),
        moderatorName: readString(json['moderatorName']),
        action: AuditAction.fromWire(readString(json['action'])),
        role: readString(json['role']),
        actorName: readString(json['actorName']),
        occurredAt: readDate(json['occurredAt']),
        reason: readStringOrNull(json['reason']),
      );
}
