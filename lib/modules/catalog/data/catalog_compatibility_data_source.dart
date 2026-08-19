/// Catalog V2 over the legacy public catalog routes.
///
/// This is the source every shipped build uses. Behaviour is unchanged from
/// before TAB 04 — the same three calls `CatalogRepository` already made
/// (`/api/catalog`, `/api/catalog/summary`, `/api/catalog/services/:id`).
/// What is new is only that they now sit behind [CatalogDataSource].
///
/// ## Deriving the four granular reads
///
/// The legacy surface has no `/categories`, `/categories/:id/subcategories`,
/// `/subcategories/:id/services` or `/services` route. This source derives all
/// four from the tree it can fetch, and that is the honest answer rather than a
/// throw: a Category list is a *projection* of the hierarchy, not a different
/// fact, so the data genuinely is available and returning it is correct.
///
/// Contrast `IdentityDataSource.verifyMobile`, which throws
/// `UnsupportedTransportOperation`: there, no legacy route exists AND no legacy
/// data exists to derive from, so any answer would be invented.
///
/// The cost is one full-tree fetch where the canonical source would make a
/// small targeted call. That is acceptable for a compatibility path whose
/// whole purpose is to stop existing once v1 deploys, and the tree is cached.
///
/// ## No legacy identifiers escape
///
/// The legacy response is parsed by the same canonical models. `level2`,
/// `level3` and `serviceFamily` are not read, not stored and not forwarded —
/// `catalog_level2_regression_test.dart` fails if the key reappears.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/time/iso_timestamp.dart';
import 'package:client/modules/catalog/data/catalog_data_source.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';

class CatalogCompatibilityDataSource implements CatalogDataSource {
  CatalogCompatibilityDataSource(this._api);

  final ServanaApiClient _api;

  /// The last tree this source fetched, so the four derived reads do not each
  /// trigger their own full fetch within one screen build.
  ///
  /// Deliberately NOT a freshness cache — `CatalogRepository` owns TTL and
  /// revalidation. This only avoids a stampede, and any caller wanting
  /// guaranteed-fresh data calls [fetchCatalog] directly.
  Catalog? _lastTree;

  @override
  Future<Catalog> fetchCatalog() async {
    final json = await _api.getCanonicalCatalog();
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Catalog response had no data object');
    }
    final catalog = Catalog.fromJson(Map<String, dynamic>.from(data))
        .copyWith(fetchedAt: DateTime.now().toUtc());
    _lastTree = catalog;
    return catalog;
  }

  @override
  Future<DateTime?> fetchLastUpdatedAt() async {
    try {
      final json = await _api.getCanonicalCatalogSummary();
      final data = json['data'];
      if (data is! Map) return null;
      return parseBackendTimestamp(data['lastUpdatedAt']);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CatalogCategory>> fetchCategories() async =>
      (await _tree()).categories;

  @override
  Future<List<CatalogSubcategory>> fetchSubcategories(int categoryId) async {
    final category = (await _tree()).categoryById(categoryId);
    // An unknown id is an empty list, not a throw. The hierarchy can change
    // under a deep link, and a missing Category is "nothing here" rather than
    // an error the customer can act on.
    return category?.subcategories ?? const <CatalogSubcategory>[];
  }

  @override
  Future<List<CatalogService>> fetchSubcategoryServices(
      int subcategoryId) async {
    for (final category in (await _tree()).categories) {
      for (final subcategory in category.subcategories) {
        if (subcategory.id == subcategoryId) return subcategory.services;
      }
    }
    return const <CatalogService>[];
  }

  @override
  Future<List<CatalogService>> fetchServices() async =>
      (await _tree()).allServices;

  @override
  Future<CatalogServiceDetail> fetchServiceDetail(int serviceId) async {
    final json = await _api.getCanonicalService(serviceId: serviceId);
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Service response had no data object');
    }
    return CatalogServiceDetail.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Catalog> _tree() async => _lastTree ?? await fetchCatalog();
}
