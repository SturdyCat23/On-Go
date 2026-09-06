import 'package:flutter/material.dart';
import '../../data/client_account_store.dart';
import '../../data/mechanic_account_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../welcome_screen.dart';
import 'admin_ui/admin_home_screen.dart';
import 'client_ui/client_home_screen.dart';
import 'mechanic_ui/mechanic_home_screen.dart';
import 'moderator_ui/moderator_home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Todo: replace this whole method with real auth once the backend exists.
  // These shortcuts keep local testing simple without forcing the full form flow.
  void _navigateToHome(Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  void _handleSignIn() {
    final username = _usernameCtrl.text.trim().toLowerCase();

    if (username == 'admin') {
      _navigateToHome(const AdminHomeScreen());
      return;
    }

    if (username == 'moderator') {
      _navigateToHome(const ModeratorHomeScreen());
      return;
    }

    if (username == 'client' || username == 'demo-client') {
      // If a real client account was already registered this session, sign
      // into THAT account instead of overwriting it with a throwaway "Demo
      // Client" identity. Only fall back to true demo mode when nothing's
      // been registered yet — mirrors the mechanic branch below exactly.
      if (!ClientAccountStore.instance.hasAccount) {
        ClientAccountStore.instance.enterDemoMode();
      }
      _navigateToHome(const ClientHomeScreen());
      return;
    }

    if (username == 'mechanic' || username == 'demo-mechanic') {
      // If a real mechanic account was already registered this session,
      // sign into THAT account (preserving its approval status) instead of
      // overwriting it with a throwaway "Demo Mechanic" identity. Only fall
      // back to true demo mode when nothing's been registered yet.
      if (!MechanicAccountStore.instance.hasAccount) {
        MechanicAccountStore.instance.enterDemoMode();
      }
      _navigateToHome(const MechanicHomeScreen());
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Use admin, moderator, client, or mechanic as the demo username'), duration: AppDurations.snackBar),
    );
  }

  void _continueAsClientDemo() {
    _usernameCtrl.text = 'client';
    _passwordCtrl.text = 'demo';
    _handleSignIn();
  }

  void _continueAsMechanicDemo() {
    _usernameCtrl.text = 'mechanic';
    _passwordCtrl.text = 'demo';
    _handleSignIn();
  }

  void _continueAsAdminDemo() {
    _usernameCtrl.text = 'admin';
    _passwordCtrl.text = 'demo';
    _handleSignIn();
  }

  void _continueAsModeratorDemo() {
    _usernameCtrl.text = 'moderator';
    _passwordCtrl.text = 'demo';
    _handleSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: AuthBottomCard(
          children: [
            AuthTextField(
              hint: 'Username',
              controller: _usernameCtrl,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              hint: 'Password',
              obscure: _obscurePassword,
              controller: _passwordCtrl,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textdark.withValues(alpha: 0.55),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: AppColors.textdark, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AuthWhiteButton(
              label: 'Sign In',
              onPressed: _handleSignIn,
            ),
            const SizedBox(height: 12),
            AuthWhiteButton(
              label: 'Continue as Client (demo)',
              onPressed: _continueAsClientDemo,
            ),
            const SizedBox(height: 8),
            AuthWhiteButton(
              label: 'Continue as Mechanic (demo)',
              onPressed: _continueAsMechanicDemo,
            ),
            const SizedBox(height: 8),
            AuthWhiteButton(
              label: 'Continue as Moderator (demo)',
              onPressed: _continueAsModeratorDemo,
            ),
            const SizedBox(height: 8),
            AuthWhiteButton(
              label: 'Continue as Admin (demo)',
              onPressed: _continueAsAdminDemo,
            ),
            const SizedBox(height: 16),
            // Wrap, not Row: at a large system text scale the prompt and the
            // link no longer fit side by side, and the link drops to its own
            // line instead of overflowing. Identical to a centred Row when it
            // does fit.
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Don't have account? ",
                  style: TextStyle(fontSize: 13, color: AppColors.textdark),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  ),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textdark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}