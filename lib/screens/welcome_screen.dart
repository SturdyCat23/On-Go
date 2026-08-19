import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'auth/client_registration/client_registration_screen.dart';
import 'auth/mechanic_registration/mechanic_step1_account.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _startClientRegistration(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Sign up as Client', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Choose how you\'d like to create your account',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ),
            ListTile(
              leading: const Icon(Icons.g_mobiledata_rounded, color: Color(0xFFEA4335), size: 32),
              title: const Text('Continue with Google'),
              onTap: () => Navigator.pop(ctx, 'google'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note, color: AppColors.primary),
              title: const Text('Fill up manually'),
              onTap: () => Navigator.pop(ctx, 'manual'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientRegistrationScreen(startWithGoogle: choice == 'google'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: AuthBottomCard(
          children: [
            const Text(
              'Welcome!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select how you want to register',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.white),
            ),
            const SizedBox(height: 24),
            AuthRoleButton(
              icon: Icons.person_outline,
              label: 'Register as Client',
              onTap: () => _startClientRegistration(context),
            ),
            const SizedBox(height: 12),
            AuthRoleButton(
              icon: Icons.work_outline,
              label: 'Register as Mechanic',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MechanicStep1Account(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}