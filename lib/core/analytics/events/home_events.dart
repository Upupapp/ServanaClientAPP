import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

final class HomeViewedEvent extends AnalyticsEvent {
  const HomeViewedEvent({required this.accountState});
  final String accountState;
  @override
  String get eventName => 'home_viewed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  String? get dedupKey => 'home_viewed';
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.accountState: accountState};
}

final class HomeSearchSelectedEvent extends AnalyticsEvent {
  const HomeSearchSelectedEvent();
  @override
  String get eventName => 'home_search_selected';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {};
}

final class HomeCategorySelectedEvent extends AnalyticsEvent {
  const HomeCategorySelectedEvent({required this.categoryKey});
  final String categoryKey;
  @override
  String get eventName => 'home_category_selected';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.categoryKey: categoryKey};
}

final class HomeServiceSelectedEvent extends AnalyticsEvent {
  const HomeServiceSelectedEvent(
      {required this.serviceCategory, required this.surface});
  final String serviceCategory;
  final String surface;
  @override
  String get eventName => 'home_service_selected';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.surface: surface,
      };
}

final class HomeActiveBookingSelectedEvent extends AnalyticsEvent {
  const HomeActiveBookingSelectedEvent({required this.bookingStatusCategory});
  final String bookingStatusCategory;
  @override
  String get eventName => 'home_active_booking_selected';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.bookingStatusCategory: bookingStatusCategory};
}

final class HomePromotionSelectedEvent extends AnalyticsEvent {
  const HomePromotionSelectedEvent({required this.promotionCategory});
  final String promotionCategory;
  @override
  String get eventName => 'home_promotion_selected';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.promotionCategory: promotionCategory};
}

final class OnboardingStartedEvent extends AnalyticsEvent {
  const OnboardingStartedEvent({required this.entrySource});
  final String entrySource;
  @override
  String get eventName => 'onboarding_started';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.entrySource: entrySource};
}

final class OnboardingCardViewedEvent extends AnalyticsEvent {
  const OnboardingCardViewedEvent(
      {required this.cardKey, required this.stepNumber});
  final String cardKey;
  final int stepNumber;
  @override
  String get eventName => 'onboarding_card_viewed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.cardKey: cardKey,
        AnalyticsKeys.stepNumber: stepNumber,
      };
}

final class OnboardingSkippedEvent extends AnalyticsEvent {
  const OnboardingSkippedEvent({required this.stepNumber});
  final int stepNumber;
  @override
  String get eventName => 'onboarding_skipped';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {AnalyticsKeys.stepNumber: stepNumber};
}

final class OnboardingCompletedEvent extends AnalyticsEvent {
  const OnboardingCompletedEvent();
  @override
  String get eventName => 'onboarding_completed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  String? get dedupKey => 'onboarding_completed';
  @override
  Map<String, Object?> get properties => {};
}

// ── Home launch campaign (LAUNCHBANNER+ §27) ─────────────────────────────────
//
// Eight events covering the full funnel: eligible -> impression -> outcome,
// plus suppression and failure. None carries a customer identifier. `platform`
// and `app_version` are injected by AnalyticsContextProvider and must NOT be
// declared here, or every event would carry them twice.

/// The campaign passed every eligibility rule and will be scheduled.
///
/// Emitted BEFORE presentation, so `eligible` minus `impression` is exactly the
/// number of presentations cancelled during the §8 delay.
final class HomeLaunchBannerEligibleEvent extends AnalyticsEvent {
  const HomeLaunchBannerEligibleEvent({
    required this.campaignId,
    required this.campaignVersion,
  });
  final String campaignId;
  final String campaignVersion;
  @override
  String get eventName => 'home_launch_banner_eligible';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  String? get dedupKey =>
      'launch_banner_eligible:${campaignId}_$campaignVersion';
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignId: campaignId,
        AnalyticsKeys.campaignVersion: campaignVersion,
      };
}

/// A VERIFIED impression — the campaign actually rendered (§28).
///
/// [impressionNumber] is 1-based and capped by the campaign's own limit, so it
/// stays low-cardinality without bucketing.
final class HomeLaunchBannerImpressionEvent extends AnalyticsEvent {
  const HomeLaunchBannerImpressionEvent({
    required this.campaignId,
    required this.campaignVersion,
    required this.impressionNumber,
  });
  final String campaignId;
  final String campaignVersion;
  final int impressionNumber;
  @override
  String get eventName => 'home_launch_banner_impression';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  /// Deduped per impression NUMBER, not per campaign: three impressions are
  /// three legitimate events, but a rebuild during one must not double-count.
  @override
  String? get dedupKey =>
      'launch_banner_impression:${campaignId}_${campaignVersion}_$impressionNumber';
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignId: campaignId,
        AnalyticsKeys.campaignVersion: campaignVersion,
        AnalyticsKeys.impressionNumber: impressionNumber,
      };
}

/// The customer chose the primary CTA — the campaign converted.
final class HomeLaunchBannerCtaSelectedEvent extends AnalyticsEvent {
  const HomeLaunchBannerCtaSelectedEvent({
    required this.campaignId,
    required this.campaignVersion,
    required this.impressionNumber,
  });
  final String campaignId;
  final String campaignVersion;
  final int impressionNumber;
  @override
  String get eventName => 'home_launch_banner_cta_selected';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignId: campaignId,
        AnalyticsKeys.campaignVersion: campaignVersion,
        AnalyticsKeys.impressionNumber: impressionNumber,
      };
}

/// "Remind me later" — a deferral, not a rejection.
final class HomeLaunchBannerRemindLaterEvent extends AnalyticsEvent {
  const HomeLaunchBannerRemindLaterEvent({
    required this.campaignId,
    required this.campaignVersion,
    required this.impressionNumber,
  });
  final String campaignId;
  final String campaignVersion;
  final int impressionNumber;
  @override
  String get eventName => 'home_launch_banner_remind_later';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignId: campaignId,
        AnalyticsKeys.campaignVersion: campaignVersion,
        AnalyticsKeys.impressionNumber: impressionNumber,
      };
}

/// Explicit Close — a permanent rejection of this campaign version.
final class HomeLaunchBannerClosedEvent extends AnalyticsEvent {
  const HomeLaunchBannerClosedEvent({
    required this.campaignId,
    required this.campaignVersion,
    required this.impressionNumber,
  });
  final String campaignId;
  final String campaignVersion;
  final int impressionNumber;
  @override
  String get eventName => 'home_launch_banner_closed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignId: campaignId,
        AnalyticsKeys.campaignVersion: campaignVersion,
        AnalyticsKeys.impressionNumber: impressionNumber,
      };
}

/// System Back or barrier dismissal.
///
/// Reported separately from Close because it means something different: the
/// customer left without deciding, and the campaign returns after the cooldown.
/// Merging the two would overstate genuine rejection.
final class HomeLaunchBannerDismissedByBackEvent extends AnalyticsEvent {
  const HomeLaunchBannerDismissedByBackEvent({
    required this.campaignId,
    required this.campaignVersion,
    required this.impressionNumber,
  });
  final String campaignId;
  final String campaignVersion;
  final int impressionNumber;
  @override
  String get eventName => 'home_launch_banner_dismissed_by_back';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignId: campaignId,
        AnalyticsKeys.campaignVersion: campaignVersion,
        AnalyticsKeys.impressionNumber: impressionNumber,
      };
}

/// The campaign was evaluated and not shown. [suppressionReason] comes from the
/// closed CampaignSuppression vocabulary, which keeps the funnel readable.
final class HomeLaunchBannerSuppressedEvent extends AnalyticsEvent {
  const HomeLaunchBannerSuppressedEvent({
    required this.campaignId,
    required this.campaignVersion,
    required this.suppressionReason,
  });
  final String campaignId;
  final String campaignVersion;
  final String suppressionReason;
  @override
  String get eventName => 'home_launch_banner_suppressed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  /// Deduped per reason: the same suppression re-evaluated on every Home
  /// rebuild would otherwise flood the funnel with identical rows.
  @override
  String? get dedupKey => 'launch_banner_suppressed:$suppressionReason';
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignId: campaignId,
        AnalyticsKeys.campaignVersion: campaignVersion,
        AnalyticsKeys.suppressionReason: suppressionReason,
      };
}

/// Presentation was attempted but the campaign could not render (§29).
///
/// Distinct from suppression: suppression is a decision, this is a failure —
/// and it must never increment the impression count.
final class HomeLaunchBannerDisplayFailedEvent extends AnalyticsEvent {
  const HomeLaunchBannerDisplayFailedEvent({
    required this.campaignId,
    required this.campaignVersion,
    required this.result,
  });
  final String campaignId;
  final String campaignVersion;
  final String result;
  @override
  String get eventName => 'home_launch_banner_display_failed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignId: campaignId,
        AnalyticsKeys.campaignVersion: campaignVersion,
        AnalyticsKeys.result: result,
      };
}
