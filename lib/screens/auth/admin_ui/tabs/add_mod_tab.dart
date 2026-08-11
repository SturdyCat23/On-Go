import 'package:flutter/material.dart';
import '../../../../data/admin_data.dart';
import '../../../../theme/app_theme.dart';

class AddModTab extends StatefulWidget {
  const AddModTab({super.key});

  @override
  State<AddModTab> createState() => _AddModTabState();
}

class _AddModTabState extends State<AddModTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _canApprove = true;
  bool _canReject = true;
  bool _canEscalate = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    AdminStore.instance.addModerator(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: 'Moderator',
      permissions: ModeratorPermissions(
        canApprove: _canApprove,
        canReject: _canReject,
        canEscalate: _canEscalate,
      ),
    );
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _canApprove = true;
      _canReject = true;
      _canEscalate = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moderator added')));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard('ACCOUNT DETAILS', [
            _label('Full Name *'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g Vince Juno'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _label('Email Address *'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'name@gmail.com'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _label('Temporary Password *'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'At least 6 characters',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textGrey),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 4),
            const Text('The moderator signs in with this password and can change it later from Settings.',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ]),
          const SizedBox(height: 16),
          _sectionCard('PERMISSIONS', [
            _permissionRow(
              title: 'Can approve accounts',
              subtitle: 'Grants account access',
              value: _canApprove,
              onChanged: (v) => setState(() => _canApprove = v),
            ),
            Divider(height: 1, color: AppColors.borderGrey.withValues(alpha: 0.6)),
            _permissionRow(
              title: 'Can reject accounts',
              subtitle: 'Decline with reasons',
              value: _canReject,
              onChanged: (v) => setState(() => _canReject = v),
            ),
            Divider(height: 1, color: AppColors.borderGrey.withValues(alpha: 0.6)),
            _permissionRow(
              title: 'Can escalate to admin',
              subtitle: 'Flag for admin review',
              value: _canEscalate,
              onChanged: (v) => setState(() => _canEscalate = v),
            ),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              onPressed: _submit,
              child: const Text('ADD MODERATOR', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              color: value ? AppColors.primary : AppColors.borderGrey,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.6))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      );
}