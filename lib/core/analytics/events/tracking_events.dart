import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

// NOTE: No coordinates, addresses, routes, or provider identity in any event.

final class TrackingOpenedEvent extends AnalyticsEvent {
  const TrackingOpenedEvent(
      {required this.trackingStatusCategory, required this.entrySource});
  final String trackingStatusCategory;
  final String entrySource;
  @override String get eventName => 'tracking_opened';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.trackingStatusCategory: trackingStatusCategory,
        AnalyticsKeys.entrySource: entrySource,
      };
}

final class TrackingSnapshotLoadedEvent extends AnalyticsEvent {
  const TrackingSnapshotLoadedEvent(
      {required this.freshnessCategory, required this.trackingStatusCategory});
  final String freshnessCategory;
  final String trackingStatusCategory;
  @override String get eventName => 'tracking_snapshot_loaded';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {
        AnalyticsKeys.freshnessCategory: freshnessCategory,
        AnalyticsKeys.trackingStatusCategory: trackingStatusCategory,
      };
}

final class TrackingLiveConnectedEvent extends AnalyticsEvent {
  const TrackingLiveConnectedEvent();
  @override String get eventName => 'tracking_live_connected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'tracking_live_connected';
  @override Map<String, Object?> get properties => {};
}

final class TrackingReconnectingEvent extends AnalyticsEvent {
  const TrackingReconnectingEvent();
  @override String get eventName => 'tracking_reconnecting';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override String? get dedupKey => 'tracking_reconnecting';
  @override Map<String, Object?> get properties => {};
}

final class TrackingStaleStateShownEvent extends AnalyticsEvent {
  const TrackingStaleStateShownEvent({required this.freshnessCategory});
  final String freshnessCategory;
  @override String get eventName => 'tracking_stale_state_shown';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties =>
      {AnalyticsKeys.freshnessCategory: freshnessCategory};
}

final class TrackingMessageSelectedEvent extends AnalyticsEvent {
  const TrackingMessageSelectedEvent();
  @override String get eventName => 'tracking_message_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {};
}

final class TrackingSupportSelectedEvent extends AnalyticsEvent {
  const TrackingSupportSelectedEvent();
  @override String get eventName => 'tracking_support_selected';
  @override ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override Map<String, Object?> get properties => {};
}
