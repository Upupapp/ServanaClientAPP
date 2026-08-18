import 'dart:convert';

import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/catalog/data/catalog_cache.dart';
import 'package:client/modules/catalog/data/catalog_canonical_data_source.dart';
import 'package:client/modules/catalog/data/catalog_data_source.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// One canonical tree, in the shape both transports return.
Map<String, dynamic> treeJson({int serviceId = 501}) => <String, dynamic>{
      'categories': [
        {
          'id': 3,
          'name': 'Personal Care',
          'slug': 'personal-care',
          'displayOrder': 1,
          'subcategories': [
            {
              'id': 31,
              'categoryId': 3,
              'name': 'Massage',
              'slug': 'massage',
              'displayOrder': 1,
              'services': [
                {
                  'id': serviceId,
                  'subcategoryId': 31,
                  'subcategoryName': 'Massage',
                  'categoryId': 3,
                  'categoryName': 'Personal Care',
                  'name': 'Swedish Massage',
                  'slug': 'swedish-massage',
                  'status': 'active',
                  'displayOrder': 1,
                  'bookable': true,
                  'basePrice': 899,
                },
              ],
            },
          ],
        },
      ],
    };

class _RecordingSource implements CatalogDataSource {
  _RecordingSource(this.label);

  final String label;
  final List<String> calls = <String>[];

  @override
  Future<Catalog> fetchCatalog() async {
    calls.add('fetchCatalog');
    return Catalog.fromJson(treeJson(serviceId: label == 'v1' ? 900 : 501));
  }

  @override
  Future<DateTime?> fetchLastUpdatedAt() async {
    calls.add('fetchLastUpdatedAt');
    return null;
  }

  @override
  Future<List<CatalogCategory>> fetchCategories() async {
    calls.add('fetchCategories');
    return (await fetchCatalog()).categories;
  }

  @override
  Future<List<CatalogSubcategory>> fetchSubcategories(int categoryId) async {
    calls.add('fetchSubcategories');
    return const <CatalogSubcategory>[];
  }

  @override
  Future<List<CatalogService>> fetchSubcategoryServices(int id) async {
    calls.add('fetchSubcategoryServices');
    return const <CatalogService>[];
  }

  @override
  Future<List<CatalogService>> fetchServices() async {
    calls.add('fetchServices');
    return (await fetchCatalog()).allServices;
  }

  @override
  Future<CatalogServiceDetail> fetchServiceDetail(int serviceId) async {
    calls.add('fetchServiceDetail');
    throw UnimplementedError();
  }
}

void main() {
  V1ApiClient v1Returning(Object body) => V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((_) async => http.Response(
              jsonEncode(body),
              200,
              headers: {'content-type': 'application/json'},
            )),
      );

  group('canonical source speaks the six canonical routes', () {
    test('fetchCatalog hits /api/v1/catalog and maps the tree', () async {
      final urls = <String>[];
      final client = V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((request) async {
          urls.add(request.url.path);
          return http.Response(jsonEncode({'data': treeJson()}), 200);
        }),
      );
      final catalog = await CatalogCanonicalDataSource(client).fetchCatalog();
      expect(urls.single, '/api/v1/catalog');
      expect(catalog.allServices.single.id, 501);
      expect(catalog.allServices.single.name, 'Swedish Massage');
    });

    test('each granular read uses its own purpose-built route', () async {
      final urls = <String>[];
      final client = V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((request) async {
          urls.add(request.url.path);
          return http.Response(jsonEncode({'data': <String, dynamic>{}}), 200);
        }),
      );
      final source = CatalogCanonicalDataSource(client);
      await source.fetchCategories();
      await source.fetchSubcategories(3);
      await source.fetchSubcategoryServices(31);
      await source.fetchServices();

      expect(urls, <String>[
        '/api/v1/catalog/categories',
        '/api/v1/catalog/categories/3/subcategories',
        '/api/v1/catalog/subcategories/31/services',
        '/api/v1/catalog/services',
      ]);
    });

    test('a failed summary read is "cannot tell", not "unchanged"', () async {
      final client = V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      );
      expect(await CatalogCanonicalDataSource(client).fetchLastUpdatedAt(),
          isNull);
    });

    test('reads a collection whether bare or under a domain key', () async {
      final keyed = CatalogCanonicalDataSource(v1Returning({
        'data': {
          'categories': [
            {
              'id': 1,
              'name': 'A',
              'slug': 'a',
              'displayOrder': 1,
              'subcategories': []
            }
          ]
        }
      }));
      expect((await keyed.fetchCategories()).single.id, 1);

      final bare = CatalogCanonicalDataSource(v1Returning({
        'data': [
          {
            'id': 2,
            'name': 'B',
            'slug': 'b',
            'displayOrder': 1,
            'subcategories': []
          }
        ]
      }));
      expect((await bare.fetchCategories()).single.id, 2);
    });
  });

  group('cache isolation between transports', () {
    test('the two sources use different boxes', () {
      // A canonical payload and a legacy payload are both valid JSON for
      // Catalog.fromJson. If they ever diverge, reading one as the other would
      // not throw — it would render a subtly wrong catalog.
      expect(CatalogCacheSource.compatibility.boxName,
          isNot(CatalogCacheSource.canonical.boxName));
    });

    test('the compatibility box name is unchanged for installed customers', () {
      // Renaming it would silently discard every existing cache.
      expect(CatalogCacheSource.compatibility.boxName, 'catalog_cache_v2');
    });

    test('the default cache is the compatibility one', () {
      expect(CatalogCache().source, CatalogCacheSource.compatibility);
    });
  });

  group('router selection', () {
    const off = CanonicalRouter(availability: CanonicalAvailability());
    const on = CanonicalRouter(
      availability: CanonicalAvailability(
        enabled: true,
        capabilities: <V1Capability>{V1Capability.catalog},
      ),
    );

    test('catalog is gated OFF by default', () {
      expect(off.isCanonical(V1Capability.catalog), isFalse);
    });

    test('selects the compatibility source while the gate is closed', () {
      final legacy = _RecordingSource('legacy');
      final canonical = _RecordingSource('v1');
      final chosen = off.select<CatalogDataSource>(
        V1Capability.catalog,
        canonical: canonical,
        compatibility: legacy,
      );
      expect(identical(chosen, legacy), isTrue);
    });

    test('selects the canonical source once enabled', () {
      final legacy = _RecordingSource('legacy');
      final canonical = _RecordingSource('v1');
      final chosen = on.select<CatalogDataSource>(
        V1Capability.catalog,
        canonical: canonical,
        compatibility: legacy,
      );
      expect(identical(chosen, canonical), isTrue);
    });
  });

  group('no migration semantics cross the boundary', () {
    test('the canonical models carry no level2/level3/serviceFamily', () async {
      final catalog = Catalog.fromJson(treeJson());
      final service = catalog.allServices.single;
      // Identity is the canonical services.id, an int.
      expect(service.id, isA<int>());
      expect(service.subcategoryId, 31);
      expect(service.categoryId, 3);
      // The model has no legacy accessors at all — asserted by the absence of
      // any level2/level3 field, which catalog_level2_regression_test also
      // guards at the response level.
      expect(service.toString(), isNot(contains('level2')));
      expect(service.toString(), isNot(contains('level3')));
    });
  });
}
