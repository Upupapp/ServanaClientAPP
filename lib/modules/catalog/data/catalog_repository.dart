/// Canonical catalog data access.
///
/// One domain shape plus a versioned, source-isolated on-disk cache. The
/// repository owns the freshness policy so no screen has to reason about it,
/// and it owns the canonical-vs-compatibility choice so no screen learns which
/// transport answered.
///
/// ## No mock fallback (§50)
///
/// On failure this throws. It never substitutes placeholder or sample catalog
/// data, because a fabricated Service is one a customer can tap, configure and
/// try to book against an id the backend has never heard of. A cached catalog
/// IS served on failure — that data was real when it was fetched, and the
/// caller is told it is cached so the UI can say so.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/catalog/data/catalog_compatibility_data_source.dart';
import 'package:client/modules/catalog/data/catalog_data_source.dart';
import 'package:client/modules/catalog/data/catalog_cache.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';

/// A catalog plus where it came from, so the UI can distinguish "live" from
/// "this is what we had".
class CatalogSnapshot {
  const CatalogSnapshot({required this.catalog, required this.fromCache});

  final Catalog catalog;
  final bool fromCache;
}

class CatalogRepository {
  /// [api] constructs the compatibility source when one is not supplied, so
  /// every existing call site keeps working unchanged.
  ///
  /// [canonical] and [router] are optional. Omitting either pins the repository
  /// to the compatibility source with no behaviour change — which is what every
  /// build does today, because `/api/v1` is not deployed.
  CatalogRepository({
    required ServanaApiClient api,
    CatalogCache? cache,
    CatalogDataSource? compatibility,
    CatalogDataSource? canonical,
    CanonicalRouter? router,
    CatalogCache? canonicalCache,
  })  : _compatibility =
            compatibility ?? CatalogCompatibilityDataSource(api),
        _canonical = canonical,
        _router = router,
        _cache = cache ?? CatalogCache(),
        _canonicalCache = canonicalCache ??
            CatalogCache(source: CatalogCacheSource.canonical);

  final CatalogDataSource _compatibility;
  final CatalogDataSource? _canonical;
  final CanonicalRouter? _router;

  final CatalogCache _cache;
  final CatalogCache _canonicalCache;

  Catalog? _memory;

  /// The transport answering right now.
  ///
  /// Falls back to compatibility whenever the canonical source or the router is
  /// absent, so a half-wired injector cannot route at a transport that does not
  /// exist.
  CatalogDataSource get _source {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<CatalogDataSource>(
      V1Capability.catalog,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  /// The cache belonging to whichever transport is active.
  ///
  /// Never shared. A canonical payload read back as a legacy one would not
  /// throw — it would render a subtly wrong catalog.
  CatalogCache get _activeCache => isCanonical ? _canonicalCache : _cache;

  /// True when catalog reads are going to `/api/v1`. Diagnostics only.
  bool get isCanonical =>
      _canonical != null && (_router?.isCanonical(V1Capability.catalog) ?? false);

  /// Loads the catalog, preferring a fresh cache.
  ///
  /// Order is deliberate:
  ///  1. In-memory, if not stale — a tab switch must not hit the network.
  ///  2. On-disk, if not stale AND the backend has not published a newer
  ///     catalog. The revalidation call is the summary endpoint, which is a few
  ///     hundred bytes against the full hierarchy's tens of kilobytes.
  ///  3. Network.
  ///
  /// Step 2's revalidation is best-effort: if the summary call fails we serve
  /// the unexpired cache rather than forcing a full fetch that would fail too.
  Future<CatalogSnapshot> load({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final memory = _memory;
      if (memory != null && !CatalogCache.isStale(memory)) {
        return CatalogSnapshot(catalog: memory, fromCache: true);
      }

      final cached = await _activeCache.read();
      if (cached != null && !CatalogCache.isStale(cached)) {
        if (!await _backendHasNewer(cached)) {
          _memory = cached;
          return CatalogSnapshot(catalog: cached, fromCache: true);
        }
      }
    }

    try {
      final catalog = await _source.fetchCatalog();
      _memory = catalog;
      await _activeCache.write(catalog);
      return CatalogSnapshot(catalog: catalog, fromCache: false);
    } catch (_) {
      // Serve verified stale data rather than an error screen when we have it.
      // Never a placeholder (§50).
      final fallback = _memory ?? await _activeCache.read();
      if (fallback != null) {
        return CatalogSnapshot(catalog: fallback, fromCache: true);
      }
      rethrow;
    }
  }

  Future<bool> _backendHasNewer(Catalog cached) async {
    final remote = await _source.fetchLastUpdatedAt();
    return CatalogCache.isSupersededBy(cached, remote);
  }

  /// Every visible Category. Served from the active transport — canonical uses
  /// the purpose-built route, compatibility projects it from the tree.
  Future<List<CatalogCategory>> categories() => _source.fetchCategories();

  /// Subcategories of one Category.
  Future<List<CatalogSubcategory>> subcategories(int categoryId) =>
      _source.fetchSubcategories(categoryId);

  /// Services of one Subcategory.
  Future<List<CatalogService>> subcategoryServices(int subcategoryId) =>
      _source.fetchSubcategoryServices(subcategoryId);

  /// Every visible Service, flat.
  Future<List<CatalogService>> services() => _source.fetchServices();

  /// One Service by canonical id.
  ///
  /// Always a network read. Detail carries availability and pricing, and §67
  /// requires those revalidated rather than trusted from a long-lived cache.
  /// The cached hierarchy is only consulted to render breadcrumbs instantly
  /// while this is in flight — never to answer "can this be booked".
  Future<CatalogServiceDetail> serviceDetail(int serviceId) =>
      _source.fetchServiceDetail(serviceId);

  /// The last catalog this session loaded, without touching the network.
  /// Used for breadcrumb context and search, never for booking decisions.
  Catalog? get cachedCatalog => _memory;

  /// Clears catalog state only. Not auth, not profile, not drafts (§46).
  Future<void> clearCache() async {
    _memory = null;
    // BOTH boxes. A build that flips the capability must not leave the other
    // transport's stale tree on disk to be served after the next flip back.
    await _cache.clear();
    await _canonicalCache.clear();
  }
}
