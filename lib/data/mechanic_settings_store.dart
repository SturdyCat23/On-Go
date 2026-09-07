import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The mechanic's own preferences, persisted across restarts.
///
/// Same singleton-[ChangeNotifier] shape as `ThemeController`: screens read
/// `MechanicSettingsStore.instance` and listen to it when they need to
/// rebuild. Loaded once before the first frame — see `main()`.
class MechanicSettingsStore extends ChangeNotifier {
  MechanicSettingsStore._internal();
  static final MechanicSettingsStore instance = MechanicSettingsStore._internal();

  static const String _emergencyPulseKey = 'mechanic_emergency_pulse';

  bool _emergencyPulseEnabled = true;

  /// Whether the Emergency filter button may pulse when unviewed emergency
  /// jobs are waiting. On by default; turning it off stops the pulse
  /// completely, no matter how many emergencies are open.
  bool get emergencyPulseEnabled => _emergencyPulseEnabled;

  /// Reads the saved preferences. Safe to call before `runApp`; a storage
  /// failure just leaves the defaults in place rather than blocking startup.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_emergencyPulseKey);
      if (saved != null && saved != _emergencyPulseEnabled) {
        _emergencyPulseEnabled = saved;
        notifyListeners();
      }
    } catch (_) {
      // No stored preference available — keep the defaults.
    }
  }

  Future<void> setEmergencyPulseEnabled(bool value) async {
    if (value == _emergencyPulseEnabled) return;
    _emergencyPulseEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_emergencyPulseKey, value);
    } catch (_) {
      // The choice still applies for this session even if it can't be saved.
    }
  }
}
