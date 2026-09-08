import 'package:flutter/material.dart';

import '../../data/password_reset_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/password_strength.dart';

/// Forgot Password, in three stages on one screen: name the account, enter the
/// one-time code, then set the new password. One screen keeps the reset
/// request — which lives in [PasswordResetStore] — tied to a single route, so
/// leaving at any point abandons it cleanly.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Stage { email, code, newPassword }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _reset = PasswordResetStore.instance;

  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _Stage _stage = _Stage.email;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    // Abandoning the screen abandons the reset — a code must not outlive the
    // flow that issued it.
    _reset.cancel();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submitEmail() {
    final result = _reset.requestReset(_emailCtrl.text);
    setState(() {
      switch (result) {
        case ResetRequestResult.codeSent:
          _error = null;
          _stage = _Stage.code;
        case ResetRequestResult.missingEmail:
          _error = 'Enter the email address on your account.';
        case ResetRequestResult.unknownAccount:
          _error = 'No account was found with that email address.';
      }
    });
  }

  void _submitCode() {
    final result = _reset.verifyCode(_codeCtrl.text);
    setState(() {
      switch (result) {
        case ResetVerifyResult.verified:
          _error = null;
          _stage = _Stage.newPassword;
        case ResetVerifyResult.incorrectCode:
          _error = 'That code is not correct. '
              '${_reset.attemptsRemaining} attempt${_reset.attemptsRemaining == 1 ? '' : 's'} left.';
        case ResetVerifyResult.expired:
          _error = 'That code has expired. Request a new one.';
          _backToEmail();
        case ResetVerifyResult.tooManyAttempts:
          _error = 'Too many incorrect attempts. Request a new code.';
          _backToEmail();
        case ResetVerifyResult.noActiveRequest:
          _error = 'This reset is no longer active. Start again.';
          _backToEmail();
      }
    });
  }

  void _submitNewPassword() {
    final result = _reset.completeReset(
      password: _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );
    if (result == ResetCompleteResult.success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated. Sign in with your new password.'),
          duration: AppDurations.snackBar,
        ),
      );
      return;
    }
    setState(() {
      switch (result) {
        case ResetCompleteResult.tooShort:
          _error = 'Password must be at least ${PasswordResetStore.minPasswordLength} characters';
        case ResetCompleteResult.tooWeak:
          _error = 'Please choose a stronger password.';
        case ResetCompleteResult.mismatch:
          _error = 'Passwords do not match.';
        case ResetCompleteResult.expired:
          _error = 'This reset expired before it was finished. Start again.';
          _backToEmail();
        case ResetCompleteResult.notVerified:
        case ResetCompleteResult.accountGone:
          _error = 'This reset is no longer valid. Start again.';
          _backToEmail();
        case ResetCompleteResult.success:
          break;
      }
    });
  }

  void _backToEmail() {
    _stage = _Stage.email;
    _codeCtrl.clear();
    _passwordCtrl.clear();
    _confirmCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AuthBackground(
        child: SafeArea(
          child: AuthBottomCard(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  switch (_stage) {
                    _Stage.email => 'Reset your password',
                    _Stage.code => 'Enter your code',
                    _Stage.newPassword => 'Create a new password',
                  },
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textdark),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  switch (_stage) {
                    _Stage.email => 'We\'ll send a one-time code to the email on your account.',
                    _Stage.code =>
                      'Enter the 6-digit code sent to ${_reset.email ?? 'your email'}. It expires in ${PasswordResetStore.codeLifetime.inMinutes} minutes.',
                    _Stage.newPassword => 'Choose a password you haven\'t used before.',
                  },
                  style: TextStyle(fontSize: 13, color: AppColors.textdark.withValues(alpha: 0.55)),
                ),
              ),
              const SizedBox(height: 20),
              ..._stageFields(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_error!, style: TextStyle(fontSize: 12, color: AppColors.error)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              AuthWhiteButton(
                label: switch (_stage) {
                  _Stage.email => 'Send Code',
                  _Stage.code => 'Verify Code',
                  _Stage.newPassword => 'Save New Password',
                },
                onPressed: switch (_stage) {
                  _Stage.email => _submitEmail,
                  _Stage.code => _submitCode,
                  _Stage.newPassword => _submitNewPassword,
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  child: Text('Back to Sign In',
                      style: TextStyle(fontSize: 13, color: AppColors.textdark)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _stageFields() {
    switch (_stage) {
      case _Stage.email:
        return [
          AuthTextField(
            hint: 'Email address',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
        ];

      case _Stage.code:
        return [
          AuthTextField(
            hint: '6-digit code',
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          // Stands in for the email this app cannot send yet. Delete this
          // block the day a mail service is wired up — nothing else in the
          // flow reads the code.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No email service is connected yet, so your code is: '
                    '${_reset.visibleCode ?? '—'}',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ];

      case _Stage.newPassword:
        return [
          AuthTextField(
            hint: 'New password',
            controller: _passwordCtrl,
            obscure: _obscurePassword,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textdark.withValues(alpha: 0.55),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          PasswordStrengthMeter(password: _passwordCtrl.text),
          const SizedBox(height: 16),
          AuthTextField(
            hint: 'Confirm new password',
            controller: _confirmCtrl,
            obscure: _obscureConfirm,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textdark.withValues(alpha: 0.55),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          PasswordMatchIndicator(
            password: _passwordCtrl.text,
            confirmPassword: _confirmCtrl.text,
          ),
        ];
    }
  }
}
