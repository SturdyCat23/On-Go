import 'package:flutter/material.dart';

/// Corner radius scale. Every rounded surface in the app should land on one of
/// these steps rather than picking its own number.
///
/// [pill] is the shape for buttons and badges — fully rounded ends, sized from
/// the widget's own height.
class AppRadii {
  AppRadii._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static BorderRadius get borderXs => BorderRadius.circular(xs);
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);

  /// Top-rounded sheet corners.
  static BorderRadius get sheetTop => const BorderRadius.vertical(top: Radius.circular(xl));

  static const StadiumBorder pill = StadiumBorder();
}

/// Border thickness scale: hairline dividers and outlines, standard control
/// outlines, and the heavy rule used to underline a section.
class AppBorders {
  AppBorders._();

  static const double thin = 1;
  static const double regular = 2;
  static const double thick = 4;
}

/// Elevation levels, as Material elevation values.
///
/// * [flat] — sits directly on the page.
/// * [hover] — a control that has lifted slightly.
/// * [raised] — cards and other raised layers.
/// * [modal] — dialogs and sheets over the page.
/// * [popover] — tooltips, toasts and menus above everything.
class AppElevation {
  AppElevation._();

  static const double flat = 0;
  static const double hover = 1;
  static const double raised = 3;
  static const double modal = 8;
  static const double popover = 12;
}

/// Hand-rolled shadows for the widgets that paint their own surface instead of
/// going through Material elevation. The tones mirror [AppElevation].
///
/// Black rather than a palette color, so the shadow disappears against a dark
/// theme instead of glowing.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> flat = [];

  static const List<BoxShadow> hover = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> modal = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> popover = [
    BoxShadow(color: Color(0x29000000), blurRadius: 28, offset: Offset(0, 12)),
  ];
}
