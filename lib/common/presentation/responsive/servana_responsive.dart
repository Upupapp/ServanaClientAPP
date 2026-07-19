import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Logical-width breakpoints for Servana layout decisions.
///
/// Use capability- and size-based logic only — never check a device model name.
abstract final class ServanaBreakpoints {
  /// Below this width, use compact single-column layouts and reduce padding.
  static const double compact = 360.0;

  /// Standard phone range — the design baseline.
  static const double standard = 420.0;

  /// Large phone — wider cards, slightly more generous padding.
  static const double largePh = 600.0;

  /// Tablet threshold — use split-view or multi-column layouts.
  static const double tablet = 840.0;
}

/// Responsive helpers used throughout Servana.
///
/// All methods read from [BuildContext] — call them inside [build] or
/// [LayoutBuilder] callbacks, never at object-construction time.
abstract final class ServanaResponsive {
  // ── Breakpoint helpers ────────────────────────────────────────────────────

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < ServanaBreakpoints.compact;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= ServanaBreakpoints.largePh;

  static bool isLargeTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= ServanaBreakpoints.tablet;

  // ── Content width ─────────────────────────────────────────────────────────

  /// Horizontal padding for body content (scales with viewport).
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < ServanaBreakpoints.compact) return 12.0;
    if (w >= ServanaBreakpoints.tablet) return 48.0;
    if (w >= ServanaBreakpoints.largePh) return 32.0;
    return 16.0;
  }

  /// Maximum width for readable single-column content.
  /// Returns [double.infinity] on phones so they fill the screen.
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= ServanaBreakpoints.tablet) return 720.0;
    if (w >= ServanaBreakpoints.largePh) return 560.0;
    return double.infinity;
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  /// Maximum width for a chat bubble — 78% of screen width, clamped to
  /// [240, 320] logical pixels so narrow phones still show readable bubbles
  /// and wide tablets don't stretch them edge-to-edge.
  static double chatBubbleMaxWidth(BuildContext context) =>
      (MediaQuery.sizeOf(context).width * 0.78).clamp(240.0, 320.0);

  // ── Text scaling ──────────────────────────────────────────────────────────

  /// True when the system text scale is large enough that fixed-width label
  /// columns should collapse to a vertical stack.  Threshold: 1.25×.
  static bool isLargeText(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1.0) > 1.25;

  /// True when layout should use a stacked (column) detail row rather than
  /// a side-by-side (row) label + value pair.
  static bool useStackedDetailRow(BuildContext context) =>
      isCompact(context) || isLargeText(context);

  // ── Touch targets ─────────────────────────────────────────────────────────

  /// Minimum touch target dimension per mobile accessibility guidelines.
  static const double minTouchTarget = 44.0;

  // ── OTP cells ─────────────────────────────────────────────────────────────

  /// Computes the per-cell width for an [otpLength]-cell input that fits
  /// within [availableWidth], with [gapBetween] between each cell.
  /// Clamped to [minCell, maxCell] logical pixels.
  static double otpCellWidth({
    required double availableWidth,
    required int otpLength,
    double gapBetween = 8.0,
    double minCell = 40.0,
    double maxCell = 56.0,
  }) {
    final gapTotal = gapBetween * (otpLength - 1);
    return ((availableWidth - gapTotal) / otpLength).clamp(minCell, maxCell);
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Short helper — clamp [value] symmetrically between [lo] and [hi].
  static double clamp(double value, double lo, double hi) =>
      math.max(lo, math.min(hi, value));
}
