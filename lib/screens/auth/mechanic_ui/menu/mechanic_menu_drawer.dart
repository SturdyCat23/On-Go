import 'package:flutter/material.dart';
import '../../../../data/mechanic_account_store.dart';
import '../../../../data/moderator_data.dart';
import '../../../../theme/app_theme.dart';
import '../../sign_in_screen.dart';

class MechanicMenuDrawer extends StatefulWidget {
  const MechanicMenuDrawer({super.key});

  @override
  State<MechanicMenuDrawer> createState() => _MechanicMenuDrawerState();
}

class _MechanicMenuDrawerState extends State<MechanicMenuDrawer> {
  final _store = MechanicAccountStore.instance;

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

  String get _subtitle {
    if (_store.isDemo) return 'Demo Mode';
    if (!_store.isRegistered) return 'Mechanic';
    switch (_store.status) {
      case ApprovalStatus.approved:
        return 'Mechanic';
      case ApprovalStatus.rejected:
        return 'Account Rejected';
      case ApprovalStatus.pending:
      default:
        return 'Pending Approval';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _store.name.isEmpty ? 'Mechanic' : _store.name;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.white.withValues(alpha: 0.25),
                  child: const Icon(Icons.person_outline, color: AppColors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                    Text(_subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(icon: Icons.person_outline, label: 'My Profile', onTap: () => Navigator.pop(context)),
                _DrawerItem(icon: Icons.badge_outlined, label: 'Certifications', onTap: () => Navigator.pop(context)),
                _DrawerItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () => Navigator.pop(context)),
                _DrawerItem(icon: Icons.help_outline, label: 'Help & Support', onTap: () => Navigator.pop(context)),
                _DrawerItem(icon: Icons.call_outlined, label: 'Contact Us', onTap: () => Navigator.pop(context)),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  onTap: () {
                    // Note: deliberately NOT calling _store.clear() here —
                    // signing out should preserve the registered account
                    // (and its approval status) so the mechanic can sign
                    // back in later without re-registering, same as
                    // ClientAccountStore's behavior on the client side.
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textDark),
      title: Text(label, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
      onTap: onTap,
    );
  }
}