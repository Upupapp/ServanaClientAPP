import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

/// Main-navigation analytics (MOVEUPNAV+ §24).
///
/// The property allow-list is deliberately narrow: tab_key, previous_tab_key
/// and entry_source. No customer id, booking id, message content or badge
/// resource id may travel with a navigation event — a tab change is behavioural
/// telemetry, not a record of what the customer was looking at.

/// A destination the CUSTOMER chose.
///
/// Only emitted from a tap. Route restoration, deep links and notification
/// routing all change the selected branch too, and attributing those to the
/// customer would inflate engagement with movement they never made (§24, §22).
final class MainTabSelectedEvent extends AnalyticsEvent {
  const MainTabSelectedEvent({
    required this.tabKey,
    required this.previousTabKey,
  });

  final String tabKey;
  final String previousTabKey;

  @override
  String get eventName => 'main_tab_selected';

  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.tabKey: tabKey,
        AnalyticsKeys.previousTabKey: previousTabKey,
      };
}

/// The active destination was tapped again AND the branch actually popped.
///
/// A tap on a tab already at its root is not reselection — nothing happened, so
/// nothing is reported (§10).
final class MainTabReselectedEvent extends AnalyticsEvent {
  const MainTabReselectedEvent({required this.tabKey});

  final String tabKey;

  @override
  String get eventName => 'main_tab_reselected';

  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  @override
  Map<String, Object?> get properties => {AnalyticsKeys.tabKey: tabKey};
}

/// The central Book action opened the Quick Book sheet.
final class QuickBookOpenedEvent extends AnalyticsEvent {
  const QuickBookOpenedEvent({required this.entrySource});

  final String entrySource;

  @override
  String get eventName => 'quick_book_opened';

  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.entrySource: entrySource};
}
