import 'package:flutter/foundation.dart';
import 'admin_data.dart';

/// Tracks which moderator is "logged in" on the moderator side of the app,
/// sourced entirely from [AdminStore.instance.moderators]. The first
/// moderator an admin ever adds becomes the active session automatically.
/// Switching to any other moderator requires that account's password
/// (set when the admin created it, changeable from Settings).
class SessionStore extends ChangeNotifier {
  SessionStore._internal() {
    AdminStore.instance.addListener(_onAdminChange);
    _onAdminChange();
  }
  static final SessionStore instance = SessionStore._internal();

  ModeratorAccount? _current;
  ModeratorAccount? get currentModerator => _current;

  String get currentModeratorName => _current?.name ?? 'No account';

  ModeratorPermissions get currentPermissions =>
      _current?.permissions ??
      const ModeratorPermissions(canApprove: false, canReject: false, canEscalate: false);

  /// Returns true and switches the session if [password] matches the
  /// target moderator's password; returns false (session unchanged) otherwise.
  bool switchTo(String moderatorId, String password) {
    if (!AdminStore.instance.verifyPassword(moderatorId, password)) return false;
    final mods = AdminStore.instance.moderators;
    final match = mods.where((m) => m.id == moderatorId);
    if (match.isEmpty) return false;
    _current = match.first;
    notifyListeners();
    return true;
  }

  void _onAdminChange() {
    final mods = AdminStore.instance.moderators;
    if (mods.isEmpty) {
      _current = null;
    } else if (_current == null || !mods.any((m) => m.id == _current!.id)) {
      _current = mods.first;
    }
    notifyListeners();
  }
}