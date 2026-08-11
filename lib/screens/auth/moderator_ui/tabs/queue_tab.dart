import 'package:flutter/material.dart';
import '../../../../data/moderator_data.dart';
import '../../../../data/session_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/date_format.dart';

class QueueTab extends StatefulWidget {
  const QueueTab({super.key});

  @override
  State<QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<QueueTab> {
  final _store = ModerationStore.instance;
  final _session = SessionStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
    _session.addListener(_onChange);
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    _session.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _reject(AccountRequest r) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject account'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason != null) _store.reject(r.id, reason);
  }

  void _noPermission(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You don't have permission to $action")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _store.pending;
    final perms = _session.currentPermissions;

    if (pending.isEmpty) {
      return const Center(child: Text('No pending requests', style: TextStyle(color: AppColors.textGrey)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${pending.length} pending', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 8),
        ...pending.map((r) => _QueueCard(
              request: r,
              canApprove: perms.canApprove,
              canReject: perms.canReject,
              canEscalate: perms.canEscalate,
              onApprove: () => perms.canApprove ? _store.approve(r.id) : _noPermission('approve accounts'),
              onReject: () => perms.canReject ? _reject(r) : _noPermission('reject accounts'),
              onEscalate: () => perms.canEscalate ? _store.escalate(r.id) : _noPermission('escalate to admin'),
            )),
      ],
    );
  }
}

class _OutlineAvatar extends StatelessWidget {
  const _OutlineAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.textDark, width: 1.3)),
      child: const Icon(Icons.person_outline, size: 26, color: AppColors.textDark),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final AccountRequest request;
  final bool canApprove;
  final bool canReject;
  final bool canEscalate;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEscalate;

  const _QueueCard({
    required this.request,
    required this.canApprove,
    required this.canReject,
    required this.canEscalate,
    required this.onApprove,
    required this.onReject,
    required this.onEscalate,
  });

  void _showDocuments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${request.name} — Documents',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${request.documents.length} files submitted',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 12),
              ...request.documents.map((doc) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      doc.endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(doc, style: const TextStyle(fontSize: 13)),
                    trailing: TextButton(
                      onPressed: () => _previewDocument(context, doc),
                      child: const Text('Preview'),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _previewDocument(BuildContext context, String doc) {
    Navigator.pop(context); // close the sheet first
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc),
        content: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.insert_drive_file_outlined, size: 48, color: AppColors.textGrey),
          ),
        ), // Todo: wire up real file/image preview once documents are hosted
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGrey),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _OutlineAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(request.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        _RoleBadge(role: request.role),
                        if (request.escalated) ...[
                          const SizedBox(width: 6),
                          const _EscalatedBadge(),
                        ],
                      ],
                    ),
                    Text(request.email, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                    Text(request.userNumber, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SUBMITTED', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                    Text(formatDateTime(request.submittedAt), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DOCUMENTS', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                    Row(
                      children: [
                        Text('${request.documentCount} files', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showDocuments(context),
                          child: const Text('view', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: Icon(Icons.cancel_outlined, color: canReject ? AppColors.primary : AppColors.textGrey, size: 18),
                  label: Text('Reject', style: TextStyle(color: canReject ? AppColors.primary : AppColors.textGrey, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: canReject ? AppColors.primary : AppColors.borderGrey),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle, size: 18, color: AppColors.white),
                  label: const Text('Approved', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: canApprove ? AppColors.green : AppColors.borderGrey,
                  ),
                ),
              ),
              if (canEscalate) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Escalate to admin',
                  onPressed: request.escalated ? null : onEscalate,
                  icon: Icon(Icons.flag_outlined, color: request.escalated ? AppColors.textGrey : AppColors.yellow),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final AccountRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = role == AccountRole.mechanic ? AppColors.primary : AppColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(role.label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _EscalatedBadge extends StatelessWidget {
  const _EscalatedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 11, color: AppColors.yellow),
          SizedBox(width: 3),
          Text('Escalated', style: TextStyle(fontSize: 10, color: AppColors.yellow, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}