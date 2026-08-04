import 'package:client/core/analytics/domain/analytics_consent.dart';
import 'package:client/core/analytics/domain/analytics_event.dart';
import 'package:client/core/analytics/domain/analytics_property.dart';

/// Category campaign popup funnel.
///
/// Five events: verified impression, then one of three outcomes, plus a
/// display failure. `platform` and `app_version` are injected by
/// [AnalyticsContextProvider] and must NOT be declared here, or every event
/// would carry them twice.
///
/// None carries a customer identifier, a booking id, an address or any search
/// text. `campaign_key` names the creative and `category_key` the category —
/// both fixed, low-cardinality strings from
/// [CategoryCampaignRegistry].

/// A VERIFIED impression: the banner (or its native fallback) actually painted.
///
/// Deliberately not emitted when the modal is scheduled. Counting at schedule
/// time would report views of a popup the customer never saw — for instance
/// when navigation cancels the presentation mid-animation.
final class CategoryCampaignOpenedEvent extends AnalyticsEvent {
  const CategoryCampaignOpenedEvent({
    required this.campaignKey,
    required this.categoryKey,
    required this.entrySource,
  });

  final String campaignKey;
  final String categoryKey;

  /// Where the tap came from — `home_category_grid` today.
  final String entrySource;

  @override
  String get eventName => 'category_campaign_opened';

  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  /// One impression per creative per 2-second window. Guards against a rebuild
  /// double-firing; a genuine second viewing is far more than 2s later.
  @override
  String? get dedupKey => 'category_campaign_opened:$campaignKey';

  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignKey: campaignKey,
        AnalyticsKeys.categoryKey: categoryKey,
        AnalyticsKeys.entrySource: entrySource,
      };
}

/// The customer tapped the artwork's call to action.
final class CategoryCampaignCtaSelectedEvent extends AnalyticsEvent {
  const CategoryCampaignCtaSelectedEvent({
    required this.campaignKey,
    required this.categoryKey,
  });

  final String campaignKey;
  final String categoryKey;

  @override
  String get eventName => 'category_campaign_cta_selected';

  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignKey: campaignKey,
        AnalyticsKeys.categoryKey: categoryKey,
      };
}

/// The popup was dismissed without the CTA.
///
/// [dismissalMethod] is one of a closed set — `close_button`, `back`,
/// `barrier` — so the property stays low-cardinality and a funnel can tell a
/// deliberate close from an accidental Back.
final class CategoryCampaignDismissedEvent extends AnalyticsEvent {
  const CategoryCampaignDismissedEvent({
    required this.campaignKey,
    required this.categoryKey,
    required this.dismissalMethod,
  });

  final String campaignKey;
  final String categoryKey;
  final String dismissalMethod;

  @override
  String get eventName => 'category_campaign_dismissed';

  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignKey: campaignKey,
        AnalyticsKeys.categoryKey: categoryKey,
        AnalyticsKeys.dismissalMethod: dismissalMethod,
      };
}

/// The artwork failed to load and the native fallback was shown instead.
///
/// Worth its own event: a creative that silently fails to decode on some
/// devices would otherwise look identical to one nobody engaged with.
final class CategoryCampaignDisplayFailedEvent extends AnalyticsEvent {
  const CategoryCampaignDisplayFailedEvent({
    required this.campaignKey,
    required this.categoryKey,
  });

  final String campaignKey;
  final String categoryKey;

  @override
  String get eventName => 'category_campaign_display_failed';

  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;

  @override
  String? get dedupKey => 'category_campaign_display_failed:$campaignKey';

  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.campaignKey: campaignKey,
        AnalyticsKeys.categoryKey: categoryKey,
      };
}

/// Closed set of dismissal verbs for [CategoryCampaignDismissedEvent].
abstract final class CategoryCampaignDismissal {
  static const String closeButton = 'close_button';
  static const String back = 'back';
  static const String barrier = 'barrier';
}
