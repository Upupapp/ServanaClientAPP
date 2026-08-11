/// Repository, cache and controller behaviour for the canonical catalog.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/catalog/application/catalog_controller.dart';
import 'package:client/modules/catalog/application/service_detail_controller.dart';
import 'package:client/modules/catalog/data/catalog_cache.dart';
import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _body({
  String name = 'Pimple Facial',
  String lastUpdatedAt = '2026-08-11T13:55:16.634Z',
}) =>
    {
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
                'services': [
                  {
                    'id': 15,
                    'subcategoryId': 7,
                    'subcategoryName': 'Facial',
                    'categoryId': 3,
                    'categoryName': 'Personal Care',
                    'name': name,
                    'slug': 'pimple-facial-15',
                    'status': 'active',
                    'displayOrder': 0,
                    'bookable': true,
                    'basePrice': 1500,
                    'unit': 'per session',
                    'basePriceSummary': '₱1,500 / per session',
                    'updatedAt': '2026-08-11T11:03:23.421Z',
                  },
                ],
              },
            ],
          },
        ],
        'summary': {'lastUpdatedAt': lastUpdatedAt},
      },
    };

class _Api extends ServanaApiClient {
  _Api({this.body, this.detail, this.summaryLastUpdatedAt})
      : super(baseUrl: 'http://fake.test');

  Map<String, dynamic>? body;
  Map<String, dynamic>? detail;
  String? summaryLastUpdatedAt;

  int catalogCalls = 0;
  int summaryCalls = 0;
  int detailCalls = 0;
  Object? throwOnCatalog;

  @override
  Future<Map<String, dynamic>> getCanonicalCatalog() async {
    catalogCalls++;
    if (throwOnCatalog != null) throw throwOnCatalog!;
    return body ?? _body();
  }

  @override
  Future<Map<String, dynamic>> getCanonicalCatalogSummary() async {
    summaryCalls++;
    return {
      'status': 'success',
      'data': {'lastUpdatedAt': summaryLastUpdatedAt},
    };
  }

  @override
  Future<Map<String, dynamic>> getCanonicalService({
    required int serviceId,
  }) async {
    detailCalls++;
    if (detail == null) {
      throw Exception('NOT_FOUND');
    }
    return detail!;
  }
}

/// In-memory stand-in for the Hive-backed cache.
class _MemoryCache extends CatalogCache {
  Catalog? stored;
  int writes = 0;

  @override
  Future<Catalog?> read() async => stored;

  @override
  Future<void> write(Catalog catalog) async {
    writes++;
    stored = catalog.copyWith(fetchedAt: DateTime.now().toUtc());
  }

  @override
  Future<void> clear() async => stored = null;
}

void main() {
  group('CatalogRepository', () {
    test('fetches, returns live data and writes the cache', () async {
      final api = _Api();
      final cache = _MemoryCache();
      final repo = CatalogRepository(api: api, cache: cache);

      final snapshot = await repo.load();

      expect(snapshot.fromCache, isFalse);
      expect(snapshot.catalog.serviceById(15)?.name, 'Pimple Facial');
      expect(cache.writes, 1);
      expect(api.catalogCalls, 1);
    });

    test('serves memory on a second load without touching the network',
        () async {
      final api = _Api();
      final repo = CatalogRepository(api: api, cache: _MemoryCache());

      await repo.load();
      final second = await repo.load();

      expect(second.fromCache, isTrue);
      expect(api.catalogCalls, 1, reason: 'a tab switch must not refetch');
    });

    test('forceRefresh bypasses both caches', () async {
      final api = _Api();
      final repo = CatalogRepository(api: api, cache: _MemoryCache());

      await repo.load();
      await repo.load(forceRefresh: true);

      expect(api.catalogCalls, 2);
      // Revalidation is pointless when we are refetching anyway.
      expect(api.summaryCalls, 0);
    });

    test('revalidates a fresh disk cache and reuses it when unchanged',
        () async {
      final api = _Api(summaryLastUpdatedAt: '2026-08-11T13:55:16.634Z');
      final cache = _MemoryCache()
        ..stored =
            Catalog.fromJson(Map<String, dynamic>.from(_body()['data'] as Map))
                .copyWith(fetchedAt: DateTime.now().toUtc());
      final repo = CatalogRepository(api: api, cache: cache);

      final snapshot = await repo.load();

      expect(snapshot.fromCache, isTrue);
      expect(api.summaryCalls, 1);
      expect(api.catalogCalls, 0, reason: 'unchanged catalog costs no fetch');
    });

    test('refetches when the backend reports a newer catalog', () async {
      // Exactly what happens after an admin edits a Service.
      final api = _Api(summaryLastUpdatedAt: '2026-09-01T00:00:00.000Z');
      final cache = _MemoryCache()
        ..stored =
            Catalog.fromJson(Map<String, dynamic>.from(_body()['data'] as Map))
                .copyWith(fetchedAt: DateTime.now().toUtc());
      final repo = CatalogRepository(api: api, cache: cache);

      final snapshot = await repo.load();

      expect(api.catalogCalls, 1);
      expect(snapshot.fromCache, isFalse);
    });

    test('serves the cache on failure — and never a placeholder', () async {
      final api = _Api();
      final cache = _MemoryCache();
      final repo = CatalogRepository(api: api, cache: cache);
      await repo.load();

      api.throwOnCatalog = Exception('network down');
      final snapshot = await repo.load(forceRefresh: true);

      expect(snapshot.fromCache, isTrue);
      expect(snapshot.catalog.serviceById(15), isNotNull,
          reason: 'real data fetched earlier, not fabricated');
    });

    test('throws when it fails with nothing cached (§50 no mock fallback)',
        () async {
      final api = _Api()..throwOnCatalog = Exception('network down');
      final repo = CatalogRepository(api: api, cache: _MemoryCache());

      await expectLater(repo.load(), throwsA(isA<Exception>()));
    });

    test('clearCache drops catalog state only', () async {
      final api = _Api();
      final cache = _MemoryCache();
      final repo = CatalogRepository(api: api, cache: cache);
      await repo.load();

      await repo.clearCache();

      expect(cache.stored, isNull);
      expect(repo.cachedCatalog, isNull);
      await repo.load();
      expect(api.catalogCalls, 2);
    });
  });

  group('CatalogCache freshness', () {
    final catalog =
        Catalog.fromJson(Map<String, dynamic>.from(_body()['data'] as Map));

    test('an unknown age counts as stale', () {
      expect(CatalogCache.isStale(catalog.copyWith()), isTrue);
    });

    test('fresh inside the TTL, stale outside it', () {
      final now = DateTime.utc(2026, 8, 11, 12);
      expect(
        CatalogCache.isStale(
            catalog.copyWith(fetchedAt: now.subtract(const Duration(hours: 1))),
            now: now),
        isFalse,
      );
      expect(
        CatalogCache.isStale(
            catalog.copyWith(fetchedAt: now.subtract(const Duration(hours: 7))),
            now: now),
        isTrue,
      );
    });

    test('an absent remote timestamp does not force a refetch', () {
      // Otherwise a backend that stopped sending the field would make every
      // launch refetch the whole catalog.
      expect(CatalogCache.isSupersededBy(catalog, null), isFalse);
    });
  });

  group('CatalogController', () {
    test('loads to success and exposes the hierarchy', () async {
      final controller = CatalogController(
          CatalogRepository(api: _Api(), cache: _MemoryCache()));

      await controller.load();

      expect(controller.status, CatalogLoadStatus.success);
      expect(controller.categoryById(3)?.name, 'Personal Care');
      expect(controller.serviceById(15)?.name, 'Pimple Facial');
    });

    test('reports failure when there is nothing to show', () async {
      final api = _Api()..throwOnCatalog = Exception('down');
      final controller =
          CatalogController(CatalogRepository(api: api, cache: _MemoryCache()));

      await controller.load();

      expect(controller.status, CatalogLoadStatus.failure);
      expect(controller.lastFailureDiagnostic, isNotNull);
    });

    test('a failed REFRESH keeps the rendered catalog on screen', () async {
      final api = _Api();
      final repo = CatalogRepository(api: api, cache: _MemoryCache());
      final controller = CatalogController(repo);
      await controller.load();

      api.throwOnCatalog = Exception('down');
      await controller.refresh();

      // Replacing a working catalog with an error page because a background
      // refresh failed is worse than showing slightly old data.
      expect(controller.status, CatalogLoadStatus.success);
      expect(controller.serviceById(15), isNotNull);
    });

    test('an empty catalog is empty, not a failure', () async {
      final api = _Api(body: {
        'status': 'success',
        'data': {'categories': <dynamic>[]},
      });
      final controller =
          CatalogController(CatalogRepository(api: api, cache: _MemoryCache()));

      await controller.load();

      expect(controller.status, CatalogLoadStatus.empty);
    });
  });

  group('ServiceDetailController', () {
    Map<String, dynamic> detailBody({bool available = true}) => {
          'status': 'success',
          'data': {
            'id': 15,
            'subcategoryId': 7,
            'subcategoryName': 'Facial',
            'categoryId': 3,
            'categoryName': 'Personal Care',
            'name': 'Pimple Facial',
            'slug': 'pimple-facial-15',
            'status': available ? 'active' : 'archived',
            'displayOrder': 0,
            'bookable': available,
            'basePrice': 1500,
            'available': available,
            'addons': [
              {'id': 6, 'name': 'Vitamin C', 'basePrice': 350},
            ],
          },
        };

    test('loads a bookable Service and permits booking', () async {
      final api = _Api(detail: detailBody());
      final controller = ServiceDetailController(
          CatalogRepository(api: api, cache: _MemoryCache()));

      await controller.load(15);

      expect(controller.status, ServiceDetailStatus.success);
      expect(controller.canStartBooking, isTrue);
      expect(controller.serviceId, 15);
    });

    test('an unavailable Service resolves but cannot be booked', () async {
      final api = _Api(detail: detailBody(available: false));
      final controller = ServiceDetailController(
          CatalogRepository(api: api, cache: _MemoryCache()));

      await controller.load(15);

      // Resolves, so a deep link lands on honest copy rather than a dead end.
      expect(controller.status, ServiceDetailStatus.unavailable);
      expect(controller.detail?.service.id, 15);
      expect(controller.canStartBooking, isFalse);
    });

    test('a missing Service is notFound, distinct from a network failure',
        () async {
      final controller = ServiceDetailController(
          CatalogRepository(api: _Api(), cache: _MemoryCache()));

      await controller.load(999999);

      expect(controller.status, ServiceDetailStatus.notFound);
    });

    test('add-on selection adjusts the estimate and never the identity',
        () async {
      final api = _Api(detail: detailBody());
      final controller = ServiceDetailController(
          CatalogRepository(api: api, cache: _MemoryCache()));
      await controller.load(15);

      expect(controller.estimatedTotal, 1500);
      controller.toggleAddon(6);
      expect(controller.estimatedTotal, 1850);
      expect(controller.selectedAddonIds, {6});
      // The Service identity is untouched by configuration.
      expect(controller.serviceId, 15);

      controller.toggleAddon(6);
      expect(controller.estimatedTotal, 1500);
      expect(controller.selectedAddonIds, isEmpty);
    });

    test('opening a second Service clears the first one\'s add-ons', () async {
      final api = _Api(detail: detailBody());
      final controller = ServiceDetailController(
          CatalogRepository(api: api, cache: _MemoryCache()));
      await controller.load(15);
      controller.toggleAddon(6);

      await controller.load(15);

      expect(controller.selectedAddonIds, isEmpty);
    });
  });
}
