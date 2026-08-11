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
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.white,
                  child: Icon(Icons.person, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Juan Dela Cruz', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                    Text('Mechanic', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.white)),
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
                _DrawerItem(icon: Icons.mail_outline, label: 'Contact Us', onTap: () => Navigator.pop(context)),
                const Divider(),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  iconColor: AppColors.primary,
                  textColor: AppColors.primary,
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
  final Color? iconColor;
  final Color? textColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textDark),
      title: Text(label,
          style: TextStyle(color: textColor ?? AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14)),
      onTap: onTap,
    );
  }
}