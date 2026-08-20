import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PasswordStrength { empty, weak, fair, good, strong }

PasswordStrength evaluatePasswordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.empty;

  int score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]/\\+=~`]').hasMatch(password)) score++;

  if (password.length < 6) return PasswordStrength.weak;
  if (score <= 1) return PasswordStrength.weak;
  if (score == 2) return PasswordStrength.fair;
  if (score == 3 || score == 4) return PasswordStrength.good;
  return PasswordStrength.strong;
}

extension PasswordStrengthDisplay on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.empty:
        return AppColors.borderGrey;
      case PasswordStrength.weak:
        return AppColors.primary;
      case PasswordStrength.fair:
        return AppColors.yellow;
      case PasswordStrength.good:
        return const Color(0xFF4CAF50);
      case PasswordStrength.strong:
        return AppColors.green;
    }
  }

  /// 0.0–1.0, for a progress bar.
  double get fraction {
    switch (this) {
      case PasswordStrength.empty:
        return 0;
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}

/// A labelled strength bar — drop under any password field.
class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  const PasswordStrengthMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = evaluatePasswordStrength(password);
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength.fraction,
              minHeight: 5,
              backgroundColor: AppColors.borderGrey.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation(strength.color),
            ),
          ),
          const SizedBox(height: 4),
          Text('Password strength: ${strength.label}',
              style: TextStyle(fontSize: 11, color: strength.color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}