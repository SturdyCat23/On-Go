import 'package:flutter/foundation.dart';
import 'moderator_data.dart';

enum MechanicAccountMode { none, demo, registered }

/// Tracks the mechanic's account this session — mirrors ClientAccountStore's
/// demo/registered pattern, plus password and photo, so mechanic Settings
/// and Profile can offer the same change-password / change-photo flows the
/// client side already has.
///
/// [canPerformJobActions] is the single source of truth for whether job
/// actions are allowed — QuoteNotificationStore checks THIS getter directly.
class MechanicAccountStore extends ChangeNotifier {
  MechanicAccountStore._internal() {
    ModerationStore.instance.addListener(notifyListeners);
  }
  static final MechanicAccountStore instance = MechanicAccountStore._internal();

  static const Duration photoChangeCooldown = Duration(days: 30);

  MechanicAccountMode mode = MechanicAccountMode.none;

  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String _password = '';

  String? photoPath;
  bool photoIsNetwork = false;
  DateTime? photoLastChangedAt;

  /// Links this account to its approval request in ModerationStore.
  String? _accountRequestId;

  String get name => '$firstName $lastName'.trim();

  bool get isDemo => mode == MechanicAccountMode.demo;
  bool get isRegistered => mode == MechanicAccountMode.registered;
  bool get hasAccount => isRegistered;

  AccountRequest? get accountRequest =>
      _accountRequestId == null ? null : ModerationStore.instance.findRequest(_accountRequestId!);

  ApprovalStatus? get status => accountRequest?.status;

  bool get canPerformJobActions {
    if (isDemo) return true;
    return status == ApprovalStatus.approved;
  }

  void enterDemoMode() {
    mode = MechanicAccountMode.demo;
    firstName = 'Demo';
    lastName = 'Mechanic';
    email = '';
    phone = '';
    _password = '';
    photoPath = null;
    photoIsNetwork = false;
    photoLastChangedAt = null;
    _accountRequestId = null;
    notifyListeners();
  }

  /// Registers a mechanic account and immediately files it with
  /// ModerationStore as a Pending approval request.
  void registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String password = '',
    String? photoPath,
    bool photoIsNetwork = false,
    List<String> documents = const [],
  }) {
    mode = MechanicAccountMode.registered;
    this.firstName = firstName;
    this.lastName = lastName;
    this.email = email;
    this.phone = phone;
    _password = password;
    this.photoPath = photoPath;
    this.photoIsNetwork = photoIsNetwork;
    photoLastChangedAt = photoPath != null ? DateTime.now() : null;

    _accountRequestId = ModerationStore.instance.submitRequest(
      name: '$firstName $lastName'.trim(),
      email: email,
      role: AccountRole.mechanic,
      documents: documents,
    );
    notifyListeners();
  }

  bool get canChangePhoto {
    if (photoLastChangedAt == null) return true;
    return DateTime.now().difference(photoLastChangedAt!) >= photoChangeCooldown;
  }

  DateTime? get nextPhotoChangeAt => photoLastChangedAt?.add(photoChangeCooldown);

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

  void clear() {
    mode = MechanicAccountMode.none;
    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    _password = '';
    photoPath = null;
    photoIsNetwork = false;
    photoLastChangedAt = null;
    _accountRequestId = null;
    notifyListeners();
  }
}