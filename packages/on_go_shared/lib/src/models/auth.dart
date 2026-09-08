import 'enums.dart';
import 'json.dart';

/// What a caller types to sign in. Password-carrying, so it only ever travels
/// to [AuthApi] and only over TLS once a real transport exists.
class SignInRequest {
  /// Email address, or one of the demo usernames while the product is
  /// pre-backend.
  final String identifier;

  final String password;

  /// Which front end is asking. The backend will refuse a console role signing
  /// in from [AppSurface.mobile] and vice versa, so a leaked moderator
  /// password cannot open a mobile session.
  final AppSurface surface;

  const SignInRequest({
    required this.identifier,
    required this.password,
    required this.surface,
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
        'surface': surface.wireName,
      };
}

/// Who is signed in, once [AuthApi.signIn] has said so.
///
/// [accountId] is null for the demo identities the app still supports and for
/// the single built-in admin, neither of which has a directory record yet.
class AuthenticatedUser {
  final String? accountId;
  final String displayName;
  final String email;
  final UserRole role;

  const AuthenticatedUser({
    required this.displayName,
    required this.role,
    this.accountId,
    this.email = '',
  });

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'displayName': displayName,
        'email': email,
        'role': role.wireName,
      };

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) => AuthenticatedUser(
        accountId: readStringOrNull(json['accountId']),
        displayName: readString(json['displayName']),
        email: readString(json['email']),
        role: UserRole.fromWire(readString(json['role'])),
      );
}

/// Why a sign-in did not go through.
///
/// [wrongSurface] is its own case on purpose: an admin typing their password
/// into the mobile app should be told to use the console, not told their
/// password is wrong.
enum SignInFailure {
  unknownAccount,
  wrongPassword,
  wrongSurface,
  accountInactive,
}

/// The result of a sign-in attempt: exactly one of [user] or [failure].
class SignInResult {
  final AuthenticatedUser? user;
  final SignInFailure? failure;

  const SignInResult.success(AuthenticatedUser this.user) : failure = null;

  const SignInResult.failed(SignInFailure this.failure) : user = null;

  bool get isSuccess => user != null;
}
