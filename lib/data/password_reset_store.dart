import 'dart:math';

import 'package:flutter/foundation.dart';

import '../widgets/password_strength.dart';
import 'client_account_store.dart';
import 'mechanic_account_store.dart';

/// Which account a reset is for. Resolved once, when the code is issued, so a
/// verified reset can only ever rewrite the account it was requested for.
///
/// Only the two roles this app signs in. A moderator resets their password in
/// the admin console, against the directory that holds their account — this
/// app cannot see it and must not be able to write to it.
enum ResetAccountKind { client, mechanic }

enum ResetRequestResult { codeSent, unknownAccount, missingEmail }

enum ResetVerifyResult { verified, incorrectCode, expired, tooManyAttempts, noActiveRequest }

enum ResetCompleteResult { success, notVerified, expired, tooShort, tooWeak, mismatch, accountGone }

/// Drives "Forgot Password?": issues a one-time code, checks it, and writes the
/// new password into whichever store owns the account.
///
/// There is no mail server in this app yet, so the code is not emailed — it is
/// surfaced on screen, clearly labelled as standing in for the email. Swapping
/// that for a real delivery later means changing [_issueCode] and hiding
/// [visibleCode]; nothing else in the flow depends on the code being visible.
class PasswordResetStore extends ChangeNotifier {
  PasswordResetStore._internal();
  static final PasswordResetStore instance = PasswordResetStore._internal();

  /// How long a code stays usable. Short enough that a code left on a screen
  /// is not a standing key to the account.
  static const Duration codeLifetime = Duration(minutes: 10);

  /// Wrong guesses before the code is burned and the user has to request a
  /// new one — a six-digit code is only worth anything if it cannot be
  /// brute-forced.
  static const int maxAttempts = 5;

  /// The same floor the registration forms use.
  static const int minPasswordLength = 8;

  String? _email;
  ResetAccountKind? _kind;
  String? _code;
  DateTime? _expiresAt;
  int _attempts = 0;
  bool _verified = false;

  String? get email => _email;
  bool get hasActiveRequest => _code != null;
  bool get isVerified => _verified;
  int get attemptsRemaining => maxAttempts - _attempts;

  /// The code that would have been emailed. Only for the stand-in notice on
  /// screen; the flow itself never reads it.
  String? get visibleCode => _code;

  DateTime? get expiresAt => _expiresAt;

  bool get isExpired {
    final expiry = _expiresAt;
    return expiry != null && DateTime.now().isAfter(expiry);
  }

  /// Looks up the account and issues a code. Reports [unknownAccount] when no
  /// account carries that email — the app has no user directory to enumerate,
  /// so there is nothing gained by being vague here.
  ResetRequestResult requestReset(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return ResetRequestResult.missingEmail;

    final client = ClientAccountStore.instance;
    final mechanic = MechanicAccountStore.instance;

    if (client.hasAccount && client.email.trim().toLowerCase() == normalized) {
      _issueCode(normalized, ResetAccountKind.client);
      return ResetRequestResult.codeSent;
    }
    if (mechanic.hasAccount && mechanic.email.trim().toLowerCase() == normalized) {
      _issueCode(normalized, ResetAccountKind.mechanic);
      return ResetRequestResult.codeSent;
    }
    return ResetRequestResult.unknownAccount;
  }

  void _issueCode(String email, ResetAccountKind kind) {
    final random = Random.secure();
    _email = email;
    _kind = kind;
    _code = List.generate(6, (_) => random.nextInt(10)).join();
    _expiresAt = DateTime.now().add(codeLifetime);
    _attempts = 0;
    _verified = false;
    notifyListeners();
  }

  ResetVerifyResult verifyCode(String code) {
    if (_code == null) return ResetVerifyResult.noActiveRequest;
    if (isExpired) {
      _clear();
      return ResetVerifyResult.expired;
    }
    if (code.trim() != _code) {
      _attempts++;
      if (_attempts >= maxAttempts) {
        _clear();
        return ResetVerifyResult.tooManyAttempts;
      }
      notifyListeners();
      return ResetVerifyResult.incorrectCode;
    }
    _verified = true;
    notifyListeners();
    return ResetVerifyResult.verified;
  }

  /// Writes the new password, then burns the request so a code can never be
  /// used twice. Applies the same rules the rest of the app applies when a
  /// password is created: at least [minPasswordLength] characters, and not a
  /// password [evaluatePasswordStrength] calls weak.
  ResetCompleteResult completeReset({
    required String password,
    required String confirmPassword,
  }) {
    if (!_verified || _code == null) return ResetCompleteResult.notVerified;
    if (isExpired) {
      _clear();
      return ResetCompleteResult.expired;
    }
    if (password.length < minPasswordLength) return ResetCompleteResult.tooShort;
    if (evaluatePasswordStrength(password) == PasswordStrength.weak) {
      return ResetCompleteResult.tooWeak;
    }
    if (password != confirmPassword) return ResetCompleteResult.mismatch;

    final written = _write(password);
    if (!written) {
      _clear();
      return ResetCompleteResult.accountGone;
    }

    _clear();
    return ResetCompleteResult.success;
  }

  bool _write(String password) {
    switch (_kind) {
      case ResetAccountKind.client:
        final store = ClientAccountStore.instance;
        if (!store.hasAccount) return false;
        store.resetPassword(password);
        return true;
      case ResetAccountKind.mechanic:
        final store = MechanicAccountStore.instance;
        if (!store.hasAccount) return false;
        store.resetPassword(password);
        return true;
      case null:
        return false;
    }
  }

  /// Abandons the request — on cancel, on success, and whenever a code dies.
  void cancel() => _clear();

  void _clear() {
    _email = null;
    _kind = null;
    _code = null;
    _expiresAt = null;
    _attempts = 0;
    _verified = false;
    notifyListeners();
  }
}
