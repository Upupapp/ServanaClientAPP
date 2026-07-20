import 'package:flutter/widgets.dart';

/// Controls the richness of motion throughout the Servana welcome and
/// onboarding experience. Resolved once at cold-start and held for the
/// session — never changes while the user is inside onboarding.
enum WelcomeMotionMode {
  /// All cinematic effects: logo fragments, multi-layer parallax, orange
  /// ribbon, traveling service cards, subtle ambient loops.
  full,

  /// Lighter variant: logo fragments, reduced parallax depth, one traveling
  /// element. Suitable for mid-range hardware where [full] might stutter.
  standard,

  /// Short logo assembly + cross-fades. No parallax, no traveling elements.
  /// Activated manually or when the platform reports performance pressure.
  reduced,

  /// Fully static: final logo mark, page backgrounds at full opacity,
  /// immediate actions. Activated when [MediaQueryData.disableAnimations]
  /// is true (Reduce Motion on iOS / Remove animations on Android).
  staticMode;

  /// Resolve the appropriate mode from the current [BuildContext].
  factory WelcomeMotionMode.resolve(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return WelcomeMotionMode.staticMode;
    }
    return WelcomeMotionMode.full;
  }

  bool get hasParallax => this == full || this == standard;
  bool get hasTravelingElements => this == full || this == standard;
  bool get hasLogoFragments => this != staticMode;
  bool get hasPortalTransition => this == full || this == standard;
  bool get hasAmbientLoops => this == full;
  bool get isStatic => this == staticMode;
}
