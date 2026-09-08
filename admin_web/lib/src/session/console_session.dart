import 'dart:async';

import 'package:flutter/foundation.dart';

import '../backend/console_backend.dart';

/// Who is signed in to the console, and what they are allowed to do.
///
/// One object rather than a per-screen check, because the answer decides three
/// separate things: which navigation the shell shows, which routes resolve, and
/// which arguments a decision is submitted with. A screen that needs any of
/// those reads it here.
///
/// Nothing about permissions is enforced *only* here — the services re-check
/// every one. This is what the UI uses to avoid offering an action that would
/// be refused.
class ConsoleSession extends ChangeNotifier {
  ConsoleSession._internal();
  static final ConsoleSession instance = ConsoleSession._internal();

  AuthenticatedUser? _user;
  ModeratorAccount? _moderator;
  StreamSubscription<List<ModeratorAccount>>? _rosterWatch;

  /// The signed-in principal, or null when nobody is.
  AuthenticatedUser? get user => _user;

  bool get isSignedIn => _user != null;

  bool get isAdmin => _user?.role == UserRole.admin;

  bool get isModerator => _user?.role == UserRole.moderator;

  /// The signed-in moderator's directory record, kept current so a permission
  /// an admin changes mid-session takes effect without a re-login. Null when
  /// an admin is signed in, or nobody is.
  ModeratorAccount? get moderator => _moderator;

  /// The name to record as the actor on anything this session decides.
  String get actorName => _moderator?.name ?? _user?.displayName ?? 'Unknown';

  /// The moderator account to credit an action to, or null for an admin —
  /// which is exactly what [ModerationDecision.actorId] means.
  String? get actorId => _moderator?.id;

  /// What this session may do. Admins hold everything; a moderator holds what
  /// their account was granted; a signed-out session holds nothing.
  ModeratorPermissions get permissions {
    if (isAdmin) return ModeratorPermissions.all;
    return _moderator?.permissions ?? ModeratorPermissions.none;
  }

  /// Signs in through [ConsoleBackend.auth] and, for a moderator, starts
  /// tracking their directory record.
  Future<SignInResult> signIn(String identifier, String password) async {
    final result = await ConsoleBackend.instance.auth.signIn(
      SignInRequest(
        identifier: identifier,
        password: password,
        surface: AppSurface.console,
      ),
    );

    final user = result.user;
    if (user == null) return result;

    _user = user;
    await _rosterWatch?.cancel();
    _rosterWatch = null;
    _moderator = null;

    final accountId = user.accountId;
    if (user.role == UserRole.moderator && accountId != null) {
      _rosterWatch = ConsoleBackend.instance.moderators
          .watchModerators()
          .listen((roster) => _onRosterChanged(accountId, roster));
    }

    notifyListeners();
    return result;
  }

  /// Keeps [moderator] in step with the roster, and signs the session out if
  /// the account it belongs to is removed while it is open.
  void _onRosterChanged(String accountId, List<ModeratorAccount> roster) {
    for (final account in roster) {
      if (account.id == accountId) {
        if (_moderator != account) {
          _moderator = account;
          notifyListeners();
        }
        return;
      }
    }
    // The admin removed this account. There is nothing left to be signed in as.
    unawaited(signOut());
  }

  Future<void> signOut() async {
    await _rosterWatch?.cancel();
    _rosterWatch = null;
    _user = null;
    _moderator = null;
    await ConsoleBackend.instance.auth.signOut();
    notifyListeners();
  }
}
