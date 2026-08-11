import 'package:flutter/material.dart';
import '../../../../data/admin_data.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/date_format.dart';

class ModsTab extends StatefulWidget {
  const ModsTab({super.key});

  @override
  State<ModsTab> createState() => _ModsTabState();
}

class _ModsTabState extends State<ModsTab> {
  final _admin = AdminStore.instance;

  @override
  void initState() {
    super.initState();
    _admin.addListener(_onChange);
  }

  @override
  void dispose() {
    _admin.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _confirmRemove(String id, String name) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $name?'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Reason (optional)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _admin.removeModerator(id, reason: controller.text.isEmpty ? null : controller.text);
    }
  }

  Future<void> _editPermissions(ModeratorAccount mod) async {
    bool canApprove = mod.permissions.canApprove;
    bool canReject = mod.permissions.canReject;
    bool canEscalate = mod.permissions.canEscalate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.borderGrey.withValues(alpha: 0.5),
                        child: Text(mod.initials, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mod.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            Text('Edit permissions', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _permissionRow(
                    title: 'Can approve accounts',
                    subtitle: 'Grants account access',
                    value: canApprove,
                    onChanged: (v) => setSheetState(() => canApprove = v),
                  ),
                  Divider(height: 1, color: AppColors.borderGrey.withValues(alpha: 0.6)),
                  _permissionRow(
                    title: 'Can reject accounts',
                    subtitle: 'Decline with reasons',
                    value: canReject,
                    onChanged: (v) => setSheetState(() => canReject = v),
                  ),
                  Divider(height: 1, color: AppColors.borderGrey.withValues(alpha: 0.6)),
                  _permissionRow(
                    title: 'Can escalate to admin',
                    subtitle: 'Flag for admin review',
                    value: canEscalate,
                    onChanged: (v) => setSheetState(() => canEscalate = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        _admin.updateModeratorPermissions(
                          mod.id,
                          ModeratorPermissions(canApprove: canApprove, canReject: canReject, canEscalate: canEscalate),
                        );
                        Navigator.pop(sheetCtx);
                      },
                      child: const Text('SAVE PERMISSIONS', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  Widget _permLabel(IconData icon, String label, bool granted, Color color) {
    final c = granted ? color : AppColors.borderGrey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: granted ? FontWeight.w700 : FontWeight.w400)),
      ],
    );
  }

  Widget _metaColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mods = _admin.moderators;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${mods.length} moderators', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 12),
        ...mods.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.6))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.borderGrey.withValues(alpha: 0.5),
                          child: Text(m.initials, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (m.status == ModStatus.active ? AppColors.green : AppColors.textGrey).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(m.status == ModStatus.active ? 'active' : 'inactive',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: m.status == ModStatus.active ? AppColors.green : AppColors.textGrey)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(m.email, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                            Text(m.role, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                _permLabel(Icons.check, 'Approve', m.permissions.canApprove, AppColors.green),
                                _permLabel(Icons.close, 'Reject', m.permissions.canReject, AppColors.primary),
                                _permLabel(Icons.flag, 'Escalate', m.permissions.canEscalate, AppColors.yellow),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _metaColumn('ADDED', formatShortDate(m.addedDate))),
                                Expanded(child: _metaColumn('HANDLED', '${m.actionsHandled}')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editPermissions(m),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Edit', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _confirmRemove(m.id, m.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Remove', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }
}