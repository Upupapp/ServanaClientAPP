import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

final class NotificationPermissionPromptShownEvent extends AnalyticsEvent {
  const NotificationPermissionPromptShownEvent();
  @override String get eventName => 'notification_permission_prompt_shown';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'notif_perm_prompt';
  @override Map<String, Object?> get properties => {};
}

final class NotificationPermissionGrantedEvent extends AnalyticsEvent {
  const NotificationPermissionGrantedEvent();
  @override String get eventName => 'notification_permission_granted';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'notif_perm_granted';
  @override Map<String, Object?> get properties => {};
}

final class NotificationPermissionDeniedEvent extends AnalyticsEvent {
  const NotificationPermissionDeniedEvent();
  @override String get eventName => 'notification_permission_denied';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'notif_perm_denied';
  @override Map<String, Object?> get properties => {};
}

// CLIENT_OBSERVATION: notification arrived while app was foreground.
// This is NOT a delivery confirmation — backend FCM logs are authoritative.
final class NotificationReceivedForegroundEvent extends AnalyticsEvent {
  const NotificationReceivedForegroundEvent({required this.notificationType});
  final String notificationType;
  @override String get eventName => 'notification_received_foreground';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.notificationType: notificationType};
}

// Customer tapped the notification — intentional action.
final class NotificationOpenedEvent extends AnalyticsEvent {
  const NotificationOpenedEvent(
      {required this.notificationType,
      required this.appState,
      this.routeKey});
  final String notificationType;
  final String appState; // 'foreground' | 'background' | 'terminated'
  final String? routeKey;
  @override String get eventName => 'notification_opened';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.notificationType: notificationType,
        AnalyticsKeys.appState: appState,
        if (routeKey != null) AnalyticsKeys.routeKey: routeKey,
      };
}

final class NotificationDeepLinkSucceededEvent extends AnalyticsEvent {
  const NotificationDeepLinkSucceededEvent({required this.routeKey});
  final String routeKey;
  @override String get eventName => 'notification_deep_link_succeeded';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.routeKey: routeKey};
}

final class NotificationDeepLinkFailedEvent extends AnalyticsEvent {
  const NotificationDeepLinkFailedEvent(
      {required this.routeKey, required this.failureCode});
  final String routeKey;
  final String failureCode;
  @override String get eventName => 'notification_deep_link_failed';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.routeKey: routeKey,
        AnalyticsKeys.failureCode: failureCode,
      };
}

final class NotificationMarkedReadEvent extends AnalyticsEvent {
  const NotificationMarkedReadEvent({required this.notificationType});
  final String notificationType;
  @override String get eventName => 'notification_marked_read';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.notificationType: notificationType};
}
