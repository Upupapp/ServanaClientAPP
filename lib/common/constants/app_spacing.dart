import 'package:flutter/widgets.dart';

/// Servana's spacing scale (HOMESPACING+ §4).
///
/// Home mixed 8, 10, 14, 16, 20 and 28pt gutters with no rule for choosing
/// between them, so sections that should have shared a vertical guide did not:
/// the search, category grid, promotion banners and benefit section sat at
/// 20pt while the active-booking card and Featured Services carousel sat at
/// 16pt, and the Featured "See All" button added another 8.
///
/// The scale is deliberately short. A longer one just relocates the original
/// problem — with ten options, picking is still a judgement call every time.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  /// Between major page sections.
  static const double section = 24;

  /// Between major sections on tablets, or either side of a section that needs
  /// visible separation from everything around it.
  static const double sectionLarge = 32;
}

/// Responsive page gutter for Home (§3).
///
/// One function, so every section lands on the same guide by construction. The
/// alternative — each widget choosing its own constant — is exactly what
/// produced the 16/20 split.
///
/// Breakpoints follow §3: 16 below 360pt, 20 on standard phones, 24 on large
/// phones and small tablets.
double homeGutter(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 360) return AppSpacing.lg;
  if (width < 600) return AppSpacing.xl;
  return AppSpacing.section;
}

/// Maximum content width on wide screens (§19).
///
/// Beyond this, extra width becomes outer margin rather than longer lines.
/// A banner stretched to 1200pt is a shallow rectangle nobody designed.
const double kHomeMaxContentWidth = 760;

/// Horizontal padding that also centres content on wide screens.
///
/// Returns symmetric padding on phones and a larger, balanced inset on tablets
/// so the content column stays at [kHomeMaxContentWidth].
EdgeInsets homeHorizontalPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final gutter = homeGutter(context);
  if (width <= kHomeMaxContentWidth + (gutter * 2)) {
    return EdgeInsets.symmetric(horizontal: gutter);
  }
  final inset = (width - kHomeMaxContentWidth) / 2;
  return EdgeInsets.symmetric(horizontal: inset);
}
