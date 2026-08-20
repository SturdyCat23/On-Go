import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/client_account_store.dart';
import '../../../../theme/app_theme.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _store = ClientAccountStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  String _formatDate(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _changePhoto() async {
    if (!_store.canChangePhoto) {
      final next = _store.nextPhotoChangeAt;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can change your photo again on ${next != null ? _formatDate(next) : 'a later date'}.')),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
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
      final ok = _store.changePhoto(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Profile photo updated' : 'You can only change your photo once every 30 days.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update photo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _store.photoPath;
    final canChange = _store.canChangePhoto;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('My Profile'),
      ),
      body: ListView(
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
                          color: AppColors.background,
                          child: const Icon(Icons.person, size: 56, color: AppColors.textGrey),
                        )
                      : (_store.photoIsNetwork
                          ? Image.network(photo, width: 120, height: 120, fit: BoxFit.cover)
                          : Image.file(File(photo), width: 120, height: 120, fit: BoxFit.cover)),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: InkWell(
                    onTap: _changePhoto,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: canChange ? AppColors.primary : AppColors.textGrey,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: AppColors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              canChange
                  ? 'You can change your photo'
                  : 'Next photo change: ${_formatDate(_store.nextPhotoChangeAt!)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
          ),
          const SizedBox(height: 28),
          const Text('ACCOUNT INFORMATION', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.person_outline, label: 'Full Name', value: _store.name.isEmpty ? '—' : _store.name),
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: _store.email.isEmpty ? '—' : _store.email),
          _InfoRow(icon: Icons.home_outlined, label: 'Address', value: _store.address.isEmpty ? '—' : _store.address),
          _InfoRow(icon: Icons.phone_outlined, label: 'Mobile Number', value: _store.phone.isEmpty ? '—' : _store.phone),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.borderGrey), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}