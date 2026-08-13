import 'package:flutter/material.dart';
import '../../../../data/moderator_data.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/date_format.dart';
import '../../../../widgets/common_widgets.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _store = ModerationStore.instance;

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

  Color _colorFor(ModAction a) {
    switch (a) {
      case ModAction.approved:
        return AppColors.green;
      case ModAction.rejected:
        return AppColors.primary;
      case ModAction.escalated:
        return AppColors.yellow;
    }
  }

  IconData _iconFor(ModAction a) {
    switch (a) {
      case ModAction.approved:
        return Icons.check;
      case ModAction.rejected:
        return Icons.close;
      case ModAction.escalated:
        return Icons.flag;
    }
  }

  void _previewDocument(BuildContext context, String doc) {
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

  Future<void> _reviewEscalation(AccountRequest request) async {
    final reasonController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(request.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Text('escalated', style: TextStyle(fontSize: 11, color: AppColors.yellow, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(request.email, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                Text('${request.userNumber}  •  ${request.role.label}', style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                const SizedBox(height: 4),
                Text('Submitted ${formatDateTime(request.submittedAt)}', style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                const SizedBox(height: 20),
                Text('DOCUMENTS (${request.documentCount})', style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (request.documents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No documents submitted', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                  )
                else
                  ...request.documents.map((doc) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.6)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
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
                        ),
                      )),
                const SizedBox(height: 12),
                Text('DECISION', style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(hintText: 'Reason if rejecting (optional)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        onPressed: () {
                          _store.reject(request.id, reasonController.text, actorName: 'Admin');
                          Navigator.pop(sheetCtx);
                        },
                        child: const Text('Reject', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppColors.green,
                        ),
                        onPressed: () {
                          _store.approve(request.id, actorName: 'Admin');
                          Navigator.pop(sheetCtx);
                        },
                        child: const Text('Approve', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Notifications'),
      ),
      body: Builder(
        builder: (context) {
          final activity = _store.activity;

          if (activity.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.notifications_none, size: 48, color: AppColors.textGrey),
                  SizedBox(height: 12),
                  Text('No activity yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                    'Moderator approvals, rejections, and escalations will show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activity.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = activity[index];
              final color = _colorFor(entry.action);
              final request = _store.findRequest(entry.accountId);
              final needsReview = entry.action == ModAction.escalated &&
                  request != null &&
                  request.status == ApprovalStatus.pending;
              final alreadyResolved = entry.action == ModAction.escalated &&
                  request != null &&
                  request.status != ApprovalStatus.pending;

              return AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: Icon(_iconFor(entry.action), color: color, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(entry.accountName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                    child: Text(entry.action.label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('${entry.role.label} · by ${entry.moderatorName}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                              if (entry.reason != null) ...[
                                const SizedBox(height: 2),
                                Text(entry.reason!, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                              ],
                              const SizedBox(height: 4),
                              Text(formatDateTime(entry.date), style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (needsReview) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellow,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _reviewEscalation(request),
                          child: const Text('Review', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ] else if (alreadyResolved) ...[
                      const SizedBox(height: 8),
                      Text('Resolved · ${request.status == ApprovalStatus.approved ? 'approved' : 'rejected'} by ${request.reviewerName ?? '—'}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}