import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

final class CategoryRevealShownEvent extends AnalyticsEvent {
  const CategoryRevealShownEvent({required this.categoryKey});
  final String categoryKey;
  @override String get eventName => 'category_reveal_shown';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'category_reveal:$categoryKey';
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.categoryKey: categoryKey};
}

final class CategoryViewedEvent extends AnalyticsEvent {
  const CategoryViewedEvent(
      {required this.categoryKey, required this.entrySource});
  final String categoryKey;
  final String entrySource;
  @override String get eventName => 'category_viewed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.categoryKey: categoryKey,
        AnalyticsKeys.entrySource: entrySource,
      };
}

final class ServiceViewedEvent extends AnalyticsEvent {
  const ServiceViewedEvent(
      {required this.serviceCategory, required this.entrySource});
  final String serviceCategory;
  final String entrySource;
  @override String get eventName => 'service_viewed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.entrySource: entrySource,
      };
}

final class ServiceAvailabilityCheckedEvent extends AnalyticsEvent {
  const ServiceAvailabilityCheckedEvent(
      {required this.serviceCategory, required this.availabilityResult});
  final String serviceCategory;
  final String availabilityResult;
  @override String get eventName => 'service_availability_checked';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.availabilityResult: availabilityResult,
      };
}

final class BookingStartedEvent extends AnalyticsEvent {
  const BookingStartedEvent(
      {required this.serviceCategory, required this.entrySource});
  final String serviceCategory;
  final String entrySource;
  @override String get eventName => 'booking_started';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.entrySource: entrySource,
      };
}

final class BookingOptionConfirmedEvent extends AnalyticsEvent {
  const BookingOptionConfirmedEvent(
      {required this.serviceCategory, required this.optionType});
  final String serviceCategory;
  final String optionType;
  @override String get eventName => 'booking_option_confirmed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.optionType: optionType,
      };
}

final class BookingAddonsConfirmedEvent extends AnalyticsEvent {
  const BookingAddonsConfirmedEvent(
      {required this.serviceCategory, required this.addonCount});
  final String serviceCategory;
  final int addonCount;
  @override String get eventName => 'booking_addons_confirmed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.addonCount: addonCount,
      };
}

final class BookingAddressSelectedEvent extends AnalyticsEvent {
  const BookingAddressSelectedEvent(
      {required this.addressSource, required this.serviceCategory});
  final String addressSource;
  final String serviceCategory;
  @override String get eventName => 'booking_address_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.addressSource: addressSource,
        AnalyticsKeys.serviceCategory: serviceCategory,
      };
}

final class BookingScheduleSelectedEvent extends AnalyticsEvent {
  const BookingScheduleSelectedEvent(
      {required this.serviceCategory, required this.scheduleType});
  final String serviceCategory;
  final String scheduleType;
  @override String get eventName => 'booking_schedule_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.scheduleType: scheduleType,
      };
}

final class BookingQuoteRequestedEvent extends AnalyticsEvent {
  const BookingQuoteRequestedEvent({required this.serviceCategory});
  final String serviceCategory;
  @override String get eventName => 'booking_quote_requested';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.serviceCategory: serviceCategory};
}

final class BookingQuoteLoadedEvent extends AnalyticsEvent {
  const BookingQuoteLoadedEvent(
      {required this.serviceCategory,
      required this.quoteResult,
      required this.amountBand,
      required this.latencyBucket});
  final String serviceCategory;
  final String quoteResult;
  final String amountBand;
  final String latencyBucket;
  @override String get eventName => 'booking_quote_loaded';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.quoteResult: quoteResult,
        AnalyticsKeys.amountBand: amountBand,
        AnalyticsKeys.latencyBucket: latencyBucket,
      };
}

final class BookingSummaryViewedEvent extends AnalyticsEvent {
  const BookingSummaryViewedEvent({required this.serviceCategory});
  final String serviceCategory;
  @override String get eventName => 'booking_summary_viewed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.serviceCategory: serviceCategory};
}

final class BookingSubmittedEvent extends AnalyticsEvent {
  const BookingSubmittedEvent({required this.serviceCategory});
  final String serviceCategory;
  @override String get eventName => 'booking_submitted';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.serviceCategory: serviceCategory};
}

final class BookingCreatedEvent extends AnalyticsEvent {
  const BookingCreatedEvent({required this.serviceCategory});
  final String serviceCategory;
  @override String get eventName => 'booking_created';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'booking_created:$serviceCategory';
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.serviceCategory: serviceCategory};
}

final class BookingFailedEvent extends AnalyticsEvent {
  const BookingFailedEvent(
      {required this.serviceCategory, required this.failureCode});
  final String serviceCategory;
  final String failureCode;
  @override String get eventName => 'booking_failed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.failureCode: failureCode,
      };
}

final class BookingAbandonedEvent extends AnalyticsEvent {
  const BookingAbandonedEvent(
      {required this.serviceCategory, required this.step});
  final String serviceCategory;
  final String step;
  @override String get eventName => 'booking_abandoned';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.step: step,
      };
}

final class BookingDetailViewedEvent extends AnalyticsEvent {
  const BookingDetailViewedEvent({required this.bookingStatusCategory});
  final String bookingStatusCategory;
  @override String get eventName => 'booking_detail_viewed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.bookingStatusCategory: bookingStatusCategory};
}

final class BookingCancelStartedEvent extends AnalyticsEvent {
  const BookingCancelStartedEvent({required this.bookingStatusCategory});
  final String bookingStatusCategory;
  @override String get eventName => 'booking_cancel_started';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.bookingStatusCategory: bookingStatusCategory};
}

final class BookingCancelSucceededEvent extends AnalyticsEvent {
  const BookingCancelSucceededEvent();
  @override String get eventName => 'booking_cancel_succeeded';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {};
}

final class BookingRepeatStartedEvent extends AnalyticsEvent {
  const BookingRepeatStartedEvent({required this.serviceCategory});
  final String serviceCategory;
  @override String get eventName => 'booking_repeat_started';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.serviceCategory: serviceCategory};
}
