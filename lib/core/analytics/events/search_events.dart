import '../domain/analytics_consent.dart';
import '../domain/analytics_event.dart';
import '../domain/analytics_property.dart';

final class SearchOpenedEvent extends AnalyticsEvent {
  const SearchOpenedEvent({required this.entrySource});
  final String entrySource;
  @override
  String get eventName => 'search_opened';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.entrySource: entrySource};
}

// IMPORTANT: raw query text is NEVER included. Only bucketed lengths/counts.
final class SearchSubmittedEvent extends AnalyticsEvent {
  const SearchSubmittedEvent({
    required this.queryLengthBucket,
    required this.queryTokenCountBucket,
    this.categoryFilter,
    this.sortKey,
    this.filterCount = 0,
  });
  final String queryLengthBucket;
  final String queryTokenCountBucket;
  final String? categoryFilter;
  final String? sortKey;
  final int filterCount;
  @override
  String get eventName => 'search_submitted';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.queryLengthBucket: queryLengthBucket,
        AnalyticsKeys.queryTokenCountBucket: queryTokenCountBucket,
        if (categoryFilter != null) AnalyticsKeys.categoryKey: categoryFilter,
        if (sortKey != null) AnalyticsKeys.sortKey: sortKey,
        AnalyticsKeys.filterCount: filterCount,
      };
}

final class SearchResultsLoadedEvent extends AnalyticsEvent {
  const SearchResultsLoadedEvent({
    required this.resultCountBucket,
    required this.latencyBucket,
  });
  final String resultCountBucket;
  final String latencyBucket;
  @override
  String get eventName => 'search_results_loaded';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.resultCountBucket: resultCountBucket,
        AnalyticsKeys.latencyBucket: latencyBucket,
      };
}

final class SearchZeroResultsEvent extends AnalyticsEvent {
  const SearchZeroResultsEvent({required this.queryLengthBucket});
  final String queryLengthBucket;
  @override
  String get eventName => 'search_zero_results';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.queryLengthBucket: queryLengthBucket};
}

final class SearchResultSelectedEvent extends AnalyticsEvent {
  const SearchResultSelectedEvent(
      {required this.serviceCategory, required this.positionBucket});
  final String serviceCategory;
  final String positionBucket;
  @override
  String get eventName => 'search_result_selected';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.serviceCategory: serviceCategory,
        AnalyticsKeys.positionBucket: positionBucket,
      };
}

final class SearchSuggestionSelectedEvent extends AnalyticsEvent {
  const SearchSuggestionSelectedEvent();
  @override
  String get eventName => 'search_suggestion_selected';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {};
}

final class SearchFilterAppliedEvent extends AnalyticsEvent {
  const SearchFilterAppliedEvent({required this.filterCount, this.categoryKey});
  final int filterCount;
  final String? categoryKey;
  @override
  String get eventName => 'search_filter_applied';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties => {
        AnalyticsKeys.filterCount: filterCount,
        if (categoryKey != null) AnalyticsKeys.categoryKey: categoryKey,
      };
}

final class SearchFailedEvent extends AnalyticsEvent {
  const SearchFailedEvent({required this.failureCode});
  final String failureCode;
  @override
  String get eventName => 'search_failed';
  @override
  ConsentCategory get consentCategory => ConsentCategory.analytics;
  @override
  Map<String, Object?> get properties =>
      {AnalyticsKeys.failureCode: failureCode};
}
