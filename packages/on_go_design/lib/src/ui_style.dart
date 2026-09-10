import 'ui_container_styles.dart';
import 'ui_icon_styles.dart';
import 'ui_text_styles.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  UI STYLE MODIFIER  —  start here
// ═══════════════════════════════════════════════════════════════════════════
//
//  On Go has TWO independent styling systems, and keeping them apart is what
//  makes either of them safe to change:
//
//    ┌──────────────────────────┬────────────────────────────────────────────┐
//    │ THEME / COLOUR system    │ UI STYLE system (this one)                 │
//    │ app_palette.dart         │ ui_text_styles / ui_container_styles /     │
//    │ theme_controller.dart    │ ui_icon_styles                             │
//    ├──────────────────────────┼────────────────────────────────────────────┤
//    │ WHAT colour things are   │ WHAT SIZE and SHAPE things are             │
//    │ Chosen by the USER, at   │ Chosen by the DEVELOPER, at build time     │
//    │ runtime, from Settings   │                                            │
//    │ Forest, Ember, Dark…     │ type scale, corner radii, icon sizes       │
//    └──────────────────────────┴────────────────────────────────────────────┘
//
//  A user switching to Forest Night must not change a single radius. A
//  developer squaring off every corner must not change a single colour. That
//  is why nothing in these three files names a colour, and nothing in the
//  palette names a size.
//
//  ───────────────────────────────────────────────────────────────────────────
//  THE THREE FILES
//
//    ui_text_styles.dart       11 text categories: size, weight, typeface.
//                              Scales with the screen, and every category can
//                              carry its own typeface.
//    ui_container_styles.dart  Container shapes: radius, outline width and
//                              style. Outlined and filled kept separate.
//    ui_icon_styles.dart       Icon sizes and the glyph list, with a guide.
//
//  Each is heavily commented and can be read on its own. This file just ties
//  them together for the two things you are most likely to want.
//
//  ───────────────────────────────────────────────────────────────────────────
//  EXAMPLE: restyle the whole product in one place
//
//      void main() {
//        UiStyle.apply(
//          fontFamily: 'Inter',        // new typeface everywhere
//          textScale: 1.1,             // everything 10% larger
//          cornerRadius: 8,            // squarer corners everywhere
//          outlineWidth: 2,            // heavier borders
//          iconScale: 1.15,            // slightly larger icons
//        );
//        runApp(const MyApp());
//      }
//
//  Everything is optional; anything you leave out keeps its current value.
// ═══════════════════════════════════════════════════════════════════════════

/// The one-call front door to the UI Style system.
///
/// Everything here can also be done by editing the three files directly —
/// this is the shortcut for the changes that touch everything at once.
class UiStyle {
  UiStyle._();

  /// Applies a broad restyle. Call it once, before `runApp`.
  ///
  /// * [fontFamily] — the default typeface for every text category. A
  ///   category that names its own face in `ui_text_styles.dart` keeps it;
  ///   call `AppTextStyles.applyFontFamily` instead to override those too.
  /// * [textScale] — multiplies every text size, keeping the steps between
  ///   the categories in proportion.
  /// * [cornerRadius] — sets EVERY container's radius to this. Pill shapes
  ///   (badges, stadium buttons) are left alone, because squaring them would
  ///   change what they are rather than how they look.
  /// * [outlineWidth] — sets every outlined container's border width.
  /// * [iconScale] — multiplies all four icon sizes.
  static void apply({
    String? fontFamily,
    double? textScale,
    double? cornerRadius,
    double? outlineWidth,
    double? iconScale,
  }) {
    if (fontFamily != null) AppTextStyles.fontFamily = fontFamily;

    // Scales every category at once, so a new category added to
    // `ui_text_styles.dart` is covered here without touching this file.
    if (textScale != null) AppTextStyles.scaleAll(textScale);

    if (cornerRadius != null) {
      AppContainerSpec squared(AppContainerSpec spec) =>
          // A pill stays a pill: its radius is "as round as it can be", not a
          // measurement to be overwritten.
          spec.radius >= 999 ? spec : spec.copyWith(radius: cornerRadius);

      AppOutlinedContainers.card = squared(AppOutlinedContainers.card);
      AppOutlinedContainers.field = squared(AppOutlinedContainers.field);
      AppOutlinedContainers.tile = squared(AppOutlinedContainers.tile);
      AppFilledContainers.surface = squared(AppFilledContainers.surface);
      AppFilledContainers.dialog = squared(AppFilledContainers.dialog);
      AppFilledContainers.sheet = squared(AppFilledContainers.sheet);
      AppFilledContainers.overlay = squared(AppFilledContainers.overlay);
    }

    if (outlineWidth != null) {
      AppOutlinedContainers.card =
          AppOutlinedContainers.card.copyWith(outlineWidth: outlineWidth);
      AppOutlinedContainers.field =
          AppOutlinedContainers.field.copyWith(outlineWidth: outlineWidth);
      AppOutlinedContainers.tile =
          AppOutlinedContainers.tile.copyWith(outlineWidth: outlineWidth);
      AppOutlinedContainers.chip =
          AppOutlinedContainers.chip.copyWith(outlineWidth: outlineWidth);
      AppOutlinedContainers.button =
          AppOutlinedContainers.button.copyWith(outlineWidth: outlineWidth);
    }

    if (iconScale != null) AppIconSizes.scaleAll(iconScale);
  }

  /// Puts every part of the UI Style system back to what On Go ships with.
  ///
  /// Tests call this in `setUp` so one test's restyle cannot leak into the
  /// next; it is also the way back from an experiment.
  static void resetToDefaults() {
    AppTextStyles.resetToDefaults();
    AppOutlinedContainers.resetToDefaults();
    AppFilledContainers.resetToDefaults();
    AppIconSizes.resetToDefaults();
    AppIconStyle.resetToDefaults();
    AppIcons.resetToDefaults();
  }
}
