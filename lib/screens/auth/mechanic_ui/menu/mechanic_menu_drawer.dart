import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../sign_in_screen.dart';

class MechanicMenuDrawer extends StatelessWidget {
  const MechanicMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
                    Text('Juan Dela Cruz', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                    Text('Mechanic', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
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