import 'package:flutter/material.dart';
import '../../../../data/admin_data.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/date_format.dart';

enum _AuditFilter { all, added, removed }

class AuditTab extends StatefulWidget {
  const AuditTab({super.key});

  @override
  State<AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<AuditTab> {
  final _admin = AdminStore.instance;
  _AuditFilter _filter = _AuditFilter.all;

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

  List<AuditEntry> get _filtered {
    final log = _admin.auditLog;
    switch (_filter) {
      case _AuditFilter.all:
        return log;
      case _AuditFilter.added:
        return log.where((e) => e.action == AuditAction.added).toList();
      case _AuditFilter.removed:
        return log.where((e) => e.action == AuditAction.removed).toList();
    }
  }

  Color _colorFor(AuditAction a) {
    switch (a) {
      case AuditAction.added:
        return AppColors.green;
      case AuditAction.removed:
        return AppColors.primary;
      case AuditAction.promoted:
        return AppColors.yellow;
    }
  }

  IconData _iconFor(AuditAction a) {
    switch (a) {
      case AuditAction.added:
        return Icons.person_add_alt;
      case AuditAction.removed:
        return Icons.person_remove_alt_1;
      case AuditAction.promoted:
        return Icons.trending_up;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _chip('All', _AuditFilter.all),
              const SizedBox(width: 8),
              _chip('Added', _AuditFilter.added),
              const SizedBox(width: 8),
              _chip('Removed', _AuditFilter.removed),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _filtered
                .map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.6))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                              radius: 20,
                              backgroundColor: _colorFor(e.action).withValues(alpha: 0.12),
                              child: Icon(_iconFor(e.action), color: _colorFor(e.action), size: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(e.moderatorName,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _colorFor(e.action).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12)),
                                      child: Text(e.action.label,
                                          style: TextStyle(fontSize: 11, color: _colorFor(e.action), fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${e.role} · by ${e.actorName}', style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                                if (e.reason != null) ...[
                                  const SizedBox(height: 2),
                                  Text(e.reason!, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ],
                                const SizedBox(height: 4),
                                Text(formatDateTime(e.date), style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, _AuditFilter value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.borderGrey),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.white : AppColors.textDark)),
      ),
    );
  }
}