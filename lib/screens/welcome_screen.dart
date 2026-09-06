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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sign up as Client', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Choose how you\'d like to create your account',
                      style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.g_mobiledata_rounded, color: AppColors.primary),
              title: const Text('Continue with Google'),
              onTap: () => Navigator.pop(ctx, 'google'),
            ),
            ListTile(
              leading: Icon(Icons.edit_note, color: AppColors.primary),
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
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: AuthBottomCard(
          children: [
            Text(
              'Welcome!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textlight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select how you want to register',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textlight),
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