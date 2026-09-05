import 'package:flutter/material.dart';

/// Internal padding shared by every job card on the Client and Mechanic Jobs
/// screens — uploaded, pending, available, emergency and active alike — so no
/// card's content sits tighter against its edges than another's. One value,
/// one place to change it.
const EdgeInsets jobCardPadding = EdgeInsets.all(16);

/// Vertical gap between one job card and the next, in every job list on the
/// Client and Mechanic Jobs screens. Set from the Mechanic Accepted list,
/// which is the reference spacing.
const double jobCardSpacing = 12;

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? elevation;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.elevation, this.borderRadius, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 2,
      color: color ?? Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: borderRadius ?? BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(padding: padding, child: child),
    );
  }
}
