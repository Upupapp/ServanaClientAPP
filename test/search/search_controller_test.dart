import 'package:client/modules/search/application/search_controller.dart';
import 'package:client/modules/search/application/search_sort.dart';
import 'package:client/modules/search/data/search_repository.dart';
import 'package:client/modules/search/domain/search_hit.dart';
import 'package:client/modules/search/domain/search_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reproduces the compatibility transport's matching, so these tests exercise
/// the controller rather than a transport.
SearchResults _matchIn(List<SearchResult> catalog, String term) {
  final needle = term.trim().toLowerCase();
  return SearchResults(
    query: needle,
    hits: catalog
        .where((r) => r.searchHaystack.contains(needle))
        .map((r) => SearchHit(
              ref: 'service:${r.serviceId}',
              type: SearchEntityType.service,
              id: r.serviceId,
              name: r.serviceName,
              context: r.hierarchyPath,
              bookable: r.bookable,
              basePrice: r.minPricePesos,
              categoryId: r.categoryId,
              subcategoryId: r.subcategoryId,
            ))
        .toList(),
  );
}

class _FakeSearchRepository extends Fake implements SearchRepository {
  _FakeSearchRepository(this.catalog);
  final List<SearchResult> catalog;

  @override
  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async =>
      catalog;

  @override
  Future<SearchResults> search(String term, {int limit = 50}) async =>
      _matchIn(catalog, term);

  @override
  void clearCache() {}
}

class _ThrowingSearchRepository extends Fake implements SearchRepository {
  @override
  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async =>
      throw Exception('network error');

  @override
  Future<SearchResults> search(String term, {int limit = 50}) async =>
      throw Exception('network error');

  @override
  void clearCache() {}
}

/// Answers different terms at different speeds, so out-of-order completion can
/// be reproduced deterministically.
class _SlowSearchRepository extends Fake implements SearchRepository {
  _SlowSearchRepository(this.catalog, this.delays);

  final List<SearchResult> catalog;
  final Map<String, Duration> delays;

  @override
  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async =>
      catalog;

  @override
  Future<SearchResults> search(String term, {int limit = 50}) async {
    await Future<void>.delayed(delays[term] ?? Duration.zero);
    return _matchIn(catalog, term);
  }

  @override
  void clearCache() {}
}

/// Fails queries until switched off, so recovery after an error is testable.
class _PartlyThrowingRepository extends Fake implements SearchRepository {
  _PartlyThrowingRepository(this.catalog);

  final List<SearchResult> catalog;
  bool shouldThrow = true;

  @override
  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async =>
      catalog;

  @override
  Future<SearchResults> search(String term, {int limit = 50}) async {
    if (shouldThrow) throw Exception('network error');
    return _matchIn(catalog, term);
  }

  @override
  void clearCache() {}
}

class _CountingSearchRepository extends Fake implements SearchRepository {
  int callCount = 0;
  List<SearchResult> catalog;
  bool _cleared = false;

  _CountingSearchRepository(this.catalog);

  @override
  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && !_cleared && callCount > 0) return catalog;
    callCount++;
    _cleared = false;
    return catalog;
  }

  @override
  Future<SearchResults> search(String term, {int limit = 50}) async =>
      _matchIn(catalog, term);

  @override
  void clearCache() => _cleared = true;
}

// Canonical fixtures: `serviceId` is `services.id`, `categoryId` is
// `catalog_categories.id`. Both are ints — the app-side ServiceCategoryId enum
// is gone from search entirely.
const _kAircon = SearchResult(
  serviceId: 130,
  serviceName: 'Aircon Cleaning',
  subcategoryId: 2,
  subcategoryName: 'Cleaning',
  categoryId: 2,
  categoryName: 'Home Services',
  minPricePesos: 700,
  maxPricePesos: 1200,
  bookable: true,
);

const _kMassage = SearchResult(
  serviceId: 44,
  serviceName: 'Swedish Massage',
  subcategoryId: 9,
  subcategoryName: 'Massage',
  categoryId: 3,
  categoryName: 'Personal Care',
  minPricePesos: 500,
  maxPricePesos: 800,
  bookable: true,
);

SearchController _makeCtrl([List<SearchResult>? catalog]) => SearchController(
    repository: _FakeSearchRepository(catalog ?? [_kAircon, _kMassage]));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SearchController', () {
    test('init() transitions state to ready', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      expect(ctrl.state, SearchLoadState.ready);
    });

    test('init() returns all results when no query is set', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      expect(ctrl.results, hasLength(2));
    });

    test('init() resets query, category filter, and sort on each call',
        () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.onQueryChanged('aircon');
      ctrl.setCategoryFilter(2);
      ctrl.setSort(SearchSort.priceHighLow);
      await ctrl.init();
      expect(ctrl.query, '');
      expect(ctrl.categoryFilter, isNull);
      expect(ctrl.sort, SearchSort.recommended);
    });

    test('onQueryChanged() filters results after debounce', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.onQueryChanged('aircon');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(ctrl.results, hasLength(1));
      expect(ctrl.results.first.serviceName, 'Aircon Cleaning');
    });

    test('onQueryChanged() with empty string returns all results', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.onQueryChanged('aircon');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      ctrl.onQueryChanged('');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(ctrl.results, hasLength(2));
    });

    test('a slow earlier query cannot repaint over a newer one', () async {
      // Search-as-you-type issues overlapping requests and the network does not
      // promise to answer them in order. Without the sequence guard, the slow
      // answer to "aircon" lands last and the screen shows aircon results for a
      // box that reads "massage".
      final repo = _SlowSearchRepository([
        _kAircon,
        _kMassage
      ], {
        'aircon': const Duration(milliseconds: 120),
        'massage': const Duration(milliseconds: 10),
      });
      final ctrl = SearchController(repository: repo);
      await ctrl.init();

      ctrl.onQuerySubmitted('aircon');
      ctrl.onQuerySubmitted('massage');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(ctrl.results, hasLength(1));
      expect(ctrl.results.first.serviceName, 'Swedish Massage');
    });

    test('a failed query is an error state, not an empty result', () async {
      final ctrl = SearchController(
          repository: _PartlyThrowingRepository([_kAircon, _kMassage]));
      await ctrl.init();

      ctrl.onQuerySubmitted('aircon');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // "No results" would be a claim about the catalog that was never made.
      expect(ctrl.state, SearchLoadState.error);
      expect(ctrl.isEmpty, isFalse);
    });

    test('typing again after a failure is not blocked by the error state',
        () async {
      final repo = _PartlyThrowingRepository([_kAircon, _kMassage]);
      final ctrl = SearchController(repository: repo);
      await ctrl.init();

      ctrl.onQuerySubmitted('aircon');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(ctrl.state, SearchLoadState.error);

      repo.shouldThrow = false;
      ctrl.onQuerySubmitted('massage');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // A text field that stops working after one failed request strands the
      // customer on a retry button.
      expect(ctrl.state, SearchLoadState.ready);
      expect(ctrl.results.first.serviceName, 'Swedish Massage');
    });

    test('clearQuery() resets query and category filter', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.onQueryChanged('aircon');
      ctrl.setCategoryFilter(2);
      ctrl.clearQuery();
      expect(ctrl.query, '');
      expect(ctrl.categoryFilter, isNull);
      expect(ctrl.hasQuery, isFalse);
    });

    test('setCategoryFilter() filters to matching category', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.setCategoryFilter(3);
      expect(ctrl.results, hasLength(1));
      expect(ctrl.results.first.categoryId, 3);
    });

    test('setCategoryFilter() toggles — tapping same ID twice clears filter',
        () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.setCategoryFilter(2);
      expect(ctrl.categoryFilter, 2);
      ctrl.setCategoryFilter(2);
      expect(ctrl.categoryFilter, isNull);
      expect(ctrl.results, hasLength(2));
    });

    test('setSort(priceLowHigh) orders results by ascending min price',
        () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.setSort(SearchSort.priceLowHigh);
      final prices = ctrl.results.map((r) => r.minPricePesos).toList();
      expect(prices.first, lessThanOrEqualTo(prices.last));
      expect(prices.first, 500);
    });

    test('setSort(priceHighLow) orders results by descending min price',
        () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.setSort(SearchSort.priceHighLow);
      final prices = ctrl.results.map((r) => r.minPricePesos).toList();
      expect(prices.first, greaterThanOrEqualTo(prices.last));
      expect(prices.first, 700);
    });

    test('selectHistory() persists term to history list', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.selectHistory('massage');
      expect(ctrl.history, contains('massage'));
    });

    test('selectHistory() deduplicates — recent term moves to front', () async {
      SharedPreferences.setMockInitialValues({
        'search_recent_terms': ['aircon', 'massage'],
      });
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.selectHistory('aircon');
      expect(ctrl.history.first, 'aircon');
      expect(ctrl.history, hasLength(2));
    });

    test('removeHistory() removes specific term', () async {
      SharedPreferences.setMockInitialValues({
        'search_recent_terms': ['massage', 'aircon'],
      });
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.removeHistory('massage');
      expect(ctrl.history, isNot(contains('massage')));
      expect(ctrl.history, contains('aircon'));
    });

    test('isEmpty is true when query matches nothing', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.onQueryChanged('xyz_will_never_match');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(ctrl.isEmpty, isTrue);
    });

    test('hasQuery is true for non-empty query', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.onQueryChanged('aircon');
      expect(ctrl.hasQuery, isTrue);
    });

    test('init() notifies listeners exactly once for successful load',
        () async {
      final ctrl = _makeCtrl();
      var notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      await ctrl.init();
      // init() notifies after history load, then after catalog load
      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('clearHistoryOnLogout() removes all persisted search terms', () async {
      SharedPreferences.setMockInitialValues({
        'search_recent_terms': ['aircon', 'massage'],
      });
      await SearchController.clearHistoryOnLogout();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('search_recent_terms'), isNull);
    });

    test('init() transitions to error state when repository throws', () async {
      final ctrl = SearchController(repository: _ThrowingSearchRepository());
      await ctrl.init();
      expect(ctrl.state, SearchLoadState.error);
      expect(ctrl.error, isNotNull);
      expect(ctrl.results, isEmpty);
    });

    test('refresh() re-fetches even when state is already ready', () async {
      final repo = _CountingSearchRepository([_kAircon]);
      final ctrl = SearchController(repository: repo);
      await ctrl.init();
      expect(repo.callCount, 1);
      await ctrl.refresh();
      expect(repo.callCount, 2);
    });

    test('SearchResult.priceDisplay formats correctly', () {
      expect(
        const SearchResult(
          serviceId: 130,
          serviceName: 'Aircon Cleaning',
          subcategoryId: 2,
          subcategoryName: 'Cleaning',
          categoryId: 2,
          categoryName: 'Home Services',
          minPricePesos: 700,
          maxPricePesos: 700,
          bookable: true,
        ).priceDisplay,
        '₱700',
      );
      expect(
        const SearchResult(
          serviceId: 130,
          serviceName: 'Aircon Cleaning',
          subcategoryId: 2,
          subcategoryName: 'Cleaning',
          categoryId: 2,
          categoryName: 'Home Services',
          minPricePesos: 500,
          maxPricePesos: 900,
          bookable: true,
        ).priceDisplay,
        'From ₱500',
      );
      expect(
        const SearchResult(
          serviceId: 130,
          serviceName: 'Aircon Cleaning',
          subcategoryId: 2,
          subcategoryName: 'Cleaning',
          categoryId: 2,
          categoryName: 'Home Services',
          minPricePesos: 0,
          maxPricePesos: 0,
          bookable: true,
        ).priceDisplay,
        'Get a quote',
      );
    });
  });

  // The `categoryIdFromService` group was removed with the function it tested.
  // It mapped a legacy family id (or, failing that, a regex over its name) onto
  // a hardcoded app-side category enum, and anything it did not recognise was
  // dropped from the index entirely — which is how Electrical Services became
  // unsearchable. Search now carries the backend's own category id.
}
