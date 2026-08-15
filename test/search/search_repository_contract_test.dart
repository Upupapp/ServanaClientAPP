import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/catalog/data/catalog_cache.dart';
import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:client/modules/search/data/search_compatibility_data_source.dart';
import 'package:client/modules/search/data/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves one canonical `GET /api/catalog` body.
class _CatalogApi extends ServanaApiClient {
  _CatalogApi(this.response) : super(baseUrl: 'http://fake.test');

  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> getCanonicalCatalog() async => response;

  @override
  Future<Map<String, dynamic>> getCanonicalCatalogSummary() async =>
      {'status': 'success', 'data': const <String, dynamic>{}};
}

/// Never touches disk: Hive is unavailable in a plain unit test, and the
/// repository must degrade to a network-only path rather than fail.
class _NoCache extends CatalogCache {
  @override
  Future<Catalog?> read() async => null;
  @override
  Future<void> write(Catalog catalog) async {}
  @override
  Future<void> clear() async {}
}

Map<String, dynamic> _service({
  required int id,
  required String name,
  Object? basePrice,
  String status = 'active',
  bool bookable = true,
}) =>
    {
      'id': id,
      'subcategoryId': 7,
      'subcategoryName': 'Facial',
      'categoryId': 3,
      'categoryName': 'Personal Care',
      'name': name,
      'slug': 'slug-$id',
      'status': status,
      'displayOrder': 0,
      'bookable': bookable,
      'basePrice': basePrice,
      'unit': 'per session',
      'basePriceSummary': basePrice == null ? null : '₱$basePrice',
      'updatedAt': '2026-08-11T11:03:23.421Z',
    };

Map<String, dynamic> _body(List<Map<String, dynamic>> services) => {
      'status': 'success',
      'data': {
        'categories': [
          {
            'id': 3,
            'name': 'Personal Care',
            'slug': 'personal-care',
            'displayOrder': 0,
            'subcategories': [
              {
                'id': 7,
                'categoryId': 3,
                'name': 'Facial',
                'slug': 'facial',
                'displayOrder': 0,
                'services': services,
              },
            ],
          },
        ],
        'summary': {'lastUpdatedAt': '2026-08-11T11:03:23.421Z'},
      },
    };

SearchRepository _repo(Map<String, dynamic> body) => SearchRepository(
      // TAB 06 moved index-building into the compatibility transport. The
      // repository's contract is unchanged, which is what these tests assert.
      compatibility: SearchCompatibilityDataSource(
        catalog: CatalogRepository(api: _CatalogApi(body), cache: _NoCache()),
      ),
    );

void main() {
  test('indexes one entry per canonical Service, keyed on services.id',
      () async {
    final results = await _repo(_body([
      _service(id: 15, name: 'Pimple Facial', basePrice: 1500),
      _service(id: 16, name: 'Acne Facial', basePrice: 1800),
    ])).fetchCatalog();

    expect(results, hasLength(2));
    // The identity a tap routes on. Previously this was the legacy FAMILY id,
    // shared by every result in the group.
    expect(results.map((r) => r.serviceId), [15, 16]);
    expect(results.first.serviceName, 'Pimple Facial');
  });

  test('carries hierarchy context resolved from the Subcategory entity',
      () async {
    final results = await _repo(_body([
      _service(id: 15, name: 'Pimple Facial', basePrice: 1500),
    ])).fetchCatalog();

    final result = results.single;
    expect(result.subcategoryId, 7);
    expect(result.subcategoryName, 'Facial');
    expect(result.categoryId, 3);
    expect(result.hierarchyPath, 'Personal Care › Facial');
    // The regression this whole migration exists to prevent: the Subcategory
    // must never be the Service's own name.
    expect(result.subcategoryName, isNot(result.serviceName));
  });

  test('haystack matches on name, subcategory and category', () async {
    final result = (await _repo(_body([
      _service(id: 15, name: 'Pimple Facial', basePrice: 1500),
    ])).fetchCatalog())
        .single;

    expect(result.searchHaystack, contains('pimple'));
    expect(result.searchHaystack, contains('facial'));
    expect(result.searchHaystack, contains('personal care'));
  });

  test('a missing price renders as a quote, never ₱0', () async {
    final results = await _repo(_body([
      _service(id: 20, name: 'Bespoke Treatment'),
    ])).fetchCatalog();

    expect(results.single.minPricePesos, 0);
    expect(results.single.priceDisplay, 'Get a quote');
  });

  test('a non-bookable Service is indexed but flagged', () async {
    // Indexed on purpose: a customer searching for it should find it and be
    // told it is unavailable, rather than be shown nothing and conclude Servana
    // does not offer it.
    final results = await _repo(_body([
      _service(id: 21, name: 'Retired Facial', basePrice: 900, bookable: false),
    ])).fetchCatalog();

    expect(results, hasLength(1));
    expect(results.single.bookable, isFalse);
  });

  test('exposes category chips from the catalog, not a hardcoded list',
      () async {
    final repository = _repo(_body([
      _service(id: 15, name: 'Pimple Facial', basePrice: 1500),
    ]));
    expect(repository.categoryChips, isEmpty);

    await repository.fetchCatalog();

    expect(repository.categoryChips, hasLength(1));
    expect(repository.categoryChips.single.id, 3);
    expect(repository.categoryChips.single.label, 'Personal Care');
  });

  test('malformed rows are skipped rather than crashing the index', () async {
    final results = await _repo({
      'status': 'success',
      'data': {
        'categories': [
          null,
          'not a category',
          {
            'id': 3,
            'name': 'Personal Care',
            'slug': 'personal-care',
            'displayOrder': 0,
            'subcategories': [
              null,
              {
                'id': 7,
                'categoryId': 3,
                'name': 'Facial',
                'slug': 'facial',
                'displayOrder': 0,
                'services': [
                  null,
                  'not a service',
                  _service(id: 15, name: 'Pimple Facial', basePrice: 1500),
                ],
              },
            ],
          },
        ],
      },
    }).fetchCatalog();

    expect(results, hasLength(1));
    expect(results.single.serviceId, 15);
  });
}
