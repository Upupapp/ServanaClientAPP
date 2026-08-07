import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/search/domain/search_result.dart';
import 'package:client/common/domain/pricing/catalog_price.dart';

/// Fetches and caches the full service catalog for in-memory search.
///
/// The backend's GET /api/services/full returns the complete structured
/// catalog in a single request — no pagination, no search endpoint needed.
/// Cache is kept for the session lifetime; call [clearCache] to force refresh.
class SearchRepository {
  SearchRepository({required ServanaApiClient api}) : _api = api;

  final ServanaApiClient _api;
  List<SearchResult>? _cache;

  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    final json = await _api.listFullCatalog();
    final services = json['services'] as List<dynamic>? ?? [];
    final results = <SearchResult>[];
    for (final rawService in services) {
      if (rawService is! Map) continue;
      final svc = Map<String, dynamic>.from(rawService);
      final serviceId = _asInt(svc['serviceId'] ?? svc['service_id']);
      final name = (svc['name'] ?? '').toString().trim();
      final cat = (svc['category'] ?? '').toString();
      final requiresBranch = cat == 'BRANCH_SERVICE';
      final catId = categoryIdFromService(serviceId: serviceId, name: name);
      if (catId == null) continue;
      final label = categoryLabel(catId);
      final options = svc['options'];
      if (options is! List) continue;
      for (final rawOption in options) {
        if (rawOption is! Map) continue;
        final opt = Map<String, dynamic>.from(rawOption);
        final level2 =
            (opt['level2'] ?? opt['level_2'] ?? '').toString().trim();
        if (level2.isEmpty) continue;
        final rawItems = opt['items'];
        final items = rawItems is List
            ? rawItems.whereType<Map>().map(Map<String, dynamic>.from).toList()
            : const <Map<String, dynamic>>[];
        if (items.isEmpty) continue;
        // Shared resolver: this used to read only `base_price` and cast it
        // `as num?`, so a price arriving as a string — or under the camelCase
        // spelling that /options-with-addons uses — became 0 and rendered as
        // "Get a quote" on a priced service.
        final prices = items
            .map(extractCatalogPricePesosInt)
            .whereType<int>()
            .where((p) => p > 0)
            .toList();
        results.add(SearchResult(
          serviceId: serviceId,
          serviceName: name,
          level2: level2,
          minPricePesos:
              prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b),
          maxPricePesos:
              prices.isEmpty ? 0 : prices.reduce((a, b) => a > b ? a : b),
          requiresBranch: requiresBranch,
          categoryId: catId,
          categoryLabel: label,
        ));
      }
    }
    _cache = results;
    return results;
  }

  static int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void clearCache() => _cache = null;
}
