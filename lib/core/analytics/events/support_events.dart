import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

// NOTE: No ticket text, descriptions, reply content, or evidence in any event.

final class SupportOpenedEvent extends AnalyticsEvent {
  const SupportOpenedEvent({required this.entrySource});
  final String entrySource;
  @override
  String get eventName => 'support_opened';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.entrySource: entrySource};
}

final class SupportCategorySelectedEvent extends AnalyticsEvent {
  const SupportCategorySelectedEvent({required this.supportCategory});
  final String supportCategory;
  @override
  String get eventName => 'support_category_selected';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.supportCategory: supportCategory};
}

final class SupportTicketStartedEvent extends AnalyticsEvent {
  const SupportTicketStartedEvent({required this.supportCategory});
  final String supportCategory;
  @override
  String get eventName => 'support_ticket_started';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.supportCategory: supportCategory};
}

final class SupportTicketSubmittedEvent extends AnalyticsEvent {
  const SupportTicketSubmittedEvent({required this.supportCategory});
  final String supportCategory;
  @override
  String get eventName => 'support_ticket_submitted';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.supportCategory: supportCategory};
}

final class SupportTicketFailedEvent extends AnalyticsEvent {
  const SupportTicketFailedEvent(
      {required this.supportCategory, required this.failureCode});
  final String supportCategory;
  final String failureCode;
  @override
  String get eventName => 'support_ticket_failed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.supportCategory: supportCategory,
        AnalyticsKeys.failureCode: failureCode,
      };
}

final class SupportTicketOpenedEvent extends AnalyticsEvent {
  const SupportTicketOpenedEvent({required this.supportCategory});
  final String supportCategory;
  @override
  String get eventName => 'support_ticket_opened';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.supportCategory: supportCategory};
}

final class SupportReplySucceededEvent extends AnalyticsEvent {
  const SupportReplySucceededEvent();
  @override
  String get eventName => 'support_reply_succeeded';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {};
}

final class SupportTicketClosedEvent extends AnalyticsEvent {
  const SupportTicketClosedEvent();
  @override
  String get eventName => 'support_ticket_closed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {};
}

final class SupportTicketReopenedEvent extends AnalyticsEvent {
  const SupportTicketReopenedEvent();
  @override
  String get eventName => 'support_ticket_reopened';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {};
}

// Safety analytics — minimal by design; no incident details
final class SafetyEntryOpenedEvent extends AnalyticsEvent {
  const SafetyEntryOpenedEvent();
  @override
  String get eventName => 'safety_entry_opened';
  @override
  ConsentCategory get consentCategory => ConsentCategory.essential;
  @override
  Map<String, Object?> get properties => {};
}

final class SafetySubmissionAttemptedEvent extends AnalyticsEvent {
  const SafetySubmissionAttemptedEvent();
  @override
  String get eventName => 'safety_submission_attempted';
  @override
  ConsentCategory get consentCategory => ConsentCategory.essential;
  @override
  Map<String, Object?> get properties => {};
}

final class SafetySubmissionSucceededEvent extends AnalyticsEvent {
  const SafetySubmissionSucceededEvent();
  @override
  String get eventName => 'safety_submission_succeeded';
  @override
  ConsentCategory get consentCategory => ConsentCategory.essential;
  @override
  String? get dedupKey => 'safety_submission_succeeded';
  @override
  Map<String, Object?> get properties => {};
}
