import 'dart:async';

import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/domain/analytics_property.dart';
import 'package:client/core/observability/performance_service.dart';
import 'package:client/core/observability/trace_name_registry.dart';
import 'package:client/core/analytics/events/search_events.dart';
import 'package:client/modules/search/application/search_sort.dart';
import 'package:client/modules/search/data/search_local_data_source.dart';
import 'package:client/modules/search/data/search_repository.dart';
import 'package:client/modules/search/domain/search_result.dart';
import 'package:flutter/foundation.dart';

enum SearchLoadState { idle, loading, ready, error }

class SearchController extends ChangeNotifier {
  SearchController({required SearchRepository repository})
      : _repository = repository;

  final SearchRepository _repository;

  String _query = '';
  SearchLoadState _state = SearchLoadState.idle;
  List<SearchResult> _allResults = [];
  List<SearchResult> _filteredResults = [];
  List<String> _history = [];
  int? _categoryFilter;
  SearchSort _sort = SearchSort.recommended;
  String? _error;
  bool _disposed = false;
  Timer? _debounce;

  String get query => _query;
  SearchLoadState get state => _state;
  List<SearchResult> get results => List.unmodifiable(_filteredResults);
  List<String> get history => List.unmodifiable(_history);

  /// Canonical `catalog_categories.id`, or null for "all".
  int? get categoryFilter => _categoryFilter;

  /// Filter chips derived from the loaded catalog, not from a list compiled
  /// into the binary. A Category an admin adds becomes filterable on the next
  /// catalog refresh rather than on the next app release.
  List<SearchCategoryChip> get categoryChips => _repository.categoryChips;
  SearchSort get sort => _sort;
  String? get error => _error;
  bool get hasQuery => _query.trim().isNotEmpty;
  bool get isEmpty =>
      _state == SearchLoadState.ready && _filteredResults.isEmpty;

  /// Called from SearchScreen.initState(). Resets session state, reloads
  /// history, and fetches the catalog (from cache if already loaded).
  Future<void> init() async {
    _query = '';
    _categoryFilter = null;
    _sort = SearchSort.recommended;
    _filteredResults = [];
    _history = await SearchLocalDataSource.loadHistory();
    if (!_disposed) notifyListeners();
    if (_state == SearchLoadState.ready) {
      _applyFilters();
      return;
    }
    await _loadCatalog();
  }

  Future<void> _loadCatalog({bool forceRefresh = false}) async {
    _state = SearchLoadState.loading;
    _error = null;
    if (!_disposed) notifyListeners();
    final sw = Stopwatch()..start();
    try {
      _allResults = await _perf(TraceNames.searchRequest,
          () async => _repository.fetchCatalog(forceRefresh: forceRefresh));
      _state = SearchLoadState.ready;
      _applyFilters();
      _track(SearchResultsLoadedEvent(
        resultCountBucket: CountBucketValues.forCount(_allResults.length),
        latencyBucket: LatencyBucketValues.forMillis(sw.elapsedMilliseconds),
      ));
    } on Exception catch (e) {
      _state = SearchLoadState.error;
      _error = e.toString();
      _track(const SearchFailedEvent(failureCode: 'network_error'));
      if (!_disposed) notifyListeners();
    }
  }

  void onQueryChanged(String query) {
    _query = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!_disposed) _applyFilters();
    });
    if (!_disposed) notifyListeners();
  }

  void onQuerySubmitted(String query) {
    _debounce?.cancel();
    _query = query;
    final term = query.trim();
    if (term.isNotEmpty) {
      _addToHistory(term);
      _track(SearchSubmittedEvent(
        queryLengthBucket: _lengthBucket(term.length),
        queryTokenCountBucket:
            CountBucketValues.forCount(term.split(RegExp(r'\s+')).length),
      ));
    }
    _applyFilters();
  }

  void clearQuery() {
    _debounce?.cancel();
    _query = '';
    _categoryFilter = null;
    _applyFilters();
  }

  void setCategoryFilter(int? id) {
    _categoryFilter = (_categoryFilter == id) ? null : id;
    _applyFilters();
  }

  void setSort(SearchSort sort) {
    _sort = sort;
    _applyFilters();
  }

  void selectHistory(String term) {
    _query = term;
    _addToHistory(term);
    _applyFilters();
  }

  void removeHistory(String term) {
    _history.remove(term);
    SearchLocalDataSource.removeTerm(term);
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() => _loadCatalog(forceRefresh: true);

  static Future<void> clearHistoryOnLogout() =>
      SearchLocalDataSource.clearHistory();

  /// Kicks off a query. Returns immediately; the result arrives through
  /// [notifyListeners] when its turn comes.
  void _applyFilters() {
    // `error` is allowed through deliberately. A failed query leaves the
    // controller in `error`, and if that state blocked the next keystroke the
    // screen would be stuck on its retry affordance with a text field that no
    // longer did anything. Only `idle` and `loading` — where there is no index
    // yet — are refused.
    if (_state != SearchLoadState.ready && _state != SearchLoadState.error) {
      return;
    }

    // Bumped even on the synchronous path, so a chip tap or a cleared box
    // invalidates a query still in flight rather than letting it repaint over
    // the newer state.
    final seq = ++_querySeq;
    final q = _query.trim();

    // No term is a browse, not a search: it is answered from the already-loaded
    // index. Kept SYNCHRONOUS on purpose — category chips and the sort control
    // both land here, and routing them through a future would add a frame of
    // latency to a filter that never leaves the device.
    if (q.isEmpty) {
      _publish(_allResults, q);
      return;
    }

    _runQuery(seq, q);
  }

  /// Applies the category filter and sort, then repaints.
  void _publish(List<SearchResult> found, String query) {
    Iterable<SearchResult> filtered = found;
    if (_categoryFilter != null) {
      filtered = filtered.where((r) => r.categoryId == _categoryFilter);
    }

    _state = SearchLoadState.ready;
    _error = null;
    _filteredResults = _sortResults(filtered.toList());
    if (query.isNotEmpty && _filteredResults.isEmpty) {
      _track(SearchZeroResultsEvent(
          queryLengthBucket: _lengthBucket(query.length)));
    }
    if (!_disposed) notifyListeners();
  }

  /// Monotonic query counter. Search-as-you-type issues overlapping requests,
  /// and the network does not promise to answer them in order — a slow answer
  /// to `fac` can land after a fast answer to `facial` and repaint the screen
  /// with results for a query the customer finished typing two keystrokes ago.
  ///
  /// Every run captures the counter it was issued under and discards itself if
  /// a newer one has started. The compatibility transport resolves too quickly
  /// to interleave in practice, but the guard belongs to the boundary rather
  /// than to whichever transport happens to be selected.
  int _querySeq = 0;

  Future<void> _runQuery(int seq, String q) async {
    final List<SearchResult> found;
    try {
      final results = await _repository.search(q);
      // Category and Subcategory hits are dropped here rather than in the data
      // layer: the transport reports everything that matched, and this screen's
      // card renders a bookable Service. They stay available on SearchResults
      // for a surface that wants to render them.
      found = results.hits
          .map(SearchResult.fromHit)
          .whereType<SearchResult>()
          .toList();
    } on Exception catch (e) {
      if (seq != _querySeq || _disposed) return;
      // A failed query is a different fact from a query that matched nothing.
      // Saying "no results" here would be a claim about the catalog that was
      // never established.
      _state = SearchLoadState.error;
      _error = e.toString();
      _track(const SearchFailedEvent(failureCode: 'network_error'));
      notifyListeners();
      return;
    }

    // A newer query started while this one was in flight, so this answer is
    // stale before it is rendered.
    if (seq != _querySeq || _disposed) return;

    _publish(found, q);
  }

  List<SearchResult> _sortResults(List<SearchResult> results) {
    switch (_sort) {
      case SearchSort.recommended:
        return results;
      case SearchSort.priceLowHigh:
        final sorted = List<SearchResult>.from(results);
        sorted.sort((a, b) => a.minPricePesos.compareTo(b.minPricePesos));
        return sorted;
      case SearchSort.priceHighLow:
        final sorted = List<SearchResult>.from(results);
        sorted.sort((a, b) => b.minPricePesos.compareTo(a.minPricePesos));
        return sorted;
    }
  }

  void _addToHistory(String term) {
    _history = [term, ..._history.where((t) => t != term)].take(10).toList();
    SearchLocalDataSource.addTerm(term);
  }

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  static String _lengthBucket(int len) {
    if (len < 5) return '<5';
    if (len < 10) return '5-9';
    if (len < 20) return '10-19';
    return '20+';
  }

  Future<T> _perf<T>(String name, Future<T> Function() fn) async {
    if (!dpLocator.isRegistered<PerformanceService>()) return fn();
    return dpLocator<PerformanceService>().traced(name, fn);
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
