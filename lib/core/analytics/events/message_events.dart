import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

final class MessagesOpenedEvent extends AnalyticsEvent {
  const MessagesOpenedEvent();
  @override String get eventName => 'messages_opened';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'messages_opened';
  @override Map<String, Object?> get properties => {};
}

final class ConversationOpenedEvent extends AnalyticsEvent {
  const ConversationOpenedEvent(
      {required this.bookingStatusCategory, required this.entrySource});
  final String bookingStatusCategory;
  final String entrySource;
  @override String get eventName => 'conversation_opened';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.bookingStatusCategory: bookingStatusCategory,
        AnalyticsKeys.entrySource: entrySource,
      };
}

// IMPORTANT: message body is NEVER included in analytics.
final class MessageSendStartedEvent extends AnalyticsEvent {
  const MessageSendStartedEvent({required this.contentType});
  final String contentType; // 'text' | 'attachment'
  @override String get eventName => 'message_send_started';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.contentType: contentType};
}

final class MessageSendSucceededEvent extends AnalyticsEvent {
  const MessageSendSucceededEvent({required this.contentType});
  final String contentType;
  @override String get eventName => 'message_send_succeeded';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.contentType: contentType};
}

final class MessageSendFailedEvent extends AnalyticsEvent {
  const MessageSendFailedEvent(
      {required this.contentType, required this.failureCode});
  final String contentType;
  final String failureCode;
  @override String get eventName => 'message_send_failed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.contentType: contentType,
        AnalyticsKeys.failureCode: failureCode,
      };
}

final class MessageRetrySelectedEvent extends AnalyticsEvent {
  const MessageRetrySelectedEvent();
  @override String get eventName => 'message_retry_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {};
}

final class ConversationMarkedReadEvent extends AnalyticsEvent {
  const ConversationMarkedReadEvent();
  @override String get eventName => 'conversation_marked_read';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {};
}
