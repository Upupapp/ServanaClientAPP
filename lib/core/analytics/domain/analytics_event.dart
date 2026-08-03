import 'analytics_consent.dart';
import 'analytics_property.dart';

// Base class for all typed analytics events.
// Features never call Firebase directly — they create an AnalyticsEvent
// and pass it to AnalyticsCoordinator.track().
abstract class AnalyticsEvent {
  const AnalyticsEvent();

  // lower_snake_case event name — stable, never renamed after production launch
  String get eventName;

  // Only allowlisted properties — no PII, no high-cardinality identifiers.
  // The privacy filter will further strip any key not on the approved list.
  Map<String, Object?> get properties;

  // Which consent category this event requires.
  ConsentCategory get consentCategory;

  // Optional deduplication key. Events with the same key fired within the
  // dedup window (default 2 seconds) are silently dropped.
  // Return null to skip deduplication for this event type.
  String? get dedupKey => null;

  @override
  String toString() => 'AnalyticsEvent($eventName)';
}

// Screen view event — emitted by ScreenAnalyticsObserver when the visible
// canonical route changes. Not emitted on widget rebuilds.
final class ScreenViewEvent extends AnalyticsEvent {
  const ScreenViewEvent({required this.screenName, this.previousScreen});

  final String screenName;
  final String? previousScreen;

  @override
  String get eventName => 'screen_view';

  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  @override
  String? get dedupKey => 'screen_view:$screenName';

  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.screenName: screenName,
        if (previousScreen != null)
          AnalyticsKeys.previousScreen: previousScreen,
      };
}

// Experiment exposure — emitted only when the customer is truly exposed
// (the variant affects visible or functional behavior on the reached screen).
final class ExperimentExposedEvent extends AnalyticsEvent {
  const ExperimentExposedEvent({
    required this.experimentKey,
    required this.variantKey,
    required this.surface,
  });

  final String experimentKey;
  final String variantKey;
  final String surface;

  @override
  String get eventName => 'experiment_exposed';

  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  @override
  String? get dedupKey => 'exp_exp:${experimentKey}_$variantKey';

  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.experimentKey: experimentKey,
        AnalyticsKeys.variantKey: variantKey,
        AnalyticsKeys.surface: surface,
      };
}

// Feature flag evaluation event — emitted only when genuinely useful.
final class FeatureFlagEvaluatedEvent extends AnalyticsEvent {
  const FeatureFlagEvaluatedEvent({
    required this.flagKey,
    required this.resolvedValue,
    required this.evaluationSource,
  });

  final String flagKey;
  final String resolvedValue;
  final String evaluationSource;

  @override
  String get eventName => 'feature_flag_evaluated';

  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  @override
  String? get dedupKey => 'flag:${flagKey}_$resolvedValue';

  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.flagKey: flagKey,
        AnalyticsKeys.resolvedValue: resolvedValue,
        AnalyticsKeys.evaluationSource: evaluationSource,
      };
}
