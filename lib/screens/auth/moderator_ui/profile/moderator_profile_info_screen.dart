import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/admin_data.dart';
import '../../../../data/session_store.dart';
import '../../../../theme/app_theme.dart';

/// The moderator's own profile, reached from the drawer — the editable
/// counterpart to the read-only Profile tab.
///
/// Name and photo belong to the moderator; email, role and the join date are
/// set by the admin who created the account, so they are shown but not
/// editable here.
class ModeratorProfileInfoScreen extends StatefulWidget {
  const ModeratorProfileInfoScreen({super.key});

  @override
  State<ModeratorProfileInfoScreen> createState() => _ModeratorProfileInfoScreenState();
}

class _ModeratorProfileInfoScreenState extends State<ModeratorProfileInfoScreen> {
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

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: AppDurations.snackBar),
    );
  }

  Future<void> _changePhoto() async {
    final mod = _session.currentModerator;
    if (mod == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (file == null) return;
      AdminStore.instance.updateModeratorProfile(mod.id, photoPath: file.path);
      _notify('Profile photo updated');
    } catch (e) {
      _notify('Could not update photo: $e');
    }
  }

  Future<void> _editName() async {
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
      _notify('Profile updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mod = _session.currentModerator;
    final photo = mod?.photoPath;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textlight,
        title: const Text('My Profile'),
      ),
      body: mod == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No moderator account yet. Ask an admin to add you as a moderator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textdark.withValues(alpha: 0.55)),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(70),
                        child: photo == null
                            ? Container(
                                width: 120,
                                height: 120,
                                color: AppColors.surface,
                                child: Icon(Icons.person, size: 56, color: AppColors.textdark.withValues(alpha: 0.55)),
                              )
                            : Image.file(File(photo), width: 120, height: 120, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: InkWell(
                          onTap: _changePhoto,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 2),
                            ),
                            child: Icon(Icons.camera_alt, color: AppColors.textlight, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap the camera to change your photo',
                    style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55)),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'PERSONAL INFORMATION',
                  style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  value: mod.name.isEmpty ? '—' : mod.name,
                  onEdit: _editName,
                ),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: mod.email.isEmpty ? '—' : mod.email,
                ),
                _InfoRow(icon: Icons.shield_outlined, label: 'Role', value: mod.role),
                _InfoRow(icon: Icons.event_outlined, label: 'Moderator Since', value: _formatDate(mod.addedDate)),
                const SizedBox(height: 4),
                Text(
                  'Your email and role are managed by the admin who added you.',
                  style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55)),
                ),
              ],
            ),
    );
  }
}

/// One field of the profile. Rows the moderator owns get a pencil; the
/// admin-owned ones are plain read-outs.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textdark.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textdark.withValues(alpha: 0.55)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              tooltip: 'Edit $label',
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
