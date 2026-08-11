import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class LocalData {
  static const _historyKey = 'mechanic_history';
  static const _balanceKey = 'mechanic_balance';

  static Future<List<Map<String, dynamic>>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveHistory(List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, json.encode(history));
  }

  static Future<int> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_balanceKey) ?? 0;
  }

  static Future<void> saveBalance(int balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, balance);
  }

  static Future<void> addCompletedJobFromQr(String data) async {
    final history = await loadHistory();
    final rnd = Random();
    final earned = 100 + rnd.nextInt(401); // 100..500
    final job = {
      'date': DateTime.now().toIso8601String(),
      'issue': 'Scanned Job',
      'description': data,
      'earned': earned,
      'rating': 0,
      'completed': true,
      'clientActive': true,
    };
    history.insert(0, job);
    await saveHistory(history);

    final balance = await loadBalance();
    await saveBalance(balance + earned);
  }
}
