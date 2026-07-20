import 'package:flutter/material.dart';

/// Reusable motion foundation for Servana.
///
/// All animation durations and curves are sourced from here so screens stay
/// consistent and reduced-motion support is handled in one place.
///
/// Usage:
///   duration: AppMotionTokens.standard
///   curve:    AppMotionTokens.enterEase
///   if (AppMotionTokens.reducedMotion(context)) ...
abstract final class AppMotionTokens {
  // ── Durations ──────────────────────────────────────────────────────────────

  /// 0 ms — for immediate state swaps.
  static const Duration instant = Duration.zero;

  /// 160 ms — micro-interactions, press feedback.
  static const Duration fast = Duration(milliseconds: 160);

  /// 280 ms — standard navigation transitions, page swipes.
  static const Duration standard = Duration(milliseconds: 280);

  /// 420 ms — emphasis reveals, modal entries.
  static const Duration emphasis = Duration(milliseconds: 420);

  /// 650 ms — celebration moments (booking confirmed, registration complete).
  static const Duration celebration = Duration(milliseconds: 650);

  // Splash-specific
  static const Duration splashFull = Duration(milliseconds: 2200);
  static const Duration splashReduced = Duration(milliseconds: 500);
  // Portal transition: ClipOval expansion from logo center → Scene 1 background.
  static const Duration splashPortal = Duration(milliseconds: 600);

  // ── Curves ─────────────────────────────────────────────────────────────────

  static const Curve standardEase = Curves.easeInOut;
  static const Curve enterEase = Curves.easeOutCubic;
  static const Curve exitEase = Curves.easeInCubic;
  // Material You "emphasized" easing — fast initial movement, soft settle.
  static const Curve emphasizedEase = Cubic(0.2, 0.0, 0.0, 1.0);

  // ── Reduced-motion helpers ─────────────────────────────────────────────────

  /// True when the platform accessibility setting requests less motion.
  /// Safe to call in build(); requires a valid [context].
  static bool reducedMotion(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  /// Returns [full] normally; [fast] when reduced-motion is active.
  /// Use for travel / parallax animations that should shrink — not skip — on
  /// accessibility preferences. For decorative animations that should be
  /// removed entirely, check [reducedMotion] directly.
  static Duration resolve(BuildContext context, Duration full) =>
      reducedMotion(context) ? fast : full;

  /// Platform-level check usable without a [BuildContext] (e.g. in initState).
  /// Prefer [reducedMotion(context)] in build methods for hot-reload accuracy.
  static bool get platformReducedMotion =>
      WidgetsBinding.instance.window.accessibilityFeatures.disableAnimations;
}
