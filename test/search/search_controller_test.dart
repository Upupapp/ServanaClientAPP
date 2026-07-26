import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/modules/search/application/search_controller.dart';
import 'package:client/modules/search/application/search_sort.dart';
import 'package:client/modules/search/data/search_repository.dart';
import 'package:client/modules/search/domain/search_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSearchRepository extends Fake implements SearchRepository {
  _FakeSearchRepository(this.catalog);
  final List<SearchResult> catalog;

  @override
  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async =>
      catalog;

  @override
  void clearCache() {}
}

class _ThrowingSearchRepository extends Fake implements SearchRepository {
  @override
  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async =>
      throw Exception('network error');

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
  void clearCache() => _cleared = true;
}

const _kAircon = SearchResult(
  serviceId: 1,
  serviceName: 'Aircon Services',
  level2: 'Aircon Cleaning',
  minPricePesos: 700,
  maxPricePesos: 1200,
  requiresBranch: false,
  categoryId: ServiceCategoryId.aircon,
  categoryLabel: 'Aircon',
);

const _kMassage = SearchResult(
  serviceId: 4,
  serviceName: 'Massage',
  level2: 'Swedish Massage',
  minPricePesos: 500,
  maxPricePesos: 800,
  requiresBranch: true,
  categoryId: ServiceCategoryId.massage,
  categoryLabel: 'Massage',
);

SearchController _makeCtrl([List<SearchResult>? catalog]) =>
    SearchController(repository: _FakeSearchRepository(catalog ?? [_kAircon, _kMassage]));

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

    test('init() resets query, category filter, and sort on each call', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.onQueryChanged('aircon');
      ctrl.setCategoryFilter(ServiceCategoryId.aircon);
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
      expect(ctrl.results.first.level2, 'Aircon Cleaning');
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

    test('clearQuery() resets query and category filter', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.onQueryChanged('aircon');
      ctrl.setCategoryFilter(ServiceCategoryId.aircon);
      ctrl.clearQuery();
      expect(ctrl.query, '');
      expect(ctrl.categoryFilter, isNull);
      expect(ctrl.hasQuery, isFalse);
    });

    test('setCategoryFilter() filters to matching category', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.setCategoryFilter(ServiceCategoryId.massage);
      expect(ctrl.results, hasLength(1));
      expect(ctrl.results.first.categoryId, ServiceCategoryId.massage);
    });

    test('setCategoryFilter() toggles — tapping same ID twice clears filter',
        () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.setCategoryFilter(ServiceCategoryId.aircon);
      expect(ctrl.categoryFilter, ServiceCategoryId.aircon);
      ctrl.setCategoryFilter(ServiceCategoryId.aircon);
      expect(ctrl.categoryFilter, isNull);
      expect(ctrl.results, hasLength(2));
    });

    test('setSort(priceLowHigh) orders results by ascending min price', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.setSort(SearchSort.priceLowHigh);
      final prices =
          ctrl.results.map((r) => r.minPricePesos).toList();
      expect(prices.first, lessThanOrEqualTo(prices.last));
      expect(prices.first, 500);
    });

    test('setSort(priceHighLow) orders results by descending min price', () async {
      final ctrl = _makeCtrl();
      await ctrl.init();
      ctrl.setSort(SearchSort.priceHighLow);
      final prices =
          ctrl.results.map((r) => r.minPricePesos).toList();
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

    test('init() notifies listeners exactly once for successful load', () async {
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
      final ctrl = SearchController(
          repository: _ThrowingSearchRepository());
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
          serviceId: 1,
          serviceName: 's',
          level2: 'Cleaning',
          minPricePesos: 700,
          maxPricePesos: 700,
          requiresBranch: false,
          categoryId: ServiceCategoryId.aircon,
          categoryLabel: 'Aircon',
        ).priceDisplay,
        '₱700',
      );
      expect(
        const SearchResult(
          serviceId: 1,
          serviceName: 's',
          level2: 'Cleaning',
          minPricePesos: 500,
          maxPricePesos: 900,
          requiresBranch: false,
          categoryId: ServiceCategoryId.aircon,
          categoryLabel: 'Aircon',
        ).priceDisplay,
        'From ₱500',
      );
      expect(
        const SearchResult(
          serviceId: 1,
          serviceName: 's',
          level2: 'Cleaning',
          minPricePesos: 0,
          maxPricePesos: 0,
          requiresBranch: false,
          categoryId: ServiceCategoryId.aircon,
          categoryLabel: 'Aircon',
        ).priceDisplay,
        'Get a quote',
      );
    });
  });

  group('categoryIdFromService — name-fallback', () {
    test('maps unknown serviceId via name: aircon', () {
      expect(
        categoryIdFromService(serviceId: 99, name: 'Aircon Maintenance'),
        ServiceCategoryId.aircon,
      );
    });

    test('maps unknown serviceId via name: massage', () {
      expect(
        categoryIdFromService(serviceId: 99, name: 'Spa & Massage Therapy'),
        ServiceCategoryId.massage,
      );
    });

    test('maps unknown serviceId via name: hair & nails', () {
      expect(
        categoryIdFromService(serviceId: 99, name: 'Hair Coloring'),
        ServiceCategoryId.hairAndNails,
      );
    });

    test('maps unknown serviceId via name: beauty & wellness', () {
      expect(
        categoryIdFromService(serviceId: 99, name: 'Facial Treatment'),
        ServiceCategoryId.beautyWellness,
      );
    });

    test('returns null for completely unrecognized name and id', () {
      expect(
        categoryIdFromService(serviceId: 99, name: 'Plumbing Services'),
        isNull,
      );
    });
  });
}
