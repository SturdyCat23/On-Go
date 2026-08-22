import 'package:flutter/material.dart';
import '../../../../data/admin_data.dart';
import '../../../../data/session_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/password_strength.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _newSubmitted = true;
  final _session = SessionStore.instance;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onChange);
  }

  @override
  void dispose() {
    _session.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _editProfile() async {
    final mod = _session.currentModerator;
    if (mod == null) return;
    final controller = TextEditingController(text: mod.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != mod.name) {
      AdminStore.instance.updateModeratorProfile(mod.id, name: newName);
    }
  }

  Future<void> _changePassword() async {
    final mod = _session.currentModerator;
    if (mod == null) return;

    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              PasswordStrengthMeter(password: newController.text),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                if (newController.text.length < 6) {
                  setDialogState(() => errorText = 'New password must be at least 6 characters');
                  return;
                }
                if (newController.text != confirmController.text) {
                  setDialogState(() => errorText = 'Passwords do not match');
                  return;
                }
                final ok = AdminStore.instance.changeModeratorPassword(
                  mod.id,
                  oldPassword: oldController.text,
                  newPassword: newController.text,
                );
                if (!ok) {
                  setDialogState(() => errorText = 'Current password is incorrect');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mod = _session.currentModerator;
    final perms = _session.currentPermissions;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.borderGrey), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.textDark, width: 1.3)),
                    child: const Icon(Icons.person_outline, size: 34, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mod?.name ?? 'No account', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(mod?.email ?? 'Ask an admin to add you as a moderator',
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Text(mod?.role ?? 'Moderator',
                              style: const TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: mod == null ? null : _editProfile,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.borderGrey),
                  ),
                  child: const Text('Edit Profile', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('YOUR PERMISSION', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _permissionRow('Approve accounts', perms.canApprove),
        _permissionRow('Reject accounts', perms.canReject),
        _permissionRow('Escalate to admin', perms.canEscalate),
        const SizedBox(height: 20),
        const Text('NOTIFICATIONS', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New pending approvals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('when accounts are submitted', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            Switch(
              value: _newSubmitted,
              onChanged: (v) => setState(() => _newSubmitted = v),
              activeTrackColor: AppColors.blue,
              activeThumbColor: AppColors.white,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        const Text('SECURITY', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Change Password', style: TextStyle(fontSize: 15)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
          onTap: mod == null ? null : _changePassword,
        ),
      ],
    );
  }

  Widget _permissionRow(String label, bool granted) {
    final color = granted ? AppColors.green : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(granted ? Icons.check : Icons.close, size: 14, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textDark)),
        ],
      ),
    );
  }
}