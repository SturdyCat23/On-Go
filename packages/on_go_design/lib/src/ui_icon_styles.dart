import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ICON STYLE MODIFIER  —  a beginner's guide is included below
// ═══════════════════════════════════════════════════════════════════════════
//
//  WHAT THIS IS
//  Two things in one file:
//
//    1. [AppIconSizes]  — how BIG icons are, in four named steps.
//    2. [AppIcons]      — WHICH glyph each meaning uses, in one list.
//
//  Colour is not here. An icon takes its colour from the theme, like
//  everything else.
//
// ───────────────────────────────────────────────────────────────────────────
//  GUIDE: WHAT CAN YOU ACTUALLY CHANGE ABOUT AN ICON?
//
//  An icon has four settings worth knowing. Three are on every icon; the
//  fourth only works on variable fonts.
//
//  ┌─ SIZE ────────────────────────────────────────────────────────────────┐
//  │ How large the glyph is drawn, in logical pixels.                      │
//  │ Values: any number. On Go uses four steps — see [AppIconSizes].       │
//  │ Example:  Icon(AppIcons.settings, size: AppIconSizes.small)           │
//  │ Rule of thumb: an icon beside text should be about the text's size,   │
//  │ +2 or so. A 13pt label pairs with a 14–16pt icon.                     │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  ┌─ COLOUR ──────────────────────────────────────────────────────────────┐
//  │ Comes from the THEME, not from here.                                  │
//  │ Example:  Icon(AppIcons.approve, color: AppColors.success)            │
//  │ Leave it off and the icon inherits whatever the surrounding           │
//  │ IconTheme says, which is usually what you want.                       │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  ┌─ WHICH GLYPH (outlined vs filled) ────────────────────────────────────┐
//  │ Material ships most icons twice: `Icons.person` is solid,             │
//  │ `Icons.person_outline` is a hollow line drawing.                      │
//  │ On Go leans OUTLINED for ordinary UI and SOLID for a state that has   │
//  │ been reached — an approved tick, a filled star.                       │
//  │ To switch the whole product from outlined to solid, change the        │
//  │ entries in [AppIcons] below. Nothing else needs editing.              │
//  └───────────────────────────────────────────────────────────────────────┘
//
//  ┌─ WEIGHT / FILL / GRADE / OPTICAL SIZE  (advanced) ────────────────────┐
//  │ These only do something when the icon font is a VARIABLE font, such   │
//  │ as Material Symbols. Flutter's bundled `Icons` set is NOT variable,   │
//  │ so setting them there has no visible effect — which is why On Go      │
//  │ leaves them null.                                                     │
//  │                                                                       │
//  │   fill        0.0 → 1.0   hollow → solid, smoothly                    │
//  │   weight      100 → 700   stroke thickness                            │
//  │   grade      -25 → 200    fine optical weight adjustment              │
//  │   opticalSize 20 → 48     tuned for the size it is drawn at           │
//  │                                                                       │
//  │ They are wired up in [AppIconStyle] anyway, so the day the product    │
//  │ adopts Material Symbols they start working with no code change.       │
//  └───────────────────────────────────────────────────────────────────────┘
//
// ───────────────────────────────────────────────────────────────────────────
//  COMMON MODIFICATIONS — copy and paste
//
//  ① Make every icon a little bigger:
//        AppIconSizes.scaleAll(1.2);
//
//  ② Swap one icon everywhere it appears:
//        AppIcons.settings = Icons.tune;          // in main(), before runApp
//
//  ③ Switch the product from outlined icons to solid ones:
//        AppIcons.person   = Icons.person;
//        AppIcons.settings = Icons.settings;
//        …and so on for the entries you want changed.
//
//  ④ Use a variable icon font and make icons heavier:
//        AppIconStyle.weight = 600;
//        AppIconStyle.fill   = 1.0;
//
//  ⑤ Draw one icon in a state colour, just here:
//        Icon(AppIcons.approve,
//             size: AppIconSizes.small,
//             color: AppColors.success)
//
// ───────────────────────────────────────────────────────────────────────────
//  ADDING AN ICON
//  Add a field to [AppIcons] with a comment saying what it MEANS, not what it
//  looks like. `AppIcons.approve` survives a redesign; `AppIcons.greenTick`
//  does not.
// ═══════════════════════════════════════════════════════════════════════════

/// The four icon sizes On Go uses.
///
/// Anything drawing an icon should pick one of these rather than inventing a
/// number, so a change here reaches the whole product.
class AppIconSizes {
  AppIconSizes._();

  /// 14 — inline with small print: a star beside a rating, a chevron in a
  /// dense row.
  static double tiny = 14;

  /// 18 — the everyday size. List rows, field prefixes, buttons.
  static double small = 18;

  /// 24 — app bars, drawer entries, anything that is its own tap target.
  static double medium = 24;

  /// 48 — the illustration in an empty state.
  static double large = 48;

  /// Multiplies every size. `scaleAll(1.2)` makes every icon 20% bigger.
  static void scaleAll(double factor) {
    tiny *= factor;
    small *= factor;
    medium *= factor;
    large *= factor;
  }

  static void resetToDefaults() {
    tiny = 14;
    small = 18;
    medium = 24;
    large = 48;
  }
}

/// The advanced, variable-font settings described in the guide above.
///
/// All null by default, which is correct for Flutter's bundled `Icons` font —
/// it is not variable, so these would do nothing. Set them once the product
/// moves to Material Symbols.
class AppIconStyle {
  AppIconStyle._();

  /// 0.0 hollow → 1.0 solid.
  static double? fill;

  /// 100 (light) → 700 (heavy) stroke.
  static double? weight;

  /// −25 → 200. A finer adjustment than [weight].
  static double? grade;

  /// 20 → 48. The size the glyph was designed to be read at.
  static double? opticalSize;

  /// These settings as an [IconThemeData], to merge into a `ThemeData`.
  ///
  /// [color] and [size] come from the app, since colour belongs to the theme
  /// and size to [AppIconSizes].
  static IconThemeData themeData({Color? color, double? size}) => IconThemeData(
        color: color,
        size: size,
        fill: fill,
        weight: weight,
        grade: grade,
        opticalSize: opticalSize,
      );

  static void resetToDefaults() {
    fill = null;
    weight = null;
    grade = null;
    opticalSize = null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ▼▼▼  THE ICON LIST — EDIT THESE TO CHANGE A GLYPH EVERYWHERE  ▼▼▼
// ═══════════════════════════════════════════════════════════════════════════

/// Every icon On Go uses, named by MEANING.
///
/// A screen writes `AppIcons.approve`, never `Icons.check_circle`. Changing
/// the glyph for "approve" is then one edit here rather than a hunt through
/// every screen that happens to draw a tick.
///
/// Grouped by where they are used. Add to the group that fits.
class AppIcons {
  AppIcons._();

  // ── People and accounts ────────────────────────────────────────────────
  static IconData person = Icons.person_outline;
  static IconData personFilled = Icons.person;
  static IconData addPerson = Icons.person_add_alt;
  static IconData moderator = Icons.shield_outlined;
  static IconData signOut = Icons.logout;
  static IconData password = Icons.lock_outline;
  static IconData email = Icons.email_outlined;
  static IconData phone = Icons.phone_outlined;
  static IconData call = Icons.call;

  // ── Navigation and chrome ──────────────────────────────────────────────
  static IconData home = Icons.home_outlined;
  static IconData menu = Icons.menu;
  static IconData back = Icons.arrow_back;
  static IconData forward = Icons.chevron_right;
  static IconData close = Icons.close;
  static IconData search = Icons.search;
  static IconData settings = Icons.settings_outlined;
  static IconData notifications = Icons.notifications_none;
  static IconData history = Icons.history;

  // ── Jobs and work ──────────────────────────────────────────────────────
  static IconData job = Icons.work_outline;
  static IconData emergency = Icons.warning_amber_rounded;
  static IconData location = Icons.location_on_outlined;
  static IconData schedule = Icons.watch_later_outlined;
  static IconData build = Icons.build_outlined;
  static IconData quote = Icons.request_quote_outlined;
  static IconData handshake = Icons.handshake_outlined;

  // ── Money and points ───────────────────────────────────────────────────
  static IconData payment = Icons.payments_outlined;
  static IconData points = Icons.stars_rounded;
  static IconData reward = Icons.card_giftcard;
  static IconData chart = Icons.bar_chart;
  static IconData offer = Icons.local_offer_outlined;
  static IconData convert = Icons.savings_outlined;

  // ── States and decisions ───────────────────────────────────────────────
  /// A state that has been reached — solid on purpose.
  static IconData approve = Icons.check_circle;
  static IconData check = Icons.check;
  static IconData reject = Icons.close;
  static IconData escalate = Icons.flag_outlined;
  static IconData info = Icons.info_outline;
  static IconData verified = Icons.verified_outlined;
  static IconData star = Icons.star;
  static IconData starOutline = Icons.star_border;
  static IconData selected = Icons.check_circle;
  static IconData unselected = Icons.radio_button_unchecked;

  // ── Files and media ────────────────────────────────────────────────────
  static IconData image = Icons.image_outlined;
  static IconData camera = Icons.photo_camera_outlined;
  static IconData gallery = Icons.photo_library_outlined;
  static IconData pdf = Icons.picture_as_pdf_outlined;
  static IconData upload = Icons.upload_outlined;
  static IconData uploadFile = Icons.upload_file_outlined;
  static IconData delete = Icons.delete_outline;
  static IconData edit = Icons.edit_outlined;
  static IconData badge = Icons.badge_outlined;
  static IconData certificate = Icons.workspace_premium_outlined;

  // ── Appearance ─────────────────────────────────────────────────────────
  static IconData palette = Icons.palette_outlined;
  static IconData visible = Icons.visibility_outlined;
  static IconData hidden = Icons.visibility_off_outlined;

  /// Puts every glyph back to the shipped default.
  ///
  /// Long, but deliberately explicit: it doubles as the canonical list of
  /// what each name means, and a `Map` would lose the compile-time checking
  /// that stops a typo becoming a missing icon at runtime.
  static void resetToDefaults() {
    person = Icons.person_outline;
    personFilled = Icons.person;
    addPerson = Icons.person_add_alt;
    moderator = Icons.shield_outlined;
    signOut = Icons.logout;
    password = Icons.lock_outline;
    email = Icons.email_outlined;
    phone = Icons.phone_outlined;
    call = Icons.call;

    home = Icons.home_outlined;
    menu = Icons.menu;
    back = Icons.arrow_back;
    forward = Icons.chevron_right;
    close = Icons.close;
    search = Icons.search;
    settings = Icons.settings_outlined;
    notifications = Icons.notifications_none;
    history = Icons.history;

    job = Icons.work_outline;
    emergency = Icons.warning_amber_rounded;
    location = Icons.location_on_outlined;
    schedule = Icons.watch_later_outlined;
    build = Icons.build_outlined;
    quote = Icons.request_quote_outlined;
    handshake = Icons.handshake_outlined;

    payment = Icons.payments_outlined;
    points = Icons.stars_rounded;
    reward = Icons.card_giftcard;
    chart = Icons.bar_chart;
    offer = Icons.local_offer_outlined;
    convert = Icons.savings_outlined;

    approve = Icons.check_circle;
    check = Icons.check;
    reject = Icons.close;
    escalate = Icons.flag_outlined;
    info = Icons.info_outline;
    verified = Icons.verified_outlined;
    star = Icons.star;
    starOutline = Icons.star_border;
    selected = Icons.check_circle;
    unselected = Icons.radio_button_unchecked;

    image = Icons.image_outlined;
    camera = Icons.photo_camera_outlined;
    gallery = Icons.photo_library_outlined;
    pdf = Icons.picture_as_pdf_outlined;
    upload = Icons.upload_outlined;
    uploadFile = Icons.upload_file_outlined;
    delete = Icons.delete_outline;
    edit = Icons.edit_outlined;
    badge = Icons.badge_outlined;
    certificate = Icons.workspace_premium_outlined;

    palette = Icons.palette_outlined;
    visible = Icons.visibility_outlined;
    hidden = Icons.visibility_off_outlined;
  }
}
