import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/auth_widgets.dart';
import '../../../data/registration_draft.dart';
import '../../../utils/step_navigator.dart';
import 'mechanic_step2_personal.dart';

class MechanicStep1Account extends StatefulWidget {
  const MechanicStep1Account({super.key});

  @override
  State<MechanicStep1Account> createState() => _MechanicStep1AccountState();
}

class _MechanicStep1AccountState extends State<MechanicStep1Account> {
  final _draft = RegistrationDraft.instance;

  final _usernameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _loaded         = false;

  String? _usernameError;
  String? _emailError;
  String? _passError;
  String? _confirmPassError;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    await _draft.load();
    if (!mounted) return;
    setState(() {
      _usernameCtrl.text    = _draft.username;
      _emailCtrl.text       = _draft.email;
      _passCtrl.text        = _draft.password;
      _confirmPassCtrl.text = _draft.confirmPassword;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _autosave() {
    _draft.username        = _usernameCtrl.text;
    _draft.email           = _emailCtrl.text;
    _draft.password        = _passCtrl.text;
    _draft.confirmPassword = _confirmPassCtrl.text;
    _draft.saveStep1();
  }

  bool _validate() {
    final username = _usernameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final pass     = _passCtrl.text;
    final confirm  = _confirmPassCtrl.text;

    String? usernameErr, emailErr, passErr, confirmErr;

    if (username.isEmpty) usernameErr = 'Username is required';

    if (email.isEmpty) {
      emailErr = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      emailErr = 'Enter a valid email address';
    }

    if (pass.isEmpty) {
      passErr = 'Password is required';
    } else if (pass.length < 8) {
      passErr = 'Password must be at least 8 characters';
    }

    if (confirm.isEmpty) {
      confirmErr = 'Please confirm your password';
    } else if (pass.isNotEmpty && confirm != pass) {
      confirmErr = 'Passwords do not match';
    }

    setState(() {
      _usernameError    = usernameErr;
      _emailError       = emailErr;
      _passError        = passErr;
      _confirmPassError = confirmErr;
    });

    return usernameErr == null && emailErr == null &&
           passErr == null && confirmErr == null;
  }

  Widget _field({required Widget child, required String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error,
                style: const TextStyle(fontSize: 11, color: Colors.red)),
          ),
      ],
    );
  }

  // Stepper tap — delegate to shared helper which handles all 5 steps
  void _onStepTapped(int step) => goToRegistrationStep(context, step);

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
            child: const Column(
              children: [
                Text('On Go Registration',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Complete all steps to provide services',
                    style: TextStyle(color: AppColors.white, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RegistrationStepper(
                    currentStep: 1,
                    highestCompletedStep: _draft.highestCompletedStep,
                    onStepTapped: _onStepTapped,
                  ),
                  const SizedBox(height: 20),
                  const Text('Create Your Account',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 16),

                  _field(
                    error: _usernameError,
                    child: OnGoTextField(
                      label: 'Username',
                      hint: 'juandelacruz',
                      controller: _usernameCtrl,
                      onChanged: (_) {
                        _autosave();
                        if (_usernameError != null) {
                          setState(() => _usernameError = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  _field(
                    error: _emailError,
                    child: OnGoTextField(
                      label: 'Email',
                      hint: 'juandelacruz@gmail.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        _autosave();
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  _field(
                    error: _passError,
                    child: OnGoTextField(
                      label: 'Password',
                      hint: '********',
                      obscure: _obscurePass,
                      controller: _passCtrl,
                      onChanged: (_) {
                        _autosave();
                        if (_passError != null) {
                          setState(() => _passError = null);
                        }
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _field(
                    error: _confirmPassError,
                    child: OnGoTextField(
                      label: 'Confirm Password',
                      hint: '********',
                      obscure: _obscureConfirm,
                      controller: _confirmPassCtrl,
                      onChanged: (_) {
                        _autosave();
                        if (_confirmPassError != null) {
                          setState(() => _confirmPassError = null);
                        }
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  StepNavButtons(
                    onNext: () {
                      if (!_validate()) return;
                      _draft.username        = _usernameCtrl.text.trim();
                      _draft.email           = _emailCtrl.text.trim();
                      _draft.password        = _passCtrl.text;
                      _draft.confirmPassword = _confirmPassCtrl.text;
                      _draft.saveStep1();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MechanicStep2Personal()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}