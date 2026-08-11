import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/modules/search/domain/search_result.dart';

/// Builds the search index from the canonical catalog.
///
/// One entry per canonical Service, carrying its `services.id` and its
/// hierarchy. The index is derived from `CatalogRepository`, so search and
/// browse cannot disagree about what exists — previously they were two
/// independent fetches of two different endpoints with two different
/// filtering rules, and they did disagree.
///
/// No synonym table is maintained here. Aliases like `AC` / `aircon` /
/// `air conditioner` belong to the catalog's own naming and to a backend search
/// capability if one is ever added; inventing a client-side alias map would
/// create a second taxonomy the Admin portal cannot see (§34).
class SearchRepository {
  SearchRepository({required CatalogRepository catalog}) : _catalog = catalog;

  final CatalogRepository _catalog;

  List<SearchResult>? _cache;
  List<SearchCategoryChip> _chips = const [];

  /// Category chips for the current index, in the backend's display order.
  /// Empty until the first successful load.
  List<SearchCategoryChip> get categoryChips => List.unmodifiable(_chips);

  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;

    final snapshot = await _catalog.load(forceRefresh: forceRefresh);

    final results = <SearchResult>[];
    final chips = <SearchCategoryChip>[];

    for (final category in snapshot.catalog.categories) {
      chips.add(SearchCategoryChip(id: category.id, label: category.name));
      for (final sub in category.subcategories) {
        for (final service in sub.services) {
          final price = service.basePrice?.round() ?? 0;
          results.add(SearchResult(
            serviceId: service.id,
            serviceName: service.name,
            subcategoryId: sub.id,
            subcategoryName: sub.name,
            categoryId: category.id,
            categoryName: category.name,
            // A Service has one price, so min and max coincide. Both are kept
            // because the card renders "From ₱X" for a range and the shape
            // should not have to change if per-option pricing returns.
            minPricePesos: price,
            maxPricePesos: price,
            bookable: service.isBookable,
          ));
        }
      }
    }

    _cache = results;
    _chips = chips;
    return results;
  }

  void clearCache() {
    _cache = null;
    _chips = const [];
  }
}
