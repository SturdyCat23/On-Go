import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:livelyness_detection/livelyness_detection.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/auth_widgets.dart';
import '../../../data/registration_draft.dart';
import '../../../utils/step_navigator.dart';
import '../mechanic_ui/mechanic_home_screen.dart';

// pubspec.yaml — add these dependencies:
//   image_picker: ^1.1.2
//   livelyness_detection: ^0.0.1+5
//
// Android: set minSdkVersion to 21 in android/app/build.gradle
//
// iOS — ios/Runner/Info.plist (inside <dict>):
//   <key>NSCameraUsageDescription</key>
//   <string>Camera access is required for face verification.</string>
//   <key>NSMicrophoneUsageDescription</key>
//   <string>Microphone access is needed during face verification.</string>
// iOS — ios/Podfile: uncomment/set  platform :ios, '14.0'

class MechanicStep5Verification extends StatefulWidget {
  const MechanicStep5Verification({super.key});

  @override
  State<MechanicStep5Verification> createState() =>
      _MechanicStep5VerificationState();
}

class _MechanicStep5VerificationState
    extends State<MechanicStep5Verification> {
  final _draft  = RegistrationDraft.instance;
  final ImagePicker _picker = ImagePicker();

  File? _profilePhoto;
  File? _faceScanPhoto;       // captured frame returned by liveness SDK
  bool _isScanning    = false;
  bool _livenessPass  = false; // true once the SDK reports success

  bool _profilePhotoError = false;
  bool _faceScanError     = false;

  @override
  void initState() {
    super.initState();
    _restoreFromDraft();
  }

  void _restoreFromDraft() {
    _profilePhoto  = _draft.resolveFile(_draft.profilePhotoPath);
    final restored = _draft.resolveFile(_draft.faceScanPath);
    if (restored != null) {
      _faceScanPhoto = restored;
      _livenessPass  = true; // was already verified in a previous session
    }
  }

  void _autosave() {
    _draft.profilePhotoPath = _profilePhoto?.path ?? '';
    _draft.faceScanPath     = _faceScanPhoto?.path ?? '';
    _draft.saveStep5();
  }

  // ── Profile photo ────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _profilePhoto = File(picked.path);
        _profilePhotoError = false;
      });
      _autosave();
    }
  }

  Future<void> _takeSelfie() async {
    final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85);
    if (picked != null) {
      setState(() {
        _profilePhoto = File(picked.path);
        _profilePhotoError = false;
      });
      _autosave();
    }
  }

  // ── Liveness detection ───────────────────────────────────────────────────

  Future<void> _startLivenessDetection() async {
    setState(() {
      _isScanning    = true;
      _faceScanError = false;
    });

    try {
      // detectLivelyness opens a full-screen camera UI that guides the user
      // through blink + smile challenges, then returns the captured image path
      // on success or null on failure/cancellation.
      final CapturedImage? result =
          await LivelynessDetection.instance.detectLivelyness(
        context,
        config: DetectionConfig(
          startWithInfoScreen: true,
          steps: [
            LivelynessStepItem(
              step: LivelynessStep.blink,
              title: 'Blink',
              isCompleted: false,
            ),
            LivelynessStepItem(
              step: LivelynessStep.smile,
              title: 'Smile',
              isCompleted: false,
            ),
          ],
        ),
      );

      final String? capturedPath = result?.imgPath;

      if (capturedPath != null && capturedPath.isNotEmpty) {
        setState(() {
          _faceScanPhoto = File(capturedPath);
          _livenessPass  = true;
          _faceScanError = false;
        });
        _autosave();
        // todo: optionally send capturedPath + validIdPath to your backend
        // to queue a human moderator review for ID-face matching.
      } else {
        // User cancelled or challenge failed
        setState(() => _livenessPass = false);
      }
    } catch (e) {
      setState(() => _livenessPass = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face verification error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _retakeLiveness() async {
    setState(() {
      _faceScanPhoto = null;
      _livenessPass  = false;
    });
    _autosave();
    await _startLivenessDetection();
  }

  // ── Validation ───────────────────────────────────────────────────────────

  bool _validate() {
    final profileMissing  = _profilePhoto == null;
    final faceScanMissing = !_livenessPass;
    setState(() {
      _profilePhotoError = profileMissing;
      _faceScanError     = faceScanMissing;
    });
    return !profileMissing && !faceScanMissing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RegistrationStepper(
                    currentStep: 5,
                    highestCompletedStep: _draft.highestCompletedStep,
                    onStepTapped: (step) => goToRegistrationStep(context, step),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Profile Picture ─────────────────────────────────────
                  Row(
                    children: const [
                      Text('Profile Picture',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('*',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload a clear photo of yourself. You can update it every 3 months for security purposes.',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 10),

                  // Preview
                  if (_profilePhoto != null) ...[
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_profilePhoto!,
                                width: 140, height: 140, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: -10,
                            right: -10,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _profilePhoto = null);
                                _autosave();
                              },
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
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.upload_outlined, size: 18),
                          label: const Text('UPLOAD\nPHOTO',
                              textAlign: TextAlign.center),
                          onPressed: _pickFromGallery,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.blue,
                            side: BorderSide(
                                color: _profilePhotoError
                                    ? Colors.red
                                    : AppColors.blue),
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
                            side: BorderSide(
                                color: _profilePhotoError
                                    ? Colors.red
                                    : AppColors.blue),
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_profilePhotoError)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('A profile picture is required',
                          style:
                              TextStyle(fontSize: 11, color: Colors.red)),
                    ),

                  const SizedBox(height: 24),

                  // ── Face Verification ───────────────────────────────────
                  Row(
                    children: const [
                      Text('Face Verification',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('*',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'We need to confirm you are a real person. You will be asked to blink and smile.',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 20),

                  // Status card
                  Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: _livenessPass
                            ? Colors.green.shade50
                            : _faceScanError
                                ? Colors.red.shade50
                                : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _livenessPass
                              ? Colors.green
                              : _faceScanError
                                  ? Colors.red
                                  : AppColors.borderGrey,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _livenessPass
                                ? Icons.verified_user_outlined
                                : _faceScanError
                                    ? Icons.error_outline
                                    : Icons.face_outlined,
                            size: 52,
                            color: _livenessPass
                                ? Colors.green
                                : _faceScanError
                                    ? Colors.red
                                    : AppColors.textGrey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _livenessPass
                                ? 'Face Verification Passed'
                                : _faceScanError
                                    ? 'Verification required to continue'
                                    : 'Not yet verified',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _livenessPass
                                  ? Colors.green
                                  : _faceScanError
                                      ? Colors.red
                                      : AppColors.textGrey,
                            ),
                          ),
                          if (_livenessPass) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Liveness confirmed — blink & smile challenges passed.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.green),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start / Retake button
                  ElevatedButton.icon(
                    icon: Icon(
                      _livenessPass
                          ? Icons.refresh
                          : Icons.face_retouching_natural,
                      size: 18,
                    ),
                    label: Text(
                      _isScanning
                          ? 'VERIFYING...'
                          : _livenessPass
                              ? 'REDO VERIFICATION'
                              : 'START FACE VERIFICATION',
                    ),
                    onPressed: _isScanning
                        ? null
                        : _livenessPass
                            ? _retakeLiveness
                            : _startLivenessDetection,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: _livenessPass
                          ? Colors.green
                          : AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  StepNavButtons(
                    onBack: () => Navigator.pop(context),
                    onNext: () {
                      if (!_validate()) return;
                      _draft.clear(); // wipe saved draft on successful completion
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const MechanicHomeScreen()),
                        (route) => false,
                      );
                    },
                    nextLabel: 'SUBMIT',
                    isLastStep: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
    );
  }
}