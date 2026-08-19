/// The contract both catalog transports satisfy.
///
/// `CatalogCompatibilityDataSource` implements it over the legacy public
/// catalog; `CatalogCanonicalDataSource` implements it over `/api/v1/catalog*`.
/// `CatalogRepository` holds this type, so the choice is one line there and
/// invisible to `CatalogController`, to `CategoryScreen` and to every widget.
///
/// ## Why the granular reads are on the interface
///
/// The canonical contract exposes six routes — the whole tree, categories,
/// a category's subcategories, a subcategory's services, all services, and one
/// service. The legacy surface has only the tree and one service.
///
/// The compatibility source does NOT throw for the four it lacks. It derives
/// them from the tree it already fetched, because the data genuinely is there —
/// a Category list is a projection of the hierarchy, not a different fact.
/// Throwing would be dishonest in the opposite direction from a silent no-op:
/// it would report "unavailable" for something the app can answer correctly.
///
/// That is the difference from `IdentityDataSource.verifyMobile`, which throws:
/// there, no legacy route exists AND no legacy data exists to derive from.
///
/// ## One shape out
///
/// Both sources return the same `Catalog` / `CatalogCategory` /
/// `CatalogSubcategory` / `CatalogService` / `CatalogServiceDetail` models.
/// No `level2`, no `level3`, no `serviceFamily`, no raw response map crosses
/// this boundary.
library;

import 'package:client/modules/catalog/domain/catalog_models.dart';

abstract interface class CatalogDataSource {
  /// The full Category → Subcategory → Service hierarchy.
  Future<Catalog> fetchCatalog();

  /// `MAX(services.updated_at)` for cache revalidation, or null when the
  /// transport cannot answer cheaply.
  ///
  /// Null means "cannot tell", never "unchanged" — a caller must treat it as
  /// no information and fall back to its TTL, not as permission to serve a
  /// stale tree indefinitely.
  Future<DateTime?> fetchLastUpdatedAt();

  /// Every visible Category.
  Future<List<CatalogCategory>> fetchCategories();

  /// Subcategories of one Category.
  Future<List<CatalogSubcategory>> fetchSubcategories(int categoryId);

  /// Services of one Subcategory.
  Future<List<CatalogService>> fetchSubcategoryServices(int subcategoryId);

  /// Every visible Service, flat.
  Future<List<CatalogService>> fetchServices();

  /// One Service by canonical `services.id`, with availability and pricing.
  Future<CatalogServiceDetail> fetchServiceDetail(int serviceId);
}
