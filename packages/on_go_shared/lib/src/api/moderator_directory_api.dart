import '../models/moderator_account.dart';

/// The moderator roster and the audit trail behind it.
///
/// Console-only: the mobile app has no business listing staff accounts, and
/// once the backend exists these routes sit behind an admin-scoped token.
abstract interface class ModeratorDirectoryApi {
  /// Every moderator account, in the order they were added.
  Future<List<ModeratorAccount>> listModerators();

  /// A live view of the roster.
  Stream<List<ModeratorAccount>> watchModerators();

  /// Creates a moderator and returns the stored record (without the password).
  Future<ModeratorAccount> createModerator(CreateModeratorRequest request);

  /// Removes a moderator, recording [reason] on the audit entry.
  Future<void> removeModerator(String moderatorId, {String? reason});

  /// Replaces one moderator's permissions. Admin only.
  Future<ModeratorAccount> updatePermissions(
    String moderatorId,
    ModeratorPermissions permissions,
  );

  /// Updates the parts of a profile a moderator owns themselves — their
  /// display name and photo. Email and role stay admin-owned.
  Future<ModeratorAccount> updateProfile(
    String moderatorId, {
    String? name,
    String? photoUrl,
  });

  /// The roster's audit log, newest first.
  Future<List<AuditEntry>> listAuditLog();

  /// A live view of the audit log.
  Stream<List<AuditEntry>> watchAuditLog();
}
