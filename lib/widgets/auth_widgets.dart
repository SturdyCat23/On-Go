import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Red header banner (logo + subtitle)
class OnGoHeader extends StatelessWidget {
  final String subtitle;
  const OnGoHeader({super.key, this.subtitle = 'Service Anywhere'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
      child: Column(
        children: [
          const Text(
            'On Go',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Labelled text field with optional validation support.
class OnGoTextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const OnGoTextField({
    super.key,
    required this.label,
    this.hint = '',
    this.obscure = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

/// Step progress indicator used in multi-step registration.
///
/// [currentStep]         — the step currently being filled (1-based).
/// [highestCompletedStep]— the highest step the user has validated and passed.
///                         Circles ≤ this value are tappable.
/// [onStepTapped]        — called with the tapped step number when a completed
///                         step circle is tapped. The screen is responsible for
///                         pushing the correct route.
class RegistrationStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;
  final int highestCompletedStep;
  final ValueChanged<int>? onStepTapped;

  const RegistrationStepper({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
    this.labels = const [
      'Account',
      'Personal',
      'ID Details',
      'Documents',
      'Verification'
    ],
    this.highestCompletedStep = 0,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Circles and connector lines
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(totalSteps * 2 - 1, (i) {
              if (i.isOdd) {
                final stepBefore = (i ~/ 2) + 1;
                final stepAfter  = stepBefore + 1;
                // Green if both the step before AND after are completed
                final active = stepBefore <= highestCompletedStep &&
                               stepAfter  <= highestCompletedStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: active ? AppColors.green : AppColors.borderGrey,
                  ),
                );
              }

              final step    = i ~/ 2 + 1;
              final done    = step < currentStep;
              final current = step == currentStep;
              // A step is tappable if it has been completed (done) but is not
              // Any completed step is tappable, including steps ahead of current.
              // Current step itself is excluded (already there).
              final tappable = step <= highestCompletedStep && step != currentStep;

              final circle = Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (done || current || step <= highestCompletedStep)
                      ? AppColors.green
                      : AppColors.borderGrey,
                ),
                child: Center(
                  child: done || (step <= highestCompletedStep && !current)
                      ? const Icon(Icons.check,
                          color: AppColors.white, size: 14)
                      : Text(
                          '$step',
                          style: TextStyle(
                            color: current
                                ? AppColors.white
                                : AppColors.textGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );

              if (tappable && onStepTapped != null) {
                return GestureDetector(
                  onTap: () => onStepTapped!(step),
                  child: circle,
                );
              }
              return circle;
            }),
          ),

          const SizedBox(height: 4),

          // Labels row
          Row(
            children: List.generate(totalSteps * 2 - 1, (i) {
              if (i.isOdd) return Expanded(child: Container());
              final step    = i ~/ 2 + 1;
              final done    = step < currentStep;
              final current = step == currentStep;
              return SizedBox(
                width: 45,
                child: Text(
                  labels[step - 1],
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 9,
                    color: (done || current)
                        ? AppColors.green
                        : AppColors.textGrey,
                    fontWeight:
                        current ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Back / Next button row for multi-step forms.
class StepNavButtons extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool isLastStep;

  const StepNavButtons({
    super.key,
    this.onBack,
    this.onNext,
    this.nextLabel = 'NEXT',
    this.isLastStep = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onNext,
            child: Text(nextLabel),
          ),
        ),
      ],
    );
  }
}

/// Layout used by the Sign In / Welcome screens.
class AuthBottomCard extends StatelessWidget {
  final List<Widget> children;
  final Widget? topContent;

  const AuthBottomCard({
    super.key,
    required this.children,
    this.topContent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(child: topContent ?? const SizedBox.shrink()),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// White, borderless input field for use on the red card.
class AuthTextField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.hint,
    this.obscure = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    );

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textGrey),
        filled: true,
        fillColor: AppColors.white,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}

/// Solid white button with red text.
class AuthWhiteButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AuthWhiteButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

/// White pill button with an icon circle.
class AuthRoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AuthRoleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}