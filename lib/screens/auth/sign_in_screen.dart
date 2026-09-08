import 'package:flutter/material.dart';

import '../../services/backend/mobile_backend.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../welcome_screen.dart';
import 'forgot_password_screen.dart';
import 'client_ui/client_home_screen.dart';
import 'mechanic_ui/mechanic_home_screen.dart';

/// Sign In for the mobile app, which serves Clients and Mechanics.
///
/// Admin and Moderator are not roles here. They sign in to the On Go admin
/// console, a separate web application; typing one of their usernames gets a
/// pointer to it rather than a shell they should not be in on a phone.
/// [MobileBackend.auth] is what decides all of that — this screen only routes
/// whatever role comes back.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _signingIn = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _navigateToHome(Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: AppDurations.snackBar),
    );
  }

  Future<void> _handleSignIn() async {
    if (_signingIn) return;
    setState(() => _signingIn = true);

    try {
      final result = await MobileBackend.instance.auth.signIn(
        SignInRequest(
          identifier: _usernameCtrl.text,
          password: _passwordCtrl.text,
          surface: AppSurface.mobile,
        ),
      );
      if (!mounted) return;

      final user = result.user;
      if (user != null) {
        _routeTo(user);
        return;
      }
      _showMessage(_messageFor(result.failure));
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  /// Opens the shell for whichever role signed in. The console roles never
  /// reach here — [MobileBackend.auth] turns them away first — but they are
  /// answered explicitly so adding a role can't silently fall through.
  void _routeTo(AuthenticatedUser user) {
    switch (user.role) {
      case UserRole.client:
        _navigateToHome(const ClientHomeScreen());
      case UserRole.mechanic:
        _navigateToHome(const MechanicHomeScreen());
      case UserRole.admin:
      case UserRole.moderator:
        _showMessage(_consoleMessage);
    }
  }

  static const String _consoleMessage =
      'Admin and Moderator sign in on the On Go admin console website, not in the app.';

  String _messageFor(SignInFailure? failure) {
    switch (failure) {
      case SignInFailure.wrongSurface:
        return _consoleMessage;
      case SignInFailure.accountInactive:
        return 'That account has been deactivated.';
      case SignInFailure.wrongPassword:
      case SignInFailure.unknownAccount:
      case null:
        return 'Use client or mechanic as the demo username, or sign in with '
            'your registered email and password.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AuthBackground(
        child: SafeArea(
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
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
                label: _signingIn ? 'Signing In…' : 'Sign In',
                onPressed: _signingIn ? null : _handleSignIn,
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
      ),
    );
  }
}
