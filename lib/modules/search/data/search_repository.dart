import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/search/domain/search_result.dart';

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
    for (final svc in services) {
      final serviceId = (svc['serviceId'] as num?)?.toInt() ?? 0;
      final name = (svc['name'] as String?) ?? '';
      final cat = (svc['category'] as String?) ?? '';
      final requiresBranch = cat == 'BRANCH_SERVICE';
      final catId = categoryIdFromService(serviceId: serviceId, name: name);
      if (catId == null) continue;
      final label = categoryLabel(catId);
      for (final opt in (svc['options'] as List<dynamic>? ?? [])) {
        final level2 = (opt['level2'] as String?) ?? '';
        if (level2.isEmpty) continue;
        final items = opt['items'] as List<dynamic>? ?? [];
        if (items.isEmpty) continue;
        final prices = items
            .map((i) => (i['base_price'] as num?)?.toInt() ?? 0)
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

  void clearCache() => _cache = null;
}
