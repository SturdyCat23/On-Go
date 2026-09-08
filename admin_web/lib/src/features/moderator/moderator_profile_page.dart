import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/console_shell.dart';
import '../../backend/console_backend.dart';
import '../../session/console_session.dart';
import '../../theme/console_theme.dart';
import '../../widgets/console_formats.dart';
import '../../widgets/console_widgets.dart';

/// The moderator's own account.
///
/// Name and photo belong to them. Email, role, join date and permissions were
/// set by the admin who created the account, so they are shown but not
/// editable — which is the point of showing them at all: a moderator who
/// cannot escalate should be able to see that, not discover it from a missing
/// button.
class ModeratorProfilePage extends StatelessWidget {
  const ModeratorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsoleShell(
      child: AnimatedBuilder(
        animation: ConsoleSession.instance,
        builder: (context, _) {
          final session = ConsoleSession.instance;
          final moderator = session.moderator;

          if (moderator == null) {
            return const ConsoleEmptyState(
              icon: Icons.person_off_outlined,
              title: 'No moderator account',
              message:
                  'You are signed in as an admin. This page shows a moderator '
                  'their own account and permissions.',
            );
          }

          return ListView(
            padding: consolePagePadding(context),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(moderator: moderator),
                    SizedBox(height: context.layout.sectionSpacing),
                    ConsoleCard(
                      title: 'Account details',
                      subtitle: 'Managed by the admin who added you',
                      child: Column(
                        children: [
                          ConsoleField(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: moderator.email.isEmpty ? '—' : moderator.email,
                          ),
                          ConsoleField(
                            icon: Icons.shield_outlined,
                            label: 'Role',
                            value: moderator.role,
                          ),
                          ConsoleField(
                            icon: Icons.event_outlined,
                            label: 'Moderator since',
                            value: formatConsoleDate(moderator.addedAt),
                          ),
                          ConsoleField(
                            icon: Icons.task_alt,
                            label: 'Requests handled',
                            value: '${moderator.actionsHandled}',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.layout.sectionSpacing),
                    ConsoleCard(
                      title: context.layout.isPhone ? 'YOUR PERMISSION' : 'Your permissions',
                      subtitle: context.layout.isPhone ? null : 'Only an admin can change these',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConsolePermissionRow(
                            label: 'Approve accounts',
                            granted: moderator.permissions.canApprove,
                          ),
                          ConsolePermissionRow(
                            label: 'Reject accounts',
                            granted: moderator.permissions.canReject,
                          ),
                          ConsolePermissionRow(
                            label: 'Escalate to admin',
                            granted: moderator.permissions.canEscalate,
                          ),
                          ConsolePermissionRow(
                            label: "Change the app's background photo",
                            granted: moderator.permissions.canChangeBackground,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({required this.moderator});

  final ModeratorAccount moderator;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _busy = false;

  Future<void> _changePhoto() async {
    final directory = ConsoleBackend.instance.localModerators;
    if (directory == null) {
      showConsoleMessage(
        context,
        'Profile photo uploads need the API.',
        isError: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final bytes = result?.files.singleOrNull?.bytes;
      if (bytes == null) return;

      await directory.setProfilePhoto(widget.moderator.id, bytes);
      if (mounted) showConsoleMessage(context, 'Profile photo updated');
    } on ApiException catch (error) {
      if (mounted) showConsoleMessage(context, error.message, isError: true);
    } catch (error) {
      if (mounted) {
        showConsoleMessage(context, 'Could not read that file: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: widget.moderator.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: consoleDialogInsets(ctx),
        title: const Text('Edit your name'),
        content: SizedBox(
          width: ConsoleLayout.of(ctx).dialogWidth(380),
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Full name'),
            onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: ConsoleColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty || name == widget.moderator.name) return;
    if (!mounted) return;

    try {
      await ConsoleBackend.instance.moderators
          .updateProfile(widget.moderator.id, name: name);
      if (mounted) showConsoleMessage(context, 'Name updated');
    } on ApiException catch (error) {
      if (mounted) showConsoleMessage(context, error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bytes = ConsoleBackend.instance.localModerators
        ?.photoBytesFor(widget.moderator.id);

    final layout = context.layout;

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        ConsoleAvatar(
          initials: widget.moderator.initials,
          radius: layout.profileAvatarRadius,
          image: bytes == null ? null : MemoryImage(bytes),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: ConsoleColors.brand,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _busy ? null : _changePhoto,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 15,
                  color: ConsoleColors.textInverse,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final details = Column(
      crossAxisAlignment:
          layout.isPhone ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.moderator.name,
                overflow: TextOverflow.ellipsis,
                textAlign: layout.isPhone ? TextAlign.center : TextAlign.start,
                style: text.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Edit your name',
              onPressed: _editName,
              icon: const Icon(Icons.edit_outlined, size: 17),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          widget.moderator.email,
          textAlign: layout.isPhone ? TextAlign.center : TextAlign.start,
          style: text.bodyMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            ConsoleBadge(
              label: widget.moderator.role,
              color: ConsoleColors.info,
            ),
            ConsoleBadge(
              label: widget.moderator.status.label,
              color: widget.moderator.isActive
                  ? ConsoleColors.success
                  : ConsoleColors.textMuted,
            ),
          ],
        ),
      ],
    );

    // A phone stacks the avatar over the details and centres them; there is no
    // room for a 44-point avatar, a name and an edit button on one line.
    if (layout.isPhone) {
      return ConsoleCard(
        boxedOnPhone: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: avatar),
            const SizedBox(height: 18),
            details,
          ],
        ),
      );
    }

    return ConsoleCard(
      boxedOnPhone: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar,
          const SizedBox(width: 26),
          Expanded(child: details),
        ],
      ),
    );
  }
}
