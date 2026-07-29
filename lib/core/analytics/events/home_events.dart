import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

final class HomeViewedEvent extends AnalyticsEvent {
  const HomeViewedEvent({required this.accountState});
  final String accountState;
  @override String get eventName => 'home_viewed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.accountState: accountState};
}

final class HomeSearchSelectedEvent extends AnalyticsEvent {
  const HomeSearchSelectedEvent();
  @override String get eventName => 'home_search_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {};
}

final class HomeCategorySelectedEvent extends AnalyticsEvent {
  const HomeCategorySelectedEvent({required this.categoryKey});
  final String categoryKey;
  @override String get eventName => 'home_category_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.categoryKey: categoryKey};
}

final class HomeServiceSelectedEvent extends AnalyticsEvent {
  const HomeServiceSelectedEvent(
      {required this.serviceCategory, required this.surface});
  final String serviceCategory;
  final String surface;
  @override String get eventName => 'home_service_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.surface: surface,
      };
}

final class HomeActiveBookingSelectedEvent extends AnalyticsEvent {
  const HomeActiveBookingSelectedEvent(
      {required this.bookingStatusCategory});
  final String bookingStatusCategory;
  @override String get eventName => 'home_active_booking_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.bookingStatusCategory: bookingStatusCategory};
}

final class HomePromotionSelectedEvent extends AnalyticsEvent {
  const HomePromotionSelectedEvent({required this.promotionCategory});
  final String promotionCategory;
  @override String get eventName => 'home_promotion_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.promotionCategory: promotionCategory};
}

final class OnboardingStartedEvent extends AnalyticsEvent {
  const OnboardingStartedEvent({required this.entrySource});
  final String entrySource;
  @override String get eventName => 'onboarding_started';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.entrySource: entrySource};
}

final class OnboardingCardViewedEvent extends AnalyticsEvent {
  const OnboardingCardViewedEvent(
      {required this.cardKey, required this.stepNumber});
  final String cardKey;
  final int stepNumber;
  @override String get eventName => 'onboarding_card_viewed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.cardKey: cardKey,
        AnalyticsKeys.stepNumber: stepNumber,
      };
}

final class OnboardingSkippedEvent extends AnalyticsEvent {
  const OnboardingSkippedEvent({required this.stepNumber});
  final int stepNumber;
  @override String get eventName => 'onboarding_skipped';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.stepNumber: stepNumber};
}

final class OnboardingCompletedEvent extends AnalyticsEvent {
  const OnboardingCompletedEvent();
  @override String get eventName => 'onboarding_completed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'onboarding_completed';
  @override Map<String, Object?> get properties => {};
}
