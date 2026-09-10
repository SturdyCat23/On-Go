import 'package:flutter/foundation.dart';

/// How to reach a mechanic: what their profile shows under Details.
@immutable
class MechanicContact {
  final String phone;
  final String email;

  const MechanicContact({this.phone = '', this.email = ''});

  bool get isEmpty => phone.isEmpty && email.isEmpty;
}

/// Contact details for every mechanic, keyed by name.
///
/// `MechanicAccountStore` holds the account of whoever is signed in, which is
/// all the mechanic's own screens need. A profile opened by a client — or by
/// another mechanic — has only a name to go on, exactly like
/// `MechanicCredentialStore`, so contact details are indexed the same way and
/// are reachable from that name alone.
///
/// Written at registration, and by demo mode, so the two profile screens read
/// one source rather than one reading the account and the other guessing.
class MechanicContactStore extends ChangeNotifier {
  MechanicContactStore._internal();
  static final MechanicContactStore instance = MechanicContactStore._internal();

  final Map<String, MechanicContact> _byName = {};

  /// What to show for [mechanicName]; empty when nothing is on file, which is
  /// the case for a mechanic who only exists as a name on an old job.
  MechanicContact contactFor(String mechanicName) =>
      _byName[mechanicName] ?? const MechanicContact();

  bool hasContact(String mechanicName) => !contactFor(mechanicName).isEmpty;

  /// Records how to reach [mechanicName]. Called when an account is created
  /// and whenever those details change, so the profile never shows a number
  /// the mechanic has since replaced.
  void record({
    required String mechanicName,
    required String phone,
    required String email,
  }) {
    if (mechanicName.isEmpty) return;

    final next = MechanicContact(phone: phone.trim(), email: email.trim());
    final current = _byName[mechanicName];
    if (current != null && current.phone == next.phone && current.email == next.email) {
      return;
    }

    _byName[mechanicName] = next;
    notifyListeners();
  }

  /// Test/demo hook — drops the index.
  void clear() {
    _byName.clear();
    notifyListeners();
  }
}
