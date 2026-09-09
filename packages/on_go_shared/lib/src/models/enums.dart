/// The vocabulary both front ends have to agree on, and the only place these
/// spellings are defined.
///
/// Every enum here carries an explicit [wireName]. The name is what crosses
/// the network once the API exists, so it must stay stable even if the Dart
/// identifier is ever renamed — never derive it from `Enum.name`.
library;

/// The kind of account a person is asking to have verified.
///
/// Filed by the mobile app during registration, decided on by a moderator in
/// the admin console.
enum AccountRole {
  mechanic('mechanic', 'Mechanic'),
  business('business', 'Business');

  const AccountRole(this.wireName, this.label);

  final String wireName;

  /// Human-readable, for both UIs.
  final String label;

  static AccountRole fromWire(String value) => AccountRole.values.firstWhere(
        (role) => role.wireName == value,
        orElse: () => AccountRole.mechanic,
      );
}

/// Where a verification request stands. The mobile app reads this to decide
/// whether a mechanic's job actions are unlocked; the console writes it.
enum ApprovalStatus {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected');

  const ApprovalStatus(this.wireName, this.label);

  final String wireName;
  final String label;

  static ApprovalStatus fromWire(String value) => ApprovalStatus.values.firstWhere(
        (status) => status.wireName == value,
        orElse: () => ApprovalStatus.pending,
      );
}

/// What a moderator (or an admin resolving an escalation) did to a request.
enum ModerationAction {
  approved('approved', 'approved'),
  rejected('rejected', 'rejected'),
  escalated('escalated', 'escalated');

  const ModerationAction(this.wireName, this.label);

  final String wireName;
  final String label;

  static ModerationAction fromWire(String value) => ModerationAction.values.firstWhere(
        (action) => action.wireName == value,
        orElse: () => ModerationAction.approved,
      );
}

/// Whether a moderator account may still sign in to the console.
enum ModeratorStatus {
  active('active', 'active'),
  inactive('inactive', 'inactive');

  const ModeratorStatus(this.wireName, this.label);

  final String wireName;
  final String label;

  static ModeratorStatus fromWire(String value) => ModeratorStatus.values.firstWhere(
        (status) => status.wireName == value,
        orElse: () => ModeratorStatus.active,
      );
}

/// What was done, in the console's audit trail.
///
/// The first three are roster changes, which only an admin can make. The rest
/// are queue decisions, made by a moderator or by an admin resolving an
/// escalation — those used to live only in the moderator activity feed, and
/// are recorded here as well so the audit log is the one place every console
/// action can be read from.
enum AuditAction {
  added('added', 'added'),
  removed('removed', 'removed'),
  promoted('promoted', 'promoted'),
  approved('approved', 'approved'),
  rejected('rejected', 'rejected'),
  escalated('escalated', 'escalated');

  const AuditAction(this.wireName, this.label);

  final String wireName;
  final String label;

  static AuditAction fromWire(String value) => AuditAction.values.firstWhere(
        (action) => action.wireName == value,
        orElse: () => AuditAction.added,
      );
}

/// What an uploaded file is, which decides who may see it.
///
/// [mechanicId] is the identity document. It is never shown on a public
/// profile — only the console's review screens ever render it.
enum CredentialKind {
  mechanicId('mechanic_id', 'Mechanic ID'),
  document('document', 'Documents'),
  certification('certification', 'Certifications');

  const CredentialKind(this.wireName, this.label);

  final String wireName;
  final String label;

  static CredentialKind fromWire(String value) => CredentialKind.values.firstWhere(
        (kind) => kind.wireName == value,
        orElse: () => CredentialKind.document,
      );
}

/// Which product surface a signed-in principal belongs to.
///
/// [client] and [mechanic] sign in on the mobile app; [moderator] and [admin]
/// sign in on the console website. The split is enforced at the API boundary
/// once the backend exists — a console token must never open a mobile session
/// and vice versa.
enum UserRole {
  client('client', 'Client', surface: AppSurface.mobile),
  mechanic('mechanic', 'Mechanic', surface: AppSurface.mobile),
  moderator('moderator', 'Moderator', surface: AppSurface.console),
  admin('admin', 'Admin', surface: AppSurface.console);

  const UserRole(this.wireName, this.label, {required this.surface});

  final String wireName;
  final String label;
  final AppSurface surface;

  static UserRole fromWire(String value) => UserRole.values.firstWhere(
        (role) => role.wireName == value,
        orElse: () => UserRole.client,
      );
}

/// The two front ends this system ships.
enum AppSurface {
  /// The Flutter mobile app: Client and Mechanic.
  mobile('mobile'),

  /// The Flutter web console: Admin and Moderator.
  console('console');

  const AppSurface(this.wireName);

  final String wireName;
}
