import 'package:flutter/foundation.dart';

/// Tracks the client's account this session — profile info, photo, and
/// password. There's no backend yet, so this is intentionally simple and
/// in-memory, same pattern as every other store in this app
/// (QuoteNotificationStore, ReviewStore, etc.). Once real auth exists, this
/// whole file goes away.
class ClientAccountStore extends ChangeNotifier {
  ClientAccountStore._internal();
  static final ClientAccountStore instance = ClientAccountStore._internal();

  static const Duration photoChangeCooldown = Duration(days: 30);

  bool _hasAccount = false;
  bool get hasAccount => _hasAccount;

  String firstName = '';
  String lastName = '';
  String email = '';
  String address = '';
  String phone = '';
  String _password = '';

  /// Local file path, or a remote URL if the client signed up with Google.
  String? photoPath;
  bool photoIsNetwork = false;
  DateTime? photoLastChangedAt;

  String get name => '$firstName $lastName'.trim();

  void registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String address,
    required String phone,
    required String password,
    String? photoPath,
    bool photoIsNetwork = false,
  }) {
    _hasAccount = true;
    this.firstName = firstName;
    this.lastName = lastName;
    this.email = email;
    this.address = address;
    this.phone = phone;
    _password = password;
    this.photoPath = photoPath;
    this.photoIsNetwork = photoIsNetwork;
    photoLastChangedAt = photoPath != null ? DateTime.now() : null;
    notifyListeners();
  }

  bool get canChangePhoto {
    if (photoLastChangedAt == null) return true;
    return DateTime.now().difference(photoLastChangedAt!) >= photoChangeCooldown;
  }

  /// When the client will next be allowed to change their photo — only
  /// meaningful when [canChangePhoto] is false.
  DateTime? get nextPhotoChangeAt =>
      photoLastChangedAt?.add(photoChangeCooldown);

  /// Returns false (and leaves the photo untouched) if the monthly cooldown
  /// hasn't elapsed yet.
  bool changePhoto(String newPath, {bool isNetwork = false}) {
    if (!canChangePhoto) return false;
    photoPath = newPath;
    photoIsNetwork = isNetwork;
    photoLastChangedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  /// Verifies [currentPassword] before setting [newPassword]. Returns false
  /// (and leaves the password untouched) if the current password is wrong.
  bool changePassword({required String currentPassword, required String newPassword}) {
    if (_password != currentPassword) return false;
    _password = newPassword;
    notifyListeners();
    return true;
  }

  bool verifyPassword(String password) => _password == password;
}