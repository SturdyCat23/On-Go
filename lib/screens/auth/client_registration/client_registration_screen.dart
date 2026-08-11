import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../client_ui/client_home_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/auth_widgets.dart';

class ClientRegistrationScreen extends StatefulWidget {
  const ClientRegistrationScreen({super.key});

  @override
  State<ClientRegistrationScreen> createState() =>
      _ClientRegistrationScreenState();
}

class _ClientRegistrationScreenState extends State<ClientRegistrationScreen> {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final _emailCtrl       = TextEditingController();
  final _firstNameCtrl   = TextEditingController();
  final _lastNameCtrl    = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // ── UI state ─────────────────────────────────────────────────────────────────
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;

  // ── Profile photo ─────────────────────────────────────────────────────────────
  File?  _profilePhoto;     // local file from gallery / camera
  final  _picker = ImagePicker();

  // ── Social auth ───────────────────────────────────────────────────────────────
  bool    _isSocialLogin  = false;
  String? _socialProvider;   // 'Google' | 'Facebook'
  String? _socialPhotoUrl;   // remote URL from provider

  // ── Validation errors ─────────────────────────────────────────────────────────
  Map<String, String?> _err = {};

  // ─────────────────────────────────────────────────────────────────────────────
  // Image picker
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _pickGallery() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _profilePhoto = File(picked.path));
    }
  }

  Future<void> _takeSelfie() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _profilePhoto = File(picked.path));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Social auth
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _continueWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final account = await GoogleSignIn(scopes: ['email', 'profile']).signIn();
      if (account == null) return;

      final parts = (account.displayName ?? '').trim().split(' ');
      setState(() {
        _emailCtrl.text     = account.email;
        _firstNameCtrl.text = parts.isNotEmpty ? parts.first : '';
        _lastNameCtrl.text  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _socialPhotoUrl     = account.photoUrl;
        _isSocialLogin      = true;
        _socialProvider     = 'Google';
        _profilePhoto       = null; // use the provider URL instead
        _err                = {};
      });
    } catch (_) {
      _snack('Google sign-in failed. Please try again.', error: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _continueWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      final result = await FacebookAuth.instance
          .login(permissions: ['email', 'public_profile']);

      if (result.status == LoginStatus.cancelled) return;
      if (result.status != LoginStatus.success) {
        _snack('Facebook sign-in failed. Please try again.', error: true);
        return;
      }

      final data = await FacebookAuth.instance
          .getUserData(fields: 'name,email,picture.height(200)');

      final parts = (data['name'] as String? ?? '').trim().split(' ');
      setState(() {
        _emailCtrl.text     = data['email'] ?? '';
        _firstNameCtrl.text = parts.isNotEmpty ? parts.first : '';
        _lastNameCtrl.text  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _socialPhotoUrl     = (data['picture'] as Map?)?['data']?['url'] as String?;
        _isSocialLogin      = true;
        _socialProvider     = 'Facebook';
        _profilePhoto       = null;
        _err                = {};
      });
    } catch (_) {
      _snack('Facebook sign-in failed. Please try again.', error: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _disconnectSocial() => setState(() {
        _isSocialLogin  = false;
        _socialProvider = null;
        _socialPhotoUrl = null;
        _emailCtrl.clear();
        _firstNameCtrl.clear();
        _lastNameCtrl.clear();
        _profilePhoto   = null;
        _err            = {};
      });

  // Remove current photo (local takes priority; fall back to social URL)
  void _removePhoto() => setState(() {
        if (_profilePhoto != null) {
          _profilePhoto = null;   // reveal social URL preview if it still exists
        } else {
          _socialPhotoUrl = null; // clear social URL so no preview shows
        }
      });

  // ─────────────────────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────────────────────
  bool _validate() {
    final e = <String, String?>{};

    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      e['email'] = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      e['email'] = 'Enter a valid email address';
    }

    if (_firstNameCtrl.text.trim().isEmpty) e['firstName'] = 'First name is required';
    if (_lastNameCtrl.text.trim().isEmpty)  e['lastName']  = 'Last name is required';
    if (_addressCtrl.text.trim().isEmpty)   e['address']   = 'Address is required';

    final digits = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      e['phone'] = 'Mobile number is required';
    } else if (digits.length < 10) {
      e['phone'] = 'Enter a valid mobile number';
    }

    if (!_isSocialLogin) {
      if (_passCtrl.text.isEmpty) {
        e['password'] = 'Password is required';
      } else if (_passCtrl.text.length < 8) {
        e['password'] = 'Password must be at least 8 characters';
      }

      if (_confirmPassCtrl.text.isEmpty) {
        e['confirmPass'] = 'Please confirm your password';
      } else if (_passCtrl.text != _confirmPassCtrl.text) {
        e['confirmPass'] = 'Passwords do not match';
      }
    }

    setState(() => _err = e);
    return e.isEmpty;
  }

  void _submit() {
    if (!_validate()) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
      (route) => false,
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : AppColors.primary,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // True when any photo is ready to preview
    final bool hasPhoto = _profilePhoto != null || _socialPhotoUrl != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // ── Header ───────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                child: Column(
                  children: const [
                    Text(
                      'Client Registration',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create your account to book services',
                      style: TextStyle(color: AppColors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Social section ────────────────────────────────────────
                      if (!_isSocialLogin) ...[
                        _SocialButton(
                          icon: Icons.g_mobiledata_rounded,
                          iconColor: const Color(0xFFEA4335),
                          label: 'Continue with Google',
                          onTap: _continueWithGoogle,
                        ),
                        const SizedBox(height: 12),
                        _SocialButton(
                          icon: Icons.facebook,
                          iconColor: const Color(0xFF1877F2),
                          label: 'Continue with Facebook',
                          onTap: _continueWithFacebook,
                        ),
                        const SizedBox(height: 20),
                        Row(children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or fill in manually',
                              style: TextStyle(
                                  color: AppColors.textGrey, fontSize: 12),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ]),
                        const SizedBox(height: 20),
                      ] else ...[
                        // ── Connected badge ───────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF4CAF50)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _socialProvider == 'Google'
                                    ? Icons.g_mobiledata_rounded
                                    : Icons.facebook,
                                color: _socialProvider == 'Google'
                                    ? const Color(0xFFEA4335)
                                    : const Color(0xFF1877F2),
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Connected via $_socialProvider',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                    Text(
                                      _emailCtrl.text,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF388E3C)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _disconnectSocial,
                                style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E7D32)),
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Profile Picture ───────────────────────────────────────
                      Row(
                        children: const [
                          Text(
                            'Profile Picture',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            ' *',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload a clear photo of yourself.',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 10),

                      // ── Photo preview (appears above buttons once set) ─────────
                      if (hasPhoto) ...[
                        Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 140×140 rounded-square preview — matches mechanic Step 5
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _profilePhoto != null
                                    ? Image.file(
                                        _profilePhoto!,
                                        width: 140,
                                        height: 140,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        _socialPhotoUrl!,
                                        width: 140,
                                        height: 140,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          width: 140,
                                          height: 140,
                                          color: const Color(0xFFF0F0F0),
                                          child: const Icon(
                                            Icons.person_outline,
                                            size: 52,
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                      ),
                              ),
                              // Red ✕ remove button
                              Positioned(
                                top: -10,
                                right: -10,
                                child: GestureDetector(
                                  onTap: _removePhoto,
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Upload / Selfie buttons ───────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.upload_outlined, size: 18),
                              label: const Text('UPLOAD\nPHOTO',
                                  textAlign: TextAlign.center),
                              onPressed: _pickGallery,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.blue,
                                side: const BorderSide(color: AppColors.blue),
                                minimumSize: const Size(0, 56),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.camera_alt_outlined,
                                  size: 18),
                              label: const Text('TAKE\nSELFIE',
                                  textAlign: TextAlign.center),
                              onPressed: _takeSelfie,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.blue,
                                side: const BorderSide(color: AppColors.blue),
                                minimumSize: const Size(0, 56),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Form fields ───────────────────────────────────────────
                      OnGoTextField(
                        label: 'Email *',
                        hint: 'juandelacruz@gmail.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _err['email'],
                      ),
                      const SizedBox(height: 14),
                      OnGoTextField(
                        label: 'First Name *',
                        hint: 'Juan',
                        controller: _firstNameCtrl,
                        errorText: _err['firstName'],
                      ),
                      const SizedBox(height: 14),
                      OnGoTextField(
                        label: 'Last Name *',
                        hint: 'De la Cruz',
                        controller: _lastNameCtrl,
                        errorText: _err['lastName'],
                      ),
                      const SizedBox(height: 14),
                      OnGoTextField(
                        label: 'Address *',
                        hint: 'Puerto Princesa City',
                        controller: _addressCtrl,
                        errorText: _err['address'],
                      ),
                      const SizedBox(height: 14),
                      OnGoTextField(
                        label: 'Mobile Number *',
                        hint: '+63 XXX XXX XXXX',
                        keyboardType: TextInputType.phone,
                        controller: _phoneCtrl,
                        errorText: _err['phone'],
                      ),

                      // ── Password (manual only) ────────────────────────────────
                      if (!_isSocialLogin) ...[
                        const SizedBox(height: 14),
                        OnGoTextField(
                          label: 'Password *',
                          hint: '••••••••',
                          obscure: _obscurePass,
                          controller: _passCtrl,
                          errorText: _err['password'],
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
                        const SizedBox(height: 14),
                        OnGoTextField(
                          label: 'Confirm Password *',
                          hint: '••••••••',
                          obscure: _obscureConfirm,
                          controller: _confirmPassCtrl,
                          errorText: _err['confirmPass'],
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
                      ] else ...[
                        // ── Provider note ─────────────────────────────────────
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline,
                                  size: 16, color: AppColors.textGrey),
                              const SizedBox(width: 8),
                              Text(
                                'Password is managed by $_socialProvider',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── Submit ────────────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Loading overlay ───────────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}

// ── Reusable social button ──────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
