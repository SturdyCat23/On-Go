import 'package:flutter/material.dart';
import '../../../../data/moderator_data.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/date_format.dart';

class AccountsTab extends StatefulWidget {
  const AccountsTab({super.key});

  @override
  State<AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends State<AccountsTab> {
  final _store = ModerationStore.instance;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final accounts = _store.approved
        .where((a) => a.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search account...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: accounts.isEmpty
              ? const Center(child: Text('No accounts found', style: TextStyle(color: AppColors.textGrey)))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: accounts
                      .map((a) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                border: Border.all(color: AppColors.borderGrey),
                                borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.textDark, width: 1.3)),
                                  child: const Icon(Icons.person_outline, size: 26, color: AppColors.textDark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: AppColors.green.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(12)),
                                            child: const Text('active', style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(a.userNumber, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                                          const SizedBox(width: 8),
                                          _roleBadge(a.role),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Approved ${formatShortDate(a.reviewedAt ?? a.submittedAt)}',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
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

  Widget _roleBadge(AccountRole role) {
    final color = role == AccountRole.mechanic ? AppColors.primary : AppColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(role.label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}