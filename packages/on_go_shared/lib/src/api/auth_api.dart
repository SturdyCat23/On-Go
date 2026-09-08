import '../models/auth.dart';

/// Sign-in, shared by both front ends because both do the same thing with it:
/// hand over an identifier and a password, get back who that is.
///
/// The surface split is enforced here rather than in either UI — see
/// [SignInRequest.surface] — so neither app has to be trusted to police it.
abstract interface class AuthApi {
  /// Verifies credentials. Never throws for bad credentials: a wrong password
  /// is an expected answer, not an exceptional one, and comes back as
  /// [SignInResult.failed].
  Future<SignInResult> signIn(SignInRequest request);

  /// Changes a signed-in account's own password. Returns false when
  /// [currentPassword] does not match, leaving the password untouched.
  Future<bool> changePassword({
    required String accountId,
    required String currentPassword,
    required String newPassword,
  });

  /// Sets a password without the old one, for a reset that proved ownership
  /// another way (a one-time code today). Returns false when the account is
  /// gone.
  Future<bool> resetPassword({
    required String accountId,
    required String newPassword,
  });

  /// Ends the session. A no-op for the local implementations; the networked
  /// one revokes the token.
  Future<void> signOut();
}
