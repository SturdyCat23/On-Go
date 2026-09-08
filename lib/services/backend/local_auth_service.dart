import 'package:on_go_shared/on_go_shared.dart';

import '../../data/client_account_store.dart';
import '../../data/mechanic_account_store.dart';

/// Sign-in for the mobile app, against the accounts this device knows about.
///
/// Two things it will not do, both of them deliberate:
///
/// * It never signs anyone in as Admin or Moderator. Those roles belong to the
///   console website, so an attempt reports [SignInFailure.wrongSurface] and
///   the Sign In screen says where to go instead. This is the app-level half
///   of the rule the backend will enforce for real.
/// * It never invents an account. The demo shortcuts below are the same ones
///   the app has always had for local testing, and each still opens the real
///   store rather than a parallel fake identity.
class LocalAuthService implements AuthApi {
  /// Usernames that open a throwaway session for local testing, mapped to the
  /// role they open it as.
  static const Map<String, UserRole> _demoUsernames = {
    'client': UserRole.client,
    'demo-client': UserRole.client,
    'mechanic': UserRole.mechanic,
    'demo-mechanic': UserRole.mechanic,
  };

  /// Usernames that used to open the Admin and Moderator shells from here.
  /// Recognised only so the screen can point at the console instead of
  /// reporting them as unknown accounts.
  static const Set<String> _consoleUsernames = {'admin', 'moderator'};

  @override
  Future<SignInResult> signIn(SignInRequest request) async {
    final identifier = request.identifier.trim().toLowerCase();
    if (identifier.isEmpty) {
      return const SignInResult.failed(SignInFailure.unknownAccount);
    }

    if (request.surface == AppSurface.mobile && _consoleUsernames.contains(identifier)) {
      return const SignInResult.failed(SignInFailure.wrongSurface);
    }

    final demoRole = _demoUsernames[identifier];
    if (demoRole != null) return SignInResult.success(_enterDemo(demoRole));

    final client = ClientAccountStore.instance;
    if (client.hasAccount &&
        client.email.trim().toLowerCase() == identifier &&
        client.verifyPassword(request.password)) {
      return SignInResult.success(AuthenticatedUser(
        displayName: client.name,
        email: client.email,
        role: UserRole.client,
      ));
    }

    final mechanic = MechanicAccountStore.instance;
    if (mechanic.hasAccount &&
        mechanic.email.trim().toLowerCase() == identifier &&
        mechanic.verifyPassword(request.password)) {
      return SignInResult.success(AuthenticatedUser(
        displayName: mechanic.name,
        email: mechanic.email,
        role: UserRole.mechanic,
      ));
    }

    // A moderator's email would have matched neither store — their account
    // lives in the console's directory, which this app cannot see. Reporting
    // it as unknown is the truth from here.
    return const SignInResult.failed(SignInFailure.unknownAccount);
  }

  /// Opens a demo session, preserving an account that was really registered
  /// this session rather than overwriting it with a throwaway identity.
  AuthenticatedUser _enterDemo(UserRole role) {
    if (role == UserRole.client) {
      final client = ClientAccountStore.instance;
      if (!client.hasAccount) client.enterDemoMode();
      return AuthenticatedUser(
        displayName: client.name,
        email: client.email,
        role: UserRole.client,
      );
    }

    final mechanic = MechanicAccountStore.instance;
    if (!mechanic.hasAccount) mechanic.enterDemoMode();
    return AuthenticatedUser(
      displayName: mechanic.name,
      email: mechanic.email,
      role: UserRole.mechanic,
    );
  }

  @override
  Future<bool> changePassword({
    required String accountId,
    required String currentPassword,
    required String newPassword,
  }) async {
    // The mobile stores own their own passwords and each Settings screen calls
    // its own store directly, which is where the per-screen rules live. This
    // exists for the day both surfaces go through one auth service.
    throw const ApiException.unsupported(
      'Mobile password changes go through the account store that owns them.',
    );
  }

  @override
  Future<bool> resetPassword({
    required String accountId,
    required String newPassword,
  }) async {
    throw const ApiException.unsupported(
      'Mobile password resets go through PasswordResetStore.',
    );
  }

  @override
  Future<void> signOut() async {
    // Nothing to revoke while sessions are local: the Sign In screen replaces
    // the whole navigator stack, which is the sign-out.
  }
}
