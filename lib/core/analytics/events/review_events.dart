import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

// NOTE: No review text, private feedback text, or comment body in any event.

final class ReviewPromptShownEvent extends AnalyticsEvent {
  const ReviewPromptShownEvent({required this.serviceCategory});
  final String serviceCategory;
  @override
  String get eventName => 'review_prompt_shown';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  String? get dedupKey => 'review_prompt:$serviceCategory';
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.serviceCategory: serviceCategory};
}

final class ReviewStartedEvent extends AnalyticsEvent {
  const ReviewStartedEvent({required this.serviceCategory});
  final String serviceCategory;
  @override
  String get eventName => 'review_started';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.serviceCategory: serviceCategory};
}

final class ReviewRatingSelectedEvent extends AnalyticsEvent {
  const ReviewRatingSelectedEvent({required this.ratingBucket});
  final String ratingBucket; // '1' | '2' | '3' | '4' | '5'
  @override
  String get eventName => 'review_rating_selected';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.ratingBucket: ratingBucket};
}

final class ReviewSubmittedEvent extends AnalyticsEvent {
  const ReviewSubmittedEvent({
    required this.ratingBucket,
    required this.serviceCategory,
    required this.hasPublicComment,
    required this.hasPrivateFeedback,
  });
  final String ratingBucket;
  final String serviceCategory;
  final bool hasPublicComment;
  final bool hasPrivateFeedback;
  @override
  String get eventName => 'review_submitted';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  String? get dedupKey => 'review_submitted:$serviceCategory';
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.ratingBucket: ratingBucket,
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.hasPublicComment: hasPublicComment,
        AnalyticsKeys.hasPrivateFeedback: hasPrivateFeedback,
      };
}

final class ReviewSubmissionFailedEvent extends AnalyticsEvent {
  const ReviewSubmissionFailedEvent({required this.failureCode});
  final String failureCode;
  @override
  String get eventName => 'review_submission_failed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.failureCode: failureCode};
}

final class ReviewProviderResponseViewedEvent extends AnalyticsEvent {
  const ReviewProviderResponseViewedEvent();
  @override
  String get eventName => 'review_provider_response_viewed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {};
}
