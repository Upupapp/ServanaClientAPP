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
  final String categoryKey; // 'beauty_wellness', 'hair_nails', 'massage', 'aircon'
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

  const HomeCampaign({
    required this.id,
    required this.version,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.ctaTarget,
    required this.motionPreset,
  });
}
