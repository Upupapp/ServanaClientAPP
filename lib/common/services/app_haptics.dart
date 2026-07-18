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
  /// Light tap — use for low-stakes selections (toggle, option pick, tab).
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Medium impact — use for valid form submissions, OTP verified, sign-in.
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Heavy success — use for registration complete, booking restored,
  /// password reset completed.
  static Future<void> success() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Warning / destructive — use sparingly for logout confirmation,
  /// discard draft, expired session.
  static Future<void> warning() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
