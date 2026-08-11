import 'package:flutter/material.dart';
// Import all step screens so this helper can push any of them.
// Adjust paths if your folder structure differs.
import '../screens/auth/mechanic_registration/mechanic_step1_account.dart';
import '../screens/auth/mechanic_registration/mechanic_step2_personal.dart';
import '../screens/auth/mechanic_registration/mechanic_step3_id_details.dart';
import '../screens/auth/mechanic_registration/mechanic_step4_documents.dart';
import '../screens/auth/mechanic_registration/mechanic_step5_verification.dart';

/// Push the registration screen for [targetStep] onto the navigator stack.
///
/// Using a plain [Navigator.push] keeps the current screen in the back-stack
/// so the system back button / Back nav button works naturally.
/// The target screen loads its fields from [RegistrationDraft] on [initState],
/// so data is always pre-filled regardless of direction.
void goToRegistrationStep(BuildContext context, int targetStep) {
  final Widget screen;
  switch (targetStep) {
    case 1:
      screen = const MechanicStep1Account();
      break;
    case 2:
      screen = const MechanicStep2Personal();
      break;
    case 3:
      screen = const MechanicStep3IdDetails();
      break;
    case 4:
      screen = const MechanicStep4Documents();
      break;
    case 5:
      screen = const MechanicStep5Verification();
      break;
    default:
      return;
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
