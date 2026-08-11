/// Versioned on-disk cache for the canonical catalog.
///
/// ## Why the version is in the box name
///
/// The legacy catalog cached a completely different shape — `service_options`
/// rows keyed by `level_2`/`level_3`, with no Category or Subcategory anywhere.
/// Deserialising one of those into a [Catalog] would not throw; it would
/// produce Services with `id: 0` and empty hierarchy names, which renders as a
/// catalog of blanks that all route to the same non-existent Service.
///
/// Putting the version in the box NAME rather than in a field inside it means
/// an incompatible cache is never opened at all, so there is no parse to get
/// wrong. Bumping [_boxName] retires the old data by construction.
///
/// ## What is deliberately NOT cleared
///
/// Only this box. Authentication, profile, saved addresses, booking drafts and
/// unrelated preferences live in their own boxes and are untouched by a catalog
/// schema change (§46) — a customer should not be signed out because an admin
/// renamed a Subcategory.
///
/// ## Freshness
///
/// Two independent signals, because they answer different questions:
///
///  - [_ttl] — "is this old?" Bounds how stale a cold start can be.
///  - `lastUpdatedAt` — "did the catalog actually change?" The backend's
///    `MAX(services.updated_at)`, so an admin edit invalidates immediately
///    while an unchanged catalog costs nothing to revalidate.
library;

import 'dart:convert';

import 'package:client/common/domain/helpers/hive_repo.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';

class CatalogCache {
  CatalogCache({HiveHelper? hive}) : _hive = hive ?? HiveHelper();

  final HiveHelper _hive;

  /// Bump this on any incompatible change to the cached shape.
  ///
  /// v1 was never written to disk by a shipped build — the legacy catalog was
  /// held in memory for the session only — but the name is versioned from the
  /// start so the next migration is a one-line change rather than a rescue.
  static const _boxName = 'catalog_cache_v2';
  static const _payloadKey = 'catalog';

  static const _ttl = Duration(hours: 6);

  /// Legacy boxes to remove on first V2 open. Empty today and that is correct:
  /// the legacy catalog never persisted. Listed explicitly so a future entry is
  /// an addition here rather than an ad-hoc delete somewhere else.
  static const List<String> legacyBoxNames = <String>[];

  Future<Catalog?> read() async {
    try {
      final box = await _hive.openBox<String>(_boxName);
      final raw = box.get(_payloadKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Catalog.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // A cache that cannot be read is a cache miss, never a crash. The box may
      // be corrupt, the cipher key may have been rotated, or the shape may
      // predate this build.
      return null;
    }
  }

  Future<void> write(Catalog catalog) async {
    try {
      final box = await _hive.openBox<String>(_boxName);
      await box.put(
        _payloadKey,
        jsonEncode(
            catalog.copyWith(fetchedAt: DateTime.now().toUtc()).toJson()),
      );
    } catch (_) {
      // Failing to cache must never fail the request that produced the data.
    }
  }

  Future<void> clear() async {
    try {
      final box = await _hive.openBox<String>(_boxName);
      await box.clear();
    } catch (_) {}
  }

  /// True when [catalog] is old enough to warrant a refetch.
  ///
  /// Missing `fetchedAt` counts as stale: an unknown age is not a fresh one.
  static bool isStale(Catalog catalog, {DateTime? now}) {
    final fetchedAt = catalog.fetchedAt;
    if (fetchedAt == null) return true;
    return (now ?? DateTime.now().toUtc()).difference(fetchedAt) > _ttl;
  }

  /// True when the backend reports a catalog newer than the cached one.
  ///
  /// An absent remote timestamp is NOT treated as a change — that would refetch
  /// on every launch against a backend that stopped sending the field.
  static bool isSupersededBy(Catalog cached, DateTime? remoteLastUpdatedAt) {
    if (remoteLastUpdatedAt == null) return false;
    final local = cached.lastUpdatedAt;
    if (local == null) return true;
    return remoteLastUpdatedAt.isAfter(local);
  }
}
