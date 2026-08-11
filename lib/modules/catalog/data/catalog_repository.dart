/// Canonical catalog data access.
///
/// One network shape (`GET /api/catalog`) plus a versioned on-disk cache. The
/// repository owns the freshness policy so no screen has to reason about it.
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
import 'package:client/common/domain/time/iso_timestamp.dart';
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
  CatalogRepository({
    required ServanaApiClient api,
    CatalogCache? cache,
  })  : _api = api,
        _cache = cache ?? CatalogCache();

  final ServanaApiClient _api;
  final CatalogCache _cache;

  Catalog? _memory;

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

      final cached = await _cache.read();
      if (cached != null && !CatalogCache.isStale(cached)) {
        if (!await _backendHasNewer(cached)) {
          _memory = cached;
          return CatalogSnapshot(catalog: cached, fromCache: true);
        }
      }
    }

    try {
      final catalog = await _fetch();
      _memory = catalog;
      await _cache.write(catalog);
      return CatalogSnapshot(catalog: catalog, fromCache: false);
    } catch (_) {
      // Serve verified stale data rather than an error screen when we have it.
      // Never a placeholder (§50).
      final fallback = _memory ?? await _cache.read();
      if (fallback != null) {
        return CatalogSnapshot(catalog: fallback, fromCache: true);
      }
      rethrow;
    }
  }

  Future<bool> _backendHasNewer(Catalog cached) async {
    try {
      final json = await _api.getCanonicalCatalogSummary();
      final data = json['data'];
      if (data is! Map) return false;
      return CatalogCache.isSupersededBy(
        cached,
        parseBackendTimestamp(data['lastUpdatedAt']),
      );
    } catch (_) {
      return false;
    }
  }

  Future<Catalog> _fetch() async {
    final json = await _api.getCanonicalCatalog();
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Catalog response had no data object');
    }
    return Catalog.fromJson(Map<String, dynamic>.from(data))
        .copyWith(fetchedAt: DateTime.now().toUtc());
  }

  /// One Service by canonical id.
  ///
  /// Always a network read. Detail carries availability and pricing, and §67
  /// requires those revalidated rather than trusted from a long-lived cache.
  /// The cached hierarchy is only consulted to render breadcrumbs instantly
  /// while this is in flight — never to answer "can this be booked".
  Future<CatalogServiceDetail> serviceDetail(int serviceId) async {
    final json = await _api.getCanonicalService(serviceId: serviceId);
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Service response had no data object');
    }
    return CatalogServiceDetail.fromJson(Map<String, dynamic>.from(data));
  }

  /// The last catalog this session loaded, without touching the network.
  /// Used for breadcrumb context and search, never for booking decisions.
  Catalog? get cachedCatalog => _memory;

  /// Clears catalog state only. Not auth, not profile, not drafts (§46).
  Future<void> clearCache() async {
    _memory = null;
    await _cache.clear();
  }
}
