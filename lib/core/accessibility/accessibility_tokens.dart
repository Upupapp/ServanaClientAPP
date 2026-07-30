import 'package:flutter/material.dart';

/// Centralized accessibility constants for the Servana Client app.
/// All minimum touch targets, semantic thresholds, and a11y settings are here.
abstract final class AccessibilityTokens {
  /// WCAG 2.2 AA minimum touch target: 24×24 CSS px / 44×44 dp for
  /// interactive controls. We use 44 as the comfortable iOS/Android minimum.
  static const double minTouchTarget = 44.0;

  /// Maximum safe text scale — above this, we may need to switch to
  /// stacked layouts. Triggers wrapping/vertical reflow.
  static const double largeTextThreshold = 1.3;

  /// The scale at which critical journey elements must still be fully
  /// functional (WCAG 1.4.4 Resize Text, 200%).
  static const double maxRequiredTextScale = 2.0;

  /// Maximum inter-control spacing that is still "adjacent" for hit-target
  /// overlap checking.
  static const double minControlSpacing = 8.0;

  /// Returns true when the system text scale is large enough to trigger
  /// stacked / wrapped layouts.
  static bool isLargeText(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) >= largeTextThreshold;

  /// Returns true when the platform has requested reduced motion.
  static bool reducedMotion(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  /// Returns true when the system is running with bold text enabled.
  static bool boldText(BuildContext context) => MediaQuery.of(context).boldText;

  /// Returns true when the system is running a screen reader (TalkBack/VoiceOver).
  static bool screenReaderActive(BuildContext context) =>
      MediaQuery.of(context).accessibleNavigation;

  /// Returns the safe minimum touch target size — 44 always.
  static double safeTouchTarget(BuildContext context) => minTouchTarget;
}
