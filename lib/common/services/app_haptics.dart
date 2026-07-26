import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralised haptic feedback for Servana.
///
/// Rules:
/// - Never trigger on keystrokes or passive scrolling.
/// - Never trigger repeatedly when an API fails.
/// - Never use haptics as the ONLY signal of a result — always pair with
///   visible feedback.
/// - All methods are fire-and-forget; they swallow errors silently so a
///   device without a vibration motor never crashes the app.
abstract final class AppHaptics {
  static bool _enabled = true;

  /// Called by [SettingsController] when the user toggles the haptics preference.
  /// OS accessibility feedback is never affected — only app-initiated calls.
  static void setEnabled(bool enabled) => _enabled = enabled;

  /// Exposed for testing only — do not use in production code.
  @visibleForTesting
  static bool get isEnabled => _enabled;
  /// Light tap — use for low-stakes selections (toggle, option pick, tab).
  static Future<void> selection() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Medium impact — use for valid form submissions, OTP verified, sign-in.
  static Future<void> medium() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy success — use for registration complete, booking restored,
  /// password reset completed.
  static Future<void> success() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Warning / destructive — use sparingly for logout confirmation,
  /// discard draft, expired session.
  static Future<void> warning() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Restrained tap when the user enters a category — like a page turn.
  /// Do NOT call on passive scrolling, filter chip selection, or keystrokes.
  static Future<void> categoryEntry() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Gentle confirmation that the category reveal has settled.
  /// Called once per session per category, on first-view only, never during
  /// passive animations or reduced-motion sessions.
  static Future<void> categoryRevealSettled() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Precise light impact — use for the orange chevron lock-in during the
  /// Servana logo animation and for single element arrivals in onboarding.
  static Future<void> light() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
