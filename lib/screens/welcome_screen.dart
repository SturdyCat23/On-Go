import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'auth/client_registration/client_registration_screen.dart';
import 'auth/mechanic_registration/mechanic_step1_account.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClientRegistrationScreen(),
                ),
              ),
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