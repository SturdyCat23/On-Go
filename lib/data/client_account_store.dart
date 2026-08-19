import 'package:flutter/foundation.dart';

/// Tracks whether a client account has been created this session. There's
/// no backend yet, so this is intentionally simple and in-memory — same
/// pattern as every other store in this app (QuoteNotificationStore,
/// ReviewStore, etc.). Once real auth exists, this whole file goes away.
class ClientAccountStore extends ChangeNotifier {
  ClientAccountStore._internal();
  static final ClientAccountStore instance = ClientAccountStore._internal();

  bool _hasAccount = false;
  String? name;
  String? email;

  bool get hasAccount => _hasAccount;

  void registerAccount({required String name, required String email}) {
    _hasAccount = true;
    this.name = name;
    this.email = email;
    notifyListeners();
  }
}