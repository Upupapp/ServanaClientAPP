import 'package:flutter/widgets.dart';

import 'package:client/common/services/motion_tokens.dart' as motion;

/// Motion constants for the curved main navigation.
///
/// Collected here rather than scattered through the widgets so the durations
/// the spec fixes (§8, §9, §13) are auditable in one place, and so reduced
/// motion is resolved through a single path (§19).
abstract final class ServanaNavMotion {
  // ── §8 tab-selection movement ──────────────────────────────────────────────

  /// Travel time for the active bubble and the curve beneath it.
  ///
  /// 320ms sits mid-range of the 280–360ms the spec allows. MoveUp's own
  /// transition is a full second; that reads as deliberate on a screen you
  /// visit occasionally and as lag on primary navigation you touch dozens of
  /// times a session, so the character is kept and the duration is not.
  static const Duration selection = Duration(milliseconds: 320);

  /// Ease-out dominant: the bubble leaves immediately and settles gently,
  /// which reads as responsive. A symmetric curve feels like it hesitates.
  static const Curve selectionCurve = Curves.easeOutCubic;

  // ── §9 page movement ───────────────────────────────────────────────────────

  static const Duration page = Duration(milliseconds: 260);
  static const Curve pageCurve = Curves.easeOutCubic;

  /// Incoming content rises this far as it fades in. Small on purpose — the
  /// intent is a sense of arrival, not a slide.
  static const double pageRiseOffset = 8;
  static const double pageStartScale = 0.985;

  // ── §7 central action press ────────────────────────────────────────────────

  static const Duration press = Duration(milliseconds: 90);
  static const Duration pressRelease = Duration(milliseconds: 70);
  static const double pressScale = 0.94;
  static const double releaseScale = 1.03;

  // ── §13 badge ──────────────────────────────────────────────────────────────

  static const Duration badge = Duration(milliseconds: 150);

  // ── §5 geometry ────────────────────────────────────────────────────────────

  /// Bar height before the device's bottom inset (§5: 68–76).
  static const double barHeight = 72;

  /// Active bubble diameter (§5: 50–56).
  static const double bubbleDiameter = 52;

  /// How far the bubble centre sits above the bar's top edge (§5: 10–14).
  static const double bubbleLift = 12;

  static const double iconSize = 24;
  static const double activeIconScale = 1.08;

  /// Central action diameter. Larger than a tab bubble so it reads as a
  /// distinct affordance rather than a fifth destination (§7).
  static const double bookDiameter = 56;

  /// Corner radius of the bar's top edge.
  static const double surfaceRadius = 24;

  /// Resolved travel time — instant-ish when the platform asks for reduced
  /// motion (§19), which disables the traveling character without touching
  /// haptics (§19 explicitly separates the two).
  static Duration selectionFor(BuildContext context) =>
      motion.AppMotionTokens.reducedMotion(context)
          ? const Duration(milliseconds: 100)
          : selection;

  static Duration pageFor(BuildContext context) =>
      motion.AppMotionTokens.reducedMotion(context)
          ? const Duration(milliseconds: 100)
          : page;

  static bool reduced(BuildContext context) =>
      motion.AppMotionTokens.reducedMotion(context);
}
