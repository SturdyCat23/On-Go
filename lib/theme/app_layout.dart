import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  RESPONSIVE LAYOUT
// ═══════════════════════════════════════════════════════════════════════════
//
//  WHAT THIS IS
//  One description of the device the app is running on, and the handful of
//  measurements that should change with it. Every screen asks the same
//  question — `context.layout` — and gets an answer consistent with every
//  other screen's.
//
//  On Go is a phone app that also has to survive a tablet. This file is what
//  makes "survive" mean "looks deliberate" rather than "does not crash".
//
//  ───────────────────────────────────────────────────────────────────────────
//  THE RULE THIS FILE EXISTS TO ENFORCE
//
//  There is ONE layout, not four. A small phone and a tablet run the same
//  widget tree; what changes is how much room its parts are given. Padding
//  grows, type grows a little, a hero image grows within limits, and on a
//  tablet the content stops widening and centres instead of stretching a line
//  of text across ten inches.
//
//  What does NOT happen here is a second design. If you find yourself writing
//  `if (layout.isTablet) return SomeOtherScreen()`, that is the thing this
//  file was written to avoid.
//
//  ───────────────────────────────────────────────────────────────────────────
//  HOW TO USE IT
//
//      final layout = context.layout;
//
//      Padding(padding: layout.pagePadding, …)          // page margins
//      SizedBox(height: layout.sectionGap)              // between sections
//      SizedBox(height: layout.panelHeight(190))        // a hero panel
//      CircleAvatar(radius: layout.avatarRadius)
//
//  …and wrap a scrolling page's contents in [ResponsiveBody], which applies
//  the gutter and stops the content widening past a comfortable reading
//  measure on a tablet.
//
//  ───────────────────────────────────────────────────────────────────────────
//  WHY shortestSide AND NOT width
//
//  A phone turned sideways is 844 points wide, which is wider than a small
//  tablet. Deciding on width alone would hand it a tablet's layout the moment
//  it rotated. The SHORTER side barely moves when a device rotates, so it
//  answers "what kind of device is this" rather than "which way is it being
//  held" — and the two are different questions. Orientation is available
//  separately as [isLandscape] for the places that genuinely care.
// ═══════════════════════════════════════════════════════════════════════════

/// The four kinds of device On Go lays out for.
///
/// Deliberately coarse. Every extra class is another combination to check, and
/// the differences between a 390-point phone and a 412-point one do not need a
/// name — the proportional [AppLayout.scale] covers those.
enum AppFormFactor {
  /// Under 360 points across: an iPhone SE, an older or budget Android.
  /// The tightest case, and the one that overflows if anything is fixed.
  smallPhone,

  /// 360–399. The commonest Android size.
  phone,

  /// 400–599. A Pro Max, a Galaxy Ultra.
  largePhone,

  /// 600 and over on the short side: an iPad, an Android tablet, a foldable
  /// opened out.
  tablet,
}

/// The device, and what its size means for layout.
///
/// Read it from a [BuildContext] with `context.layout` rather than building
/// one — that way every part of a screen agrees, and a widget rebuilt inside a
/// dialog or a sheet still sees the real window.
@immutable
class AppLayout {
  /// The window, in logical pixels.
  final Size size;

  final AppFormFactor formFactor;

  const AppLayout._(this.size, this.formFactor);

  factory AppLayout.fromSize(Size size) =>
      AppLayout._(size, formFactorFor(size));

  // ------------------------------------------------------------ breakpoints ---

  /// Below this, the short side belongs to a small phone.
  static const double phoneMin = 360;

  /// At or above this, a large phone.
  static const double largePhoneMin = 400;

  /// At or above this, a tablet. 600 is the long-standing Material figure and
  /// the one Android's own resource qualifiers use, so it agrees with what the
  /// platform thinks.
  static const double tabletMin = 600;

  static AppFormFactor formFactorFor(Size size) {
    final shortest = size.shortestSide;
    if (shortest >= tabletMin) return AppFormFactor.tablet;
    if (shortest >= largePhoneMin) return AppFormFactor.largePhone;
    if (shortest >= phoneMin) return AppFormFactor.phone;
    return AppFormFactor.smallPhone;
  }

  double get width => size.width;
  double get height => size.height;

  bool get isSmallPhone => formFactor == AppFormFactor.smallPhone;
  bool get isTablet => formFactor == AppFormFactor.tablet;

  /// Any phone, of any size. The common case.
  bool get isPhone => !isTablet;

  bool get isLandscape => size.width > size.height;

  /// A window short enough that vertical room is the scarce thing — a phone
  /// on its side, or a small window. Panels and images give ground here.
  bool get isShort => size.height < 640;

  // --------------------------------------------------------------- spacing ---

  /// The margin between content and the edge of the screen.
  ///
  /// Every page should use this rather than its own number. A small phone
  /// cannot spare 20 points a side; a tablet looks cramped with anything less
  /// than 28.
  double get gutter => switch (formFactor) {
        AppFormFactor.smallPhone => 14,
        AppFormFactor.phone => 16,
        AppFormFactor.largePhone => 20,
        AppFormFactor.tablet => 28,
      };

  /// The gap between one section of a page and the next.
  double get sectionGap => switch (formFactor) {
        AppFormFactor.smallPhone => 16,
        AppFormFactor.phone => 20,
        AppFormFactor.largePhone => 24,
        AppFormFactor.tablet => 32,
      };

  /// Padding inside a card.
  double get cardPadding => switch (formFactor) {
        AppFormFactor.smallPhone => 12,
        AppFormFactor.phone => 14,
        AppFormFactor.largePhone => 16,
        AppFormFactor.tablet => 20,
      };

  /// The gap between one card in a list and the next.
  double get cardSpacing => switch (formFactor) {
        AppFormFactor.smallPhone => 10,
        AppFormFactor.phone => 12,
        AppFormFactor.largePhone => 12,
        AppFormFactor.tablet => 16,
      };

  EdgeInsets get pagePadding => EdgeInsets.all(gutter);

  EdgeInsets get pageHorizontal => EdgeInsets.symmetric(horizontal: gutter);

  EdgeInsets get cardInsets => EdgeInsets.all(cardPadding);

  /// How far in from each edge a page's content should start.
  ///
  /// The gutter on a phone. On a tablet, whatever it takes to hold the content
  /// down to [contentMaxWidth] — which turns the leftover width into margin
  /// and leaves the content centred.
  ///
  /// Doing it as PADDING rather than as a centred box is deliberate: a
  /// `ListView` takes padding directly, so a page becomes tablet-aware by
  /// changing one argument, and the scrollbar and the overscroll glow still
  /// belong to the full width of the screen rather than to a column floating
  /// in the middle of it.
  double get _sideInset {
    if (!contentMaxWidth.isFinite) return gutter;
    final slack = (width - contentMaxWidth) / 2;
    return slack > gutter ? slack : gutter;
  }

  /// Page padding for a scrolling screen: inset both sides, gutter top and
  /// bottom. The default for a `ListView` that IS the page.
  EdgeInsets get pageInsets =>
      EdgeInsets.symmetric(horizontal: _sideInset, vertical: gutter);

  /// The same, for a list that sits under a header already providing the top
  /// spacing — so it does not add a second gap under it.
  EdgeInsets listInsets({double top = 0}) =>
      EdgeInsets.fromLTRB(_sideInset, top, _sideInset, gutter);

  // --------------------------------------------------------------- content ---

  /// How wide the content of a page is allowed to get.
  ///
  /// Unlimited on a phone, where the window IS the measure. Capped on a
  /// tablet, because a line of body text spanning a ten-inch screen is
  /// genuinely hard to read — the eye loses its place coming back to the left
  /// margin — and a form field a foot wide looks like a mistake. Past the cap
  /// the content centres and the extra width becomes margin.
  ///
  /// This is the single biggest difference a tablet sees, and it is the reason
  /// the app does not need a separate tablet design.
  double get contentMaxWidth => isTablet ? 680 : double.infinity;

  /// Columns for a grid of equal tiles — photos, options, credentials.
  ///
  /// A tablet gets more across rather than the same number stretched.
  int get gridColumns => switch (formFactor) {
        AppFormFactor.smallPhone => 2,
        AppFormFactor.phone => 2,
        AppFormFactor.largePhone => 3,
        AppFormFactor.tablet => 4,
      };

  // ----------------------------------------------------- proportional sizes ---

  /// The width the app's fixed numbers were originally written against.
  ///
  /// Everything hard-coded in this codebase was tuned on a phone about this
  /// wide, so it is the honest baseline to scale from: at 390 points [scale]
  /// returns exactly what the original number was.
  static const double baselineWidth = 390;

  /// [base], scaled for this device.
  ///
  /// Use it for a measurement that should grow with the screen but is not
  /// worth its own breakpoint — an icon in a header, a fixed-width badge, the
  /// height of a preview.
  ///
  /// Clamped at both ends on purpose. Straight proportional scaling would
  /// shrink a 320-point phone's controls to the point of being hard to hit,
  /// and would nearly double everything on a tablet, which is not what a
  /// tablet wants — it wants more room around things, not bigger things.
  double scale(double base, {double min = 0.88, double max = 1.3}) {
    final factor = (width / baselineWidth).clamp(min, max);
    return base * factor;
  }

  /// The height for a panel that was written as a fixed number — a map
  /// preview, a photo, a scanner window.
  ///
  /// Scales like [scale], then gives way to the screen: never more than
  /// [maxFraction] of the window's height. That second limit is what stops a
  /// 190-point panel from swallowing a short window, or a phone held sideways
  /// from showing nothing but the panel.
  double panelHeight(double base, {double maxFraction = 0.34}) {
    final scaled = scale(base);
    final ceiling = height * maxFraction;
    return scaled < ceiling ? scaled : ceiling;
  }

  /// The radius of a profile photo in a header.
  double get avatarRadius => switch (formFactor) {
        AppFormFactor.smallPhone => 34,
        AppFormFactor.phone => 40,
        AppFormFactor.largePhone => 44,
        AppFormFactor.tablet => 56,
      };

  /// How much to multiply every text size by.
  ///
  /// Gentle, and gentle on purpose: the app's type sizes were chosen for a
  /// phone and mostly still suit one. A small phone pulls back a touch so a
  /// long label has room to fit rather than ellipsing; a tablet grows a little
  /// because it is held further away. Anything more aggressive and the fixed
  /// sizes still scattered through the screens start colliding with the boxes
  /// they sit in.
  double get textScale => switch (formFactor) {
        AppFormFactor.smallPhone => 0.94,
        AppFormFactor.phone => 1.0,
        AppFormFactor.largePhone => 1.0,
        AppFormFactor.tablet => 1.12,
      };

  /// The most the reader's own font-size setting may enlarge text.
  ///
  /// Accessibility settings can ask for 2× or more. This app's screens are
  /// full of fixed heights and single-line labels, and at 2× they break — text
  /// clipped, rows overflowing. Honouring the setting up to a point is better
  /// than honouring it into an unusable screen; raising this is work on the
  /// screens, not a number to change here on its own.
  static const double maxTextScale = 1.35;

  /// The floor, so a reader who has shrunk their system font does not end up
  /// with captions nobody can read.
  static const double minTextScale = 0.85;

  /// The text scaler the app should actually run at, given what the reader's
  /// device asked for.
  ///
  /// Two things combined, in this order:
  ///
  ///  1. [reader]'s own setting, clamped to [minTextScale]–[maxTextScale].
  ///  2. This device's [textScale] on top.
  ///
  /// The reader's scaler is kept and asked to scale a slightly different size,
  /// rather than being replaced by a flat multiplier. That matters because a
  /// system scaler is not necessarily a straight multiplication — Android's
  /// non-linear font scaling deliberately enlarges small text more than large
  /// — and flattening it would throw that curve away.
  TextScaler textScalerFrom(TextScaler reader) => _DeviceTextScaler(
        reader.clamp(
          minScaleFactor: minTextScale,
          maxScaleFactor: maxTextScale,
        ),
        textScale,
      );

  @override
  bool operator ==(Object other) =>
      other is AppLayout && other.size == size && other.formFactor == formFactor;

  @override
  int get hashCode => Object.hash(size, formFactor);
}

/// The reader's own text scaling, with this device's factor applied on top.
///
/// Applies the device factor to the size going IN rather than to the result
/// coming out, so whatever curve the platform's scaler has is preserved —
/// see [AppLayout.textScalerFrom].
@immutable
class _DeviceTextScaler extends TextScaler {
  const _DeviceTextScaler(this._reader, this._device);

  final TextScaler _reader;
  final double _device;

  @override
  double scale(double fontSize) => _reader.scale(fontSize * _device);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => _reader.textScaleFactor * _device;

  // Value equality, so a rebuild that produces an identical scaler does not
  // look like a MediaQuery change and re-lay-out the whole app.
  @override
  bool operator ==(Object other) =>
      other is _DeviceTextScaler &&
      other._reader == _reader &&
      other._device == _device;

  @override
  int get hashCode => Object.hash(_reader, _device);
}

// ═══════════════════════════════════════════════════════════════════════════
//  GETTING AT IT
// ═══════════════════════════════════════════════════════════════════════════

/// Carries the [AppLayout] down the tree.
///
/// Installed once, in `main.dart`'s `MaterialApp.builder`, so it sits above
/// every route, dialog and bottom sheet — there is no screen it does not
/// reach, and no screen has to remember to install it.
class AppLayoutScope extends InheritedWidget {
  final AppLayout layout;

  const AppLayoutScope({super.key, required this.layout, required super.child});

  static AppLayout of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLayoutScope>();
    // Falling back to the window rather than throwing: a widget pumped on its
    // own in a test, or built above the scope, should still lay out sensibly
    // instead of crashing.
    return scope?.layout ?? AppLayout.fromSize(MediaQuery.sizeOf(context));
  }

  @override
  bool updateShouldNotify(AppLayoutScope old) => old.layout != layout;
}

extension AppLayoutContext on BuildContext {
  /// The device this widget is being laid out on.
  ///
  ///     final layout = context.layout;
  AppLayout get layout => AppLayoutScope.of(this);
}

// ═══════════════════════════════════════════════════════════════════════════
//  THE WIDGETS THAT DO THE WORK
// ═══════════════════════════════════════════════════════════════════════════

/// A page's content: gutters on both sides, and never wider than is
/// comfortable to read.
///
/// This is the one wrapper worth putting on every scrolling page. On a phone
/// it is just padding. On a tablet it is what keeps the app from looking like
/// a phone screen stretched — the content holds a sensible measure and centres
/// itself, and the leftover width becomes margin rather than over-long rows.
///
///     ListView(
///       children: [ ResponsiveBody(child: Column(children: [...])) ],
///     )
///
/// Put it INSIDE the scrollable rather than around it, so the scrollbar and
/// the overscroll glow still belong to the full width of the screen.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  final Widget child;

  /// Overrides the gutter. Pass [EdgeInsets.zero] for a page that paints to
  /// the edge and pads its own rows.
  final EdgeInsetsGeometry? padding;

  /// Overrides the reading measure, for content that genuinely wants to be
  /// wider — a table, a gallery.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final limit = maxWidth ?? layout.contentMaxWidth;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: limit),
        child: Padding(
          padding: padding ?? layout.pageHorizontal,
          child: child,
        ),
      ),
    );
  }
}

/// A row that becomes a column when its contents will not fit side by side.
///
/// The reflow this app needs most. A label-and-value row, a pair of buttons, a
/// figure beside its caption — all of them fit a 414-point phone and none of
/// them fit a 320-point one, and the honest answer at 320 is to stack rather
/// than to shrink the text until it cannot be read.
///
/// [breakpoint] is the width below which it stacks. Measure what the row
/// actually needs and pass that, rather than guessing a device size.
class FlexibleRow extends StatelessWidget {
  const FlexibleRow({
    super.key,
    required this.children,
    required this.breakpoint,
    this.spacing = 12,
    this.rowCrossAxisAlignment = CrossAxisAlignment.center,
    this.columnCrossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;

  /// Stack below this width.
  final double breakpoint;

  final double spacing;
  final CrossAxisAlignment rowCrossAxisAlignment;
  final CrossAxisAlignment columnCrossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The width it actually has, not the width of the screen — the same
        // row inside a card has less to work with, and that is what decides.
        final stack = constraints.maxWidth.isFinite &&
            constraints.maxWidth < breakpoint;

        if (stack) {
          return Column(
            crossAxisAlignment: columnCrossAxisAlignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: rowCrossAxisAlignment,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              children[i],
            ],
          ],
        );
      },
    );
  }
}
