import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../data/session_store.dart';
import '../../../../theme/app_theme.dart';

/// The Profile tab on the moderator bottom bar, in the slot Settings used to
/// occupy. It is a read-only summary — photo, name, moderator tag and
/// permissions. Editing lives on the drawer's Profile screen, and Appearance,
/// Notifications and Security moved to the drawer's Settings screen.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
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

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mod = _session.currentModerator;
    final perms = _session.currentPermissions;
    final photo = mod?.photoPath;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.textdark.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.textmedium.withValues(alpha: 0.55), width: 2),
                    ),
                    child: ClipOval(
                      child: photo == null
                          ? Container(
                              color: AppColors.background,
                              child: Icon(Icons.person_outline, size: 48, color: AppColors.textdark.withValues(alpha: 0.55)),
                            )
                          : Image.file(File(photo), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mod?.name ?? 'No account',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          mod?.email ?? '—',
                          style: TextStyle(fontSize: 16, color: AppColors.textdark.withValues(alpha: 0.65)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            mod?.role ?? 'Moderator',
                            style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'YOUR PERMISSION',
          style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _permissionRow('Approve accounts', perms.canApprove),
        _permissionRow('Reject accounts', perms.canReject),
        _permissionRow('Escalate to admin', perms.canEscalate),
        _permissionRow('Change background', perms.canChangeBackground),
      ],
    );
  }

  Widget _permissionRow(String label, bool granted) {
    final color = granted ? AppColors.success : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(granted ? Icons.check : Icons.close, size: 14, color: AppColors.textlight),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 15, color: AppColors.textdark)),
        ],
      ),
    );
  }
}
