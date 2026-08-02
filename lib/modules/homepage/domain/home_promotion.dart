enum HomeBannerSlot {
  primaryHero,
  categorySpotlight,
  reengagement,
  compactStrip,
  inline,
}

enum HomeMotionPreset {
  productReveal,
  categoryBloom,
  airflowSweep,
  wellnessRipple,
  benefitOrbit,
  cleanWipe,
  genericFade,
  staticPreset,
}

enum HomePromotionAudience { all, guestOnly, authenticatedOnly }

enum HomeVisualQuality { full, standard, reduced, staticQuality }

enum HomeEntryContext {
  firstAfterOnboarding,
  returningLaunch,
  returningFromCategory,
  returningFromBooking,
  returningFromAuth,
  tabReselection,
  deepLink,
  notificationEntry,
  appResume,
}

// Typed navigation target — validated before navigation
sealed class HomePromotionTarget {
  const HomePromotionTarget();
}

class HomeTargetCategory extends HomePromotionTarget {
  final String
      categoryKey; // 'beauty_wellness', 'hair_nails', 'massage', 'aircon'
  const HomeTargetCategory(this.categoryKey);
}

class HomeTargetSearch extends HomePromotionTarget {
  final String? initialQuery;
  const HomeTargetSearch({this.initialQuery});
}

class HomeTargetInformational extends HomePromotionTarget {
  final String pageId;
  const HomeTargetInformational(this.pageId);
}

class HomeTargetNoNavigation extends HomePromotionTarget {
  const HomeTargetNoNavigation();
}

enum HomeBannerTheme { primaryBlue, categoryPurple, reengagementNavy, wellness }

class HomePromotion {
  final String id;
  final String version;
  final HomeBannerSlot slot;
  final String title;
  final String? subtitle;
  final String ctaLabel;
  final HomePromotionTarget target;
  final HomeMotionPreset motion;
  final HomeBannerTheme theme;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int priority;
  final HomePromotionAudience audience;
  final bool dismissible;
  final String analyticsId;
  final String accessibilityDescription;

  const HomePromotion({
    required this.id,
    required this.version,
    required this.slot,
    required this.title,
    this.subtitle,
    required this.ctaLabel,
    required this.target,
    required this.motion,
    required this.theme,
    this.startsAt,
    this.endsAt,
    required this.priority,
    required this.audience,
    this.dismissible = false,
    required this.analyticsId,
    required this.accessibilityDescription,
  });

  bool get isActive {
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  bool isEligibleFor({required bool isAuthenticated}) {
    if (!isActive) return false;
    return switch (audience) {
      HomePromotionAudience.all => true,
      HomePromotionAudience.guestOnly => !isAuthenticated,
      HomePromotionAudience.authenticatedOnly => isAuthenticated,
    };
  }
}

class HomeCampaign {
  final String id;
  final String version;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final HomePromotionTarget ctaTarget;
  final HomeMotionPreset motionPreset;

  // ── LAUNCHBANNER+ §4 lifecycle ──────────────────────────────────────────
  // All defaulted, so the pre-existing `defaultSpotlight` const keeps
  // compiling unchanged. A campaign that does not opt in behaves exactly as
  // it did before these fields existed.

  /// Local kill switch. Remote Config overrides this at runtime (§22); this
  /// value is the safe default used before or without a successful fetch.
  final bool enabled;

  /// Optional flight window. Null means "no bound on that side".
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Bundled artwork. Null means the campaign has no creative and must render
  /// through its native accessible layout only.
  final String? assetPath;

  /// Intrinsic size of [assetPath], used to derive the CTA hotspot
  /// proportionally rather than from raw screen pixels (§13).
  final double? assetWidth;
  final double? assetHeight;

  /// Hard cap on verified impressions for this campaign version (§6).
  final int maxImpressions;

  /// How long "Remind me later" suppresses the campaign (§6).
  final Duration remindLaterCooldown;

  /// Minimum spacing between impressions, independent of remind-later.
  final Duration minTimeBetweenImpressions;

  /// Inclusive app-version bounds, compared as dotted-numeric (§21).
  final String? minAppVersion;
  final String? maxAppVersion;

  const HomeCampaign({
    required this.id,
    required this.version,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.ctaTarget,
    required this.motionPreset,
    this.enabled = true,
    this.startsAt,
    this.endsAt,
    this.assetPath,
    this.assetWidth,
    this.assetHeight,
    this.maxImpressions = 3,
    this.remindLaterCooldown = const Duration(days: 7),
    this.minTimeBetweenImpressions = const Duration(days: 7),
    this.minAppVersion,
    this.maxAppVersion,
  });

  /// Aspect ratio of the creative, or null when there is no creative.
  ///
  /// Callers use this with [BoxFit.contain] so the artwork is never cropped —
  /// §10 forbids cropping the headline, CTA or footer.
  double? get assetAspectRatio =>
      (assetWidth != null && assetHeight != null && assetHeight! > 0)
          ? assetWidth! / assetHeight!
          : null;

  /// Whether the flight window is open at [now].
  ///
  /// Mirrors [HomePromotion.isActive] deliberately rather than sharing it:
  /// that one reads the wall clock internally, which is untestable. This takes
  /// the clock as an argument.
  bool isWithinFlightWindow(DateTime now) {
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  HomeCampaign copyWith({
    bool? enabled,
    DateTime? startsAt,
    DateTime? endsAt,
    int? maxImpressions,
    Duration? remindLaterCooldown,
    String? minAppVersion,
    String? maxAppVersion,
  }) {
    return HomeCampaign(
      id: id,
      version: version,
      title: title,
      subtitle: subtitle,
      ctaLabel: ctaLabel,
      ctaTarget: ctaTarget,
      motionPreset: motionPreset,
      enabled: enabled ?? this.enabled,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      assetPath: assetPath,
      assetWidth: assetWidth,
      assetHeight: assetHeight,
      maxImpressions: maxImpressions ?? this.maxImpressions,
      remindLaterCooldown: remindLaterCooldown ?? this.remindLaterCooldown,
      minTimeBetweenImpressions: minTimeBetweenImpressions,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      maxAppVersion: maxAppVersion ?? this.maxAppVersion,
    );
  }
}
