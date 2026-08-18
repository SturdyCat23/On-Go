/// Tracks which UI shell is currently active, so shared stores (like
/// ReviewStore and QuoteNotificationStore) can enforce who's allowed to
/// call which methods at runtime — not just by what buttons exist on screen.
///
/// Todo: replace with real auth/role claims once login exists. Until then,
/// ClientHomeScreen / MechanicHomeScreen set this the moment they mount.
enum AppRole { none, client, mechanic, moderator, admin }

class AppSession {
  AppSession._internal();
  static final AppSession instance = AppSession._internal();

  AppRole currentRole = AppRole.none;

  /// Identifies "who's looking" for viewer-scoped interactions like
  /// liking a review — distinct from role, since both Client and Mechanic
  /// UIs can like reviews (only writing a review is role-gated).
  String? currentViewerName;

  void setRole(AppRole role, {String? viewerName}) {
    currentRole = role;
    currentViewerName = viewerName;
  }
}