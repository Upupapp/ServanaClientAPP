import 'package:flutter/material.dart';
import 'package:client/common/config/app_config.dart';

class ColorPalette {
  static Color primaryText = Colors.white;
  static Color primaryBackground = const Color(0xFFF3F4F6);
  static Color secondaryBackground = Colors.white;
  static Color secondaryText = const Color(0xFF111827); // near-black
  static Color accentText = const Color(0xFF6B7280); // grey
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
    accentText = const Color(0xFF6B7280);
    primaryText = Colors.white;
    primaryButtonTextColor = Colors.white;
    // Light tint used for chips/background accents (keep this brand-friendly).
    primaryColorLight = const Color(0xFFEAF0FF);
    secondaryColor = const Color(0xFFF3F4F6);
    secondaryBorder = const Color(0xFFE5E7EB);
    secondaryAccentColor = const Color(0xFFE5E7EB);
  }
}
