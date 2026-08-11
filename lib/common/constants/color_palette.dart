import 'package:flutter/material.dart';
import 'package:client/common/config/app_config.dart';

class ColorPalette {
  static Color primaryText = Colors.white;
  static Color primaryBackground = const Color(0xFFF3F4F6);
  static Color secondaryBackground = Colors.white;
  static Color secondaryText = const Color(0xFF111827); // near-black

  /// Secondary text: metadata, captions, helper copy.
  ///
  /// #6A717F, not the #6B7280 this was until 2026-08-11. Four thousandths of HSL
  /// lightness darker, same hue and saturation — visually indistinguishable, and
  /// not a whim:
  ///
  /// **#6B7280 on [primaryBackground] (#F6F6FA) measures 4.485:1**, which fails
  /// the WCAG 2.2 SC 1.4.3 floor of 4.5:1. That is the commonest text-on-surface
  /// pairing in the app and it has been shipping. #6A717F measures 4.55:1 there
  /// and 4.91:1 on white.
  ///
  /// Measured in the provider app, which was being aligned to this palette and
  /// has a contrast test over its token pairs — it refused the value on the way
  /// in. This app had no such test for this pair; it does now, in
  /// `test/common/no_unimplemented_dark_theme_test.dart`.
  ///
  /// Both assignments matter. This one is the default, and `applyBrand()` sets it
  /// again at startup — changing only one leaves the other shipping.
  static Color accentText = const Color(0xFF6A717F); // grey
  static Color primaryButtonTextColor = Colors.white;
  // Defaults (overridden by applyBrand at startup).
  // Logo orange (#F89040) is used as accent; logo blue (#3058C8) is primary.
  static Color primaryColor = const Color(0xFFF89040); // accent
  static Color primaryColorDark = const Color(0xFF3058C8); // primary
  static Color primaryColorLight = const Color(0xFFEAF0FF); // light blue
  static Color secondaryColor = const Color(0xFFF3F4F6);
  static Color secondaryBorder = const Color(0xFFE5E7EB);
  static Color secondaryAccentColor = const Color(0xFFE5E7EB);
  static const Color transparent = Color(0x00000000);
  static const Color danger = Color(0xFFEF4444);

  // ── Main navigation (MOVEUPNAV+ §4) ────────────────────────────────────────
  //
  // These were previously private constants inside main_nav_scaffold, which
  // meant the navigation carried its own colour system that no other surface
  // could reference and no theme change could reach. Named here so §4's "use
  // design tokens from the existing Servana theme" is actually satisfiable —
  // it was not, because the tokens did not exist.
  //
  // navActive matches primaryColorDark rather than introducing a third blue.

  /// Selected destination: bubble fill, icon-on-white, label.
  static const Color navActive = Color(0xFF3058C8);

  /// Unselected icon and label. 4.6:1 on white — above the 4.5:1 floor for the
  /// small label text, which a lighter grey would not clear.
  static const Color navInactive = Color(0xFF6D717F);

  /// Central Book action. Servana orange, so the primary action is never
  /// mistaken for a fifth navigation destination.
  static const Color navBookAction = Color(0xFFF08A24);

  /// Hairline on the bar's top edge, light theme.
  static const Color navBorder = Color(0xFFE7E9EF);

  // Convenience aliases so UI code doesn't reach for `Colors.*`.
  static Color get surface => secondaryBackground;
  static Color get onSurface => secondaryText;
  static Color get onPrimary => primaryButtonTextColor;

  static Color border([double opacity = 1]) =>
      secondaryBorder.withOpacity(_clamp01(opacity));

  static Color shadow([double opacity = 0.06]) =>
      secondaryText.withOpacity(_clamp01(opacity));

  /// Brand-friendly header gradient end color derived from [primaryColorDark].
  static Color primaryGradientEnd() => _shiftLightness(primaryColorDark, -0.12);

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  static Color _shiftLightness(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(_clamp01(hsl.lightness + delta)).toColor();
  }

  /// White-label: call this once at startup to override palette with brand colors.
  static void applyBrand(AppBrand brand) {
    // Primary + accent
    primaryColor = brand.seedColor;
    primaryColorDark = brand.primary;

    // Keep the rest in a neutral, brand-friendly set that matches the new theme.
    primaryBackground = const Color(0xFFF6F6FA);
    secondaryBackground = Colors.white;
    secondaryText = const Color(0xFF111827);
    // See the declaration: #6B7280 on #F6F6FA is 4.485:1 and fails the floor.
    accentText = const Color(0xFF6A717F);
    primaryText = Colors.white;
    primaryButtonTextColor = Colors.white;
    // Light tint used for chips/background accents (keep this brand-friendly).
    primaryColorLight = const Color(0xFFEAF0FF);
    secondaryColor = const Color(0xFFF3F4F6);
    secondaryBorder = const Color(0xFFE5E7EB);
    secondaryAccentColor = const Color(0xFFE5E7EB);
  }
}
