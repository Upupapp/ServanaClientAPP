/// Catalog V2 over the canonical `/api/v1/catalog*` namespace.
///
/// ## Not reachable in any shipped build
///
/// Selected only when `CanonicalAvailability.isAvailable(V1Capability.catalog)`
/// is true, which requires `--dart-define=CANONICAL_V1_ENABLED=true` AND
/// `catalog` in `CANONICAL_V1_CAPABILITIES`. No production build passes either.
///
/// The catalog capability is blocked twice over, which is worth stating
/// plainly: its canonical successors are undeployed AND the legacy routes it
/// would replace (`/api/catalog*`) are themselves absent from the backend's
/// `origin/main`. TAB 01 established both from the backend's git objects.
///
/// ## All six canonical routes
///
/// The contract exposes the whole tree, categories, a category's
/// subcategories, a subcategory's services, all services, and one service.
/// This source implements every one, so enabling the capability does not
/// silently leave a screen on a derived projection when a purpose-built route
/// exists for it.
library;

import 'package:client/core/network/api_envelope.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/common/domain/time/iso_timestamp.dart';
import 'package:client/modules/catalog/data/catalog_data_source.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';

class CatalogCanonicalDataSource implements CatalogDataSource {
  CatalogCanonicalDataSource(this._api);

  final V1ApiClient _api;

  @override
  Future<Catalog> fetchCatalog() async {
    final envelope = await _api.get(V1Endpoints.catalog());
    final data = envelope.asMap;
    if (data.isEmpty) {
      throw const FormatException('Catalog response had no data object');
    }
    return Catalog.fromJson(data).copyWith(fetchedAt: DateTime.now().toUtc());
  }

  @override
  Future<DateTime?> fetchLastUpdatedAt() async {
    try {
      final envelope = await _api.get(V1Endpoints.catalogSummary());
      return parseBackendTimestamp(envelope.asMap['lastUpdatedAt']);
    } catch (_) {
      // Revalidation is best-effort by contract: null means "cannot tell", and
      // the caller falls back to its TTL rather than refetching the whole tree.
      return null;
    }
  }

  @override
  Future<List<CatalogCategory>> fetchCategories() async {
    final envelope = await _api.get(V1Endpoints.catalogCategories());
    return _rows(envelope, 'categories').map(CatalogCategory.fromJson).toList();
  }

  @override
  Future<List<CatalogSubcategory>> fetchSubcategories(int categoryId) async {
    final envelope = await _api
        .get(V1Endpoints.catalogCategorySubcategories(categoryId.toString()));
    return _rows(envelope, 'subcategories')
        .map(CatalogSubcategory.fromJson)
        .toList();
  }

  @override
  Future<List<CatalogService>> fetchSubcategoryServices(
      int subcategoryId) async {
    final envelope = await _api
        .get(V1Endpoints.catalogSubcategoryServices(subcategoryId.toString()));
    return _rows(envelope, 'services').map(CatalogService.fromJson).toList();
  }

  @override
  Future<List<CatalogService>> fetchServices() async {
    final envelope = await _api.get(V1Endpoints.catalogServices());
    return _rows(envelope, 'services').map(CatalogService.fromJson).toList();
  }

  @override
  Future<CatalogServiceDetail> fetchServiceDetail(int serviceId) async {
    final envelope =
        await _api.get(V1Endpoints.catalogService(serviceId.toString()));
    final data = envelope.asMap;
    if (data.isEmpty) {
      throw const FormatException('Service response had no data object');
    }
    return CatalogServiceDetail.fromJson(data);
  }

  /// Reads a collection whether it arrives as a bare array or under a domain
  /// key. Both shapes are legal in the canonical envelope depending on whether
  /// the route paginates, and a caller should not have to know which.
  static List<Map<String, dynamic>> _rows(ApiEnvelope envelope, String key) {
    final keyed = envelope.listAt(key);
    if (keyed.isNotEmpty) return keyed;
    return envelope.listAt();
  }
}
