import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';

/// Lets the admin put a photo behind the Sign In and Welcome screens in place
/// of their background color, and take it away again.
///
/// Photos come from the gallery only — there is no camera option. Picking one
/// stages it as a preview and changes nothing; the background is written only
/// when Confirm is pressed.
///
/// Everything applied is held by [AuthBackgroundController]; both screens
/// listen to it, so a confirmed photo or a removal shows up there without any
/// further wiring.
class ChangeBackgroundScreen extends StatefulWidget {
  const ChangeBackgroundScreen({super.key});

  @override
  State<ChangeBackgroundScreen> createState() => _ChangeBackgroundScreenState();
}

class _ChangeBackgroundScreenState extends State<ChangeBackgroundScreen> {
  final _controller = AuthBackgroundController.instance;
  bool _busy = false;

  /// The photo picked from the gallery but not confirmed yet. Nothing outside
  /// this screen sees it until [_confirmPhoto] hands it to the controller.
  String? _pendingPath;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: AppDurations.snackBar),
    );
  }

  /// Picks a photo from the gallery and stages it for confirmation. The
  /// background is left exactly as it is until Confirm.
  Future<void> _choosePhoto() async {
    setState(() => _busy = true);
    try {
      // Gallery only — the camera is deliberately not offered here. Sized for
      // a full-screen backdrop, at the same quality the rest of the app
      // uploads photos with.
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      if (!mounted) return;
      setState(() => _pendingPath = file.path);
    } catch (e) {
      _notify('Could not open the gallery: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Applies the staged photo — the only path that touches the background.
  Future<void> _confirmPhoto() async {
    final pending = _pendingPath;
    if (pending == null) return;

    setState(() => _busy = true);
    final ok = await _controller.setPhoto(pending);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _pendingPath = null;
    });
    _notify(ok ? 'Background photo applied' : 'Could not save that photo. Please try another one.');
  }

  /// Drops the staged photo. Nothing was applied, so there is nothing to undo.
  void _cancelPending() => setState(() => _pendingPath = null);

  Future<void> _removePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove background photo?'),
        content: const Text(
          'The Sign In and Welcome screens will go back to the default background color.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    await _controller.removePhoto();
    if (mounted) setState(() => _busy = false);
    _notify('Background photo removed');
  }

  @override
  Widget build(BuildContext context) {
    final photo = _controller.photoPath;
    final pending = _pendingPath;
    // The preview always shows what Confirm would leave in place.
    final shown = pending ?? photo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textlight,
        title: const Text('Change Background'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'SIGN IN & WELCOME SCREENS',
            style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            "Choose a photo from your gallery to use as the background of the Sign In "
            "and Welcome screens. It is applied only after you press Confirm. Remove it "
            "and both screens go back to the theme's background color.",
            style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 16),
          _BackgroundPreview(photoPath: shown),
          const SizedBox(height: 8),
          Center(
            child: Text(
              pending != null
                  ? 'Preview only — press Confirm to apply'
                  : (photo == null ? 'Using the default background color' : 'Using the uploaded photo'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: pending != null ? FontWeight.w600 : FontWeight.normal,
                color: pending != null ? AppColors.warning : AppColors.textdark.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _busy ? null : _choosePhoto,
            icon: Icon(Icons.photo_library_outlined, color: AppColors.textlight),
            label: Text(
              pending != null
                  ? 'Choose a Different Photo'
                  : (photo == null ? 'Choose from Gallery' : 'Replace from Gallery'),
            ),
          ),
          const SizedBox(height: 12),
          // While a photo is staged the only two moves are Confirm and Cancel;
          // Remove acts on the applied background, so it comes back once the
          // selection is resolved either way.
          if (pending != null) ...[
            ElevatedButton.icon(
              onPressed: _busy ? null : _confirmPhoto,
              icon: Icon(Icons.check, color: AppColors.textlight),
              label: const Text('Confirm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.textlight,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _cancelPending,
              icon: Icon(Icons.close, color: AppColors.textdark),
              label: Text('Cancel', style: TextStyle(color: AppColors.textdark)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: AppColors.textmedium.withValues(alpha: 0.5)),
              ),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: (_busy || photo == null) ? null : _removePhoto,
              icon: Icon(Icons.delete_outline, color: photo == null ? AppColors.textmedium : AppColors.error),
              label: Text(
                'Remove Photo',
                style: TextStyle(color: photo == null ? AppColors.textmedium : AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(
                  color: photo == null
                      ? AppColors.textmedium.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shows what the two screens currently sit on — the uploaded photo, or the
/// background color it replaced — with a miniature of the card that overlaps it.
class _BackgroundPreview extends StatelessWidget {
  final String? photoPath;

  const _BackgroundPreview({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 160,
        height: 280,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textmedium.withValues(alpha: 0.3)),
          image: photoPath == null
              ? null
              : DecorationImage(image: FileImage(File(photoPath!)), fit: BoxFit.cover),
        ),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: double.infinity,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Change Background" row on a Settings screen.
///
/// The Admin shell uses it as-is. The Moderator shell passes [enabled] from
/// `ModeratorPermissions.canChangeBackground`; when that is off the row is
/// inert and says so, and the screen behind it can't be opened.
class ChangeBackgroundSettingsTile extends StatelessWidget {
  /// Whether this role may open the screen. Admins are always allowed.
  final bool enabled;

  const ChangeBackgroundSettingsTile({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.textdark : AppColors.textdark.withValues(alpha: 0.38);

    return AnimatedBuilder(
      animation: AuthBackgroundController.instance,
      builder: (context, _) => ListTile(
        enabled: enabled,
        contentPadding: EdgeInsets.zero,
        leading: Icon(enabled ? Icons.image_outlined : Icons.lock_outline, color: color),
        title: Text('Change Background', style: TextStyle(fontSize: 15, color: color)),
        subtitle: Text(
          enabled
              ? (AuthBackgroundController.instance.hasPhoto ? 'Uploaded photo' : 'Default background color')
              : 'Your admin has not given you this permission',
          style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
        ),
        trailing: enabled ? Icon(Icons.chevron_right, color: AppColors.textdark.withValues(alpha: 0.55)) : null,
        onTap: enabled
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangeBackgroundScreen()),
                )
            : null,
      ),
    );
  }
}
