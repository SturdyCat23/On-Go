import 'package:on_go_shared/on_go_shared.dart';

import 'local_moderator_directory_service.dart';

/// Sign-in for the console, against the moderator directory it holds.
///
/// Two roles and only two. A Client or Mechanic typing their email here gets
/// [SignInFailure.wrongSurface] and a pointer back to the mobile app, the
/// mirror image of what the app does to an admin — the app-level half of the
/// rule the backend will enforce on the token.
class LocalConsoleAuthService implements AuthApi {
  LocalConsoleAuthService(this._directory);

  final LocalModeratorDirectoryService _directory;

  /// The single built-in admin, until admin accounts are real. It is the same
  /// shortcut the mobile Admin panel had, kept so the console is usable from a
  /// clean start — someone has to be able to create the first moderator.
  static const String adminUsername = 'admin';

  /// Usernames that belong to the other application.
  static const Set<String> _mobileUsernames = {
    'client',
    'demo-client',
    'mechanic',
    'demo-mechanic',
  };

  @override
  Future<SignInResult> signIn(SignInRequest request) async {
    final identifier = request.identifier.trim().toLowerCase();
    if (identifier.isEmpty) {
      return const SignInResult.failed(SignInFailure.unknownAccount);
    }

    if (request.surface == AppSurface.console && _mobileUsernames.contains(identifier)) {
      return const SignInResult.failed(SignInFailure.wrongSurface);
    }

    if (identifier == adminUsername) {
      return const SignInResult.success(AuthenticatedUser(
        displayName: LocalModeratorDirectoryService.adminActorName,
        role: UserRole.admin,
      ));
    }

    final account = _directory.findByEmail(identifier);
    if (account == null) {
      return const SignInResult.failed(SignInFailure.unknownAccount);
    }
    if (!_directory.verifyPassword(account.id, request.password)) {
      return const SignInResult.failed(SignInFailure.wrongPassword);
    }
    if (!account.isActive) {
      return const SignInResult.failed(SignInFailure.accountInactive);
    }

    return SignInResult.success(AuthenticatedUser(
      accountId: account.id,
      displayName: account.name,
      email: account.email,
      role: UserRole.moderator,
    ));
  }

  @override
  Future<bool> changePassword({
    required String accountId,
    required String currentPassword,
    required String newPassword,
  }) async =>
      _directory.changePassword(
        accountId,
        oldPassword: currentPassword,
        newPassword: newPassword,
      );

  @override
  Future<bool> resetPassword({
    required String accountId,
    required String newPassword,
  }) async =>
      _directory.resetPassword(accountId, newPassword);

  @override
  Future<void> signOut() async {
    // Nothing to revoke while sessions are local; the console session object
    // clears itself and the router falls back to Sign In.
  }
}
