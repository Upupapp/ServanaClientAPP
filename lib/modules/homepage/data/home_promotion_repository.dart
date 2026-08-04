import '../domain/home_promotion.dart';

class HomePromotionRepository {
  static const _bannerA = HomePromotion(
    id: 'banner_primary_v1',
    version: '1',
    slot: HomeBannerSlot.primaryHero,
    title: 'Home services, made simpler.',
    subtitle: 'Find, book, and manage services — all from one app.',
    ctaLabel: 'Explore Services',
    target: HomeTargetSearch(),
    motion: HomeMotionPreset.productReveal,
    theme: HomeBannerTheme.primaryBlue,
    priority: 100,
    audience: HomePromotionAudience.all,
    analyticsId: 'banner_primary_v1',
    accessibilityDescription: 'Discover and book home services with Servana',
  );

  static const _bannerBGuest = HomePromotion(
    id: 'banner_category_beauty_v1',
    version: '1',
    slot: HomeBannerSlot.categorySpotlight,
    title: 'Beauty and wellness, on your schedule.',
    subtitle: 'Browse available treatments and book in a few simple steps.',
    ctaLabel: 'See Beauty Services',
    target: HomeTargetCategory('beauty_wellness'),
    motion: HomeMotionPreset.wellnessRipple,
    theme: HomeBannerTheme.wellness,
    priority: 90,
    audience: HomePromotionAudience.all,
    analyticsId: 'banner_category_beauty_v1',
    accessibilityDescription: 'Browse beauty and wellness services',
  );

  static const _bannerCGuest = HomePromotion(
    id: 'banner_reengagement_guest_v1',
    version: '1',
    slot: HomeBannerSlot.reengagement,
    title: 'One app. More ways to get things done.',
    subtitle: 'Find, book, and manage home and personal services in one place.',
    ctaLabel: 'Get Started',
    target: HomeTargetSearch(),
    motion: HomeMotionPreset.genericFade,
    theme: HomeBannerTheme.reengagementNavy,
    priority: 80,
    audience: HomePromotionAudience.guestOnly,
    analyticsId: 'banner_reengagement_guest_v1',
    accessibilityDescription:
        'Start using Servana for home and personal services',
  );

  static const _bannerCAuth = HomePromotion(
    id: 'banner_reengagement_auth_v1',
    version: '1',
    slot: HomeBannerSlot.reengagement,
    title: 'Book again in fewer steps.',
    subtitle: 'Reuse your recent service details and review before confirming.',
    ctaLabel: 'Book a Service',
    target: HomeTargetSearch(),
    motion: HomeMotionPreset.genericFade,
    theme: HomeBannerTheme.reengagementNavy,
    priority: 80,
    audience: HomePromotionAudience.authenticatedOnly,
    analyticsId: 'banner_reengagement_auth_v1',
    accessibilityDescription: 'Book a service again quickly with Servana',
  );

  static const defaultSpotlight = HomeCampaign(
    id: 'benefit_spotlight_v1',
    version: '1',
    title: 'One app. More ways\nto get things done.',
    subtitle:
        'Discover, book, and manage home and personal services in one simple Servana experience.',
    ctaLabel: 'Explore Services',
    ctaTarget: HomeTargetSearch(),
    motionPreset: HomeMotionPreset.productReveal,
  );

  /// The Servana launch-benefits campaign (LAUNCHBANNER+).
  ///
  /// `enabled: false` is the production default §21 requires. The campaign
  /// ships dark and is turned on through Remote Config after release-candidate
  /// testing — so a bad creative or a mistimed launch is a console toggle, not
  /// an app update.
  ///
  /// Reuses [HomeTargetSearch] so the CTA flows through Home's existing
  /// `_handlePromotionTap`, which already validates the sealed target type.
  /// §14 forbids inventing a route, and this is the one the previous spotlight
  /// used for the identical "Explore Services" action.
  static const launchBenefits = HomeCampaign(
    id: 'servana_launch_benefits',
    version: '1',
    title: 'Everything you need, all in one app',
    subtitle: 'Browse services, choose your schedule, and get updates right '
        'from your phone.',
    ctaLabel: 'Explore Services',
    ctaTarget: HomeTargetSearch(),
    motionPreset: HomeMotionPreset.productReveal,
    enabled: false,
    assetPath: 'assets/images/campaigns/servana_launch_benefits_v1.webp',
    assetWidth: 941,
    assetHeight: 1672,
    maxImpressions: 3,
    remindLaterCooldown: Duration(days: 7),
    minTimeBetweenImpressions: Duration(days: 7),
  );

  /// Accessor for the launch campaign. The older [defaultSpotlight] had no
  /// getter and tests reached the static field directly; this keeps the
  /// repository the single source of campaign definitions.
  HomeCampaign getLaunchCampaign() => launchBenefits;

  HomePromotion? getBannerA({required bool isAuthenticated}) =>
      _bannerA.isEligibleFor(isAuthenticated: isAuthenticated)
          ? _bannerA
          : null;

  HomePromotion? getBannerB({required bool isAuthenticated}) =>
      _bannerBGuest.isEligibleFor(isAuthenticated: isAuthenticated)
          ? _bannerBGuest
          : null;

  HomePromotion? getBannerC({required bool isAuthenticated}) {
    if (_bannerCAuth.isEligibleFor(isAuthenticated: isAuthenticated)) {
      return _bannerCAuth;
    }
    if (_bannerCGuest.isEligibleFor(isAuthenticated: isAuthenticated)) {
      return _bannerCGuest;
    }
    return null;
  }
}
