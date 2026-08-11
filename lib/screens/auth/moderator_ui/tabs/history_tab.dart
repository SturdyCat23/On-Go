import 'package:flutter/material.dart';
import '../../../../data/moderator_data.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/date_format.dart';

enum _Filter { all, approved, rejected }

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final _store = ModerationStore.instance;
  _Filter _filter = _Filter.all;

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

  List<AccountRequest> get _filtered {
    switch (_filter) {
      case _Filter.approved:
        return _store.approved;
      case _Filter.rejected:
        return _store.rejected;
      case _Filter.all:
        return [..._store.approved, ..._store.rejected]
          ..sort((a, b) => (b.reviewedAt ?? b.submittedAt).compareTo(a.reviewedAt ?? a.submittedAt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _chip('All', _Filter.all),
              const SizedBox(width: 8),
              _chip('Approved', _Filter.approved),
              const SizedBox(width: 8),
              _chip('Rejected', _Filter.rejected),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No records', style: TextStyle(color: AppColors.textGrey)))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: items.map((r) => _HistoryCard(request: r)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, _Filter value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.borderGrey.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.white : AppColors.textDark)),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AccountRequest request;
  const _HistoryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final approved = request.status == ApprovalStatus.approved;
    final color = approved ? AppColors.green : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.borderGrey), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.3)),
            child: Icon(approved ? Icons.check : Icons.close, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(request.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Text(approved ? 'approved' : 'rejected', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(request.userNumber, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                    const SizedBox(width: 8),
                    _RoleBadgeStatic(role: request.role),
                  ],
                ),
                if (request.reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(request.reason!, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 4),
                Text(formatDateTime(request.reviewedAt ?? request.submittedAt), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadgeStatic extends StatelessWidget {
  final AccountRole role;
  const _RoleBadgeStatic({required this.role});

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