import 'package:flutter/foundation.dart';
import 'moderator_data.dart';

enum MechanicAccountMode { none, demo, registered }

/// Tracks the mechanic's account this session — mirrors ClientAccountStore.
/// Demo mode needs no approval at all (per spec); a registered account is
/// linked to an AccountRequest in ModerationStore and stays gated until a
/// moderator approves it there.
///
/// [canPerformJobActions] is the single source of truth for whether job
/// actions are allowed — and critically, QuoteNotificationStore checks THIS
/// getter directly inside mechanicSendQuote/mechanicAcceptEmergency, not
/// just the UI. A disabled button is a courtesy; the store call itself
/// refuses to run for an unapproved account.
class MechanicAccountStore extends ChangeNotifier {
  MechanicAccountStore._internal() {
    // Approval can change from the Moderator UI while this mechanic is
    // already inside the app — forward those changes so anything listening
    // to this store (banners, gated buttons) updates live, with no need to
    // re-login or re-register.
    ModerationStore.instance.addListener(notifyListeners);
  }
  static final MechanicAccountStore instance = MechanicAccountStore._internal();

  MechanicAccountMode mode = MechanicAccountMode.none;

  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';

  /// Links this account to its approval request in ModerationStore.
  String? _accountRequestId;

  String get name => '$firstName $lastName'.trim();

  bool get isDemo => mode == MechanicAccountMode.demo;
  bool get isRegistered => mode == MechanicAccountMode.registered;

  AccountRequest? get accountRequest =>
      _accountRequestId == null ? null : ModerationStore.instance.findRequest(_accountRequestId!);

  ApprovalStatus? get status => accountRequest?.status;

  /// THE gate — see class doc.
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
    _accountRequestId = null;
    notifyListeners();
  }

  /// Registers a mechanic account and immediately files it with
  /// ModerationStore as a Pending approval request — this is what makes it
  /// show up in the Moderator Queue tab automatically.
  void registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    List<String> documents = const [],
  }) {
    mode = MechanicAccountMode.registered;
    this.firstName = firstName;
    this.lastName = lastName;
    this.email = email;
    this.phone = phone;

    _accountRequestId = ModerationStore.instance.submitRequest(
      name: '$firstName $lastName'.trim(),
      email: email,
      role: AccountRole.mechanic,
      documents: documents,
    );
    notifyListeners();
  }

  void clear() {
    mode = MechanicAccountMode.none;
    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    _accountRequestId = null;
    notifyListeners();
  }
}