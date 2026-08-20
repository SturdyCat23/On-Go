import 'package:flutter/material.dart';
import '../../../../data/client_account_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/password_strength.dart';

class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  final _store = ClientAccountStore.instance;
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);

    if (_currentCtrl.text.isEmpty || _newCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    final strength = evaluatePasswordStrength(_newCtrl.text);
    if (strength == PasswordStrength.weak) {
      setState(() => _error = 'Please choose a stronger password.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }

    final ok = _store.changePassword(currentPassword: _currentCtrl.text, newPassword: _newCtrl.text);
    if (!ok) {
      setState(() => _error = 'Current password is incorrect.');
      return;
    }

    _currentCtrl.clear();
    _newCtrl.clear();
    _confirmCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
  }

  @override
  Widget build(BuildContext context) {
    final isGoogleAccount = _store.photoIsNetwork && !_store.verifyPassword('');
    // A Google sign-up leaves the local password empty — that's the signal
    // we use to detect it, since this app has no real auth backend yet.
    final hasLocalPassword = !_store.verifyPassword('');

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('SECURITY', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (!hasLocalPassword) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.textGrey),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your account uses Google Sign-In, so there\'s no On Go password to change here. Manage your password from your Google account instead.',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            _PasswordField(
              label: 'Current Password',
              controller: _currentCtrl,
              obscure: _obscureCurrent,
              onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 14),
            _PasswordField(
              label: 'New Password',
              controller: _newCtrl,
              obscure: _obscureNew,
              onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
              onChanged: (_) => setState(() {}),
            ),
            PasswordStrengthMeter(password: _newCtrl.text),
            const SizedBox(height: 14),
            _PasswordField(
              label: 'Confirm New Password',
              controller: _confirmCtrl,
              obscure: _obscureConfirm,
              onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Update Password', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final ValueChanged<String>? onChanged;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textGrey),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}