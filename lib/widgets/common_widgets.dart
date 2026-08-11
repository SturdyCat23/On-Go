import 'package:flutter/material.dart';

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
