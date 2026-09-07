import 'package:flutter/foundation.dart';
import 'mechanic_notification_store.dart';
import 'moderator_data.dart';

enum MechanicAccountMode { none, demo, registered }

/// Tracks the mechanic's account this session — mirrors ClientAccountStore's
/// demo/registered pattern, plus password, photo, and address, so mechanic
/// Settings and Profile can offer the same flows the client side has.
class MechanicAccountStore extends ChangeNotifier {
  MechanicAccountStore._internal() {
    ModerationStore.instance.addListener(_onModerationChange);
  }
  static final MechanicAccountStore instance = MechanicAccountStore._internal();

  /// The approval status this store last saw, so a moderator's decision can be
  /// spotted as a *transition* rather than re-fired on every moderation change.
  ApprovalStatus? _lastSeenStatus;

  /// Watches this mechanic's own account request. Crossing into approved is
  /// what puts "Account approved" on their bell; every other moderation change
  /// just repaints, as before.
  void _onModerationChange() {
    final current = status;
    if (current != _lastSeenStatus) {
      if (current == ApprovalStatus.approved) {
        MechanicNotificationStore.instance.add(
          kind: MechanicNotificationKind.accountApproved,
          mechanicName: name,
          clientName: '',
          detail: accountRequest?.reviewerName == null
              ? 'Reviewed by a moderator'
              : 'Reviewed by ${accountRequest!.reviewerName}',
        );
      }
      _lastSeenStatus = current;
    }
    notifyListeners();
  }

  static const Duration photoChangeCooldown = Duration(days: 30);

  MechanicAccountMode mode = MechanicAccountMode.none;

  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String address = '';
  String _password = '';

  String? photoPath;
  bool photoIsNetwork = false;
  DateTime? photoLastChangedAt;

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
    address = '';
    _password = '';
    photoPath = null;
    photoIsNetwork = false;
    photoLastChangedAt = null;
    _accountRequestId = null;
    _lastSeenStatus = null;
    notifyListeners();
  }

  void registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String address = '',
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
    this.address = address;
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
    // Start from this request's own status, so the moderator's decision on it
    // reads as a transition rather than inheriting a previous account's state.
    _lastSeenStatus = status;
    notifyListeners();
  }

  bool get canChangePhoto {
    if (photoLastChangedAt == null) return true;
    return DateTime.now().difference(photoLastChangedAt!) >= photoChangeCooldown;
  }

  DateTime? get nextPhotoChangeAt => photoLastChangedAt?.add(photoChangeCooldown);

  bool changePhoto(String newPath, {bool isNetwork = false}) {
    if (!canChangePhoto) return false;
    photoPath = newPath;
    photoIsNetwork = isNetwork;
    photoLastChangedAt = DateTime.now();
    notifyListeners();
    return true;
  }

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
    address = '';
    _password = '';
    photoPath = null;
    photoIsNetwork = false;
    photoLastChangedAt = null;
    _accountRequestId = null;
    _lastSeenStatus = null;
    notifyListeners();
  }
}