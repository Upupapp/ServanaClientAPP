/// Search as the app does it today: an on-device index over the catalog.
///
/// This is the source every shipped build uses, and it changes no endpoint. It
/// wraps the existing behaviour — build one entry per canonical Service from
/// `CatalogRepository`, then match a lowercased substring against the Service
/// name and its hierarchy — behind [SearchDataSource], so the controller has a
/// single call path whichever transport answers.
///
/// ## What it cannot do, stated rather than hidden
///
/// It matches with `String.contains`. That means:
///
///  - **No aliases.** `aircon` will not find `Air Conditioning`. The backend's
///    term expansion is the fix, and it is server-side.
///  - **No ranking.** Every match scores the same, so results come back in
///    catalog order. `score` is reported as 1 (`contains`) rather than invented,
///    because claiming an exact-match score the comparison never computed would
///    make the two transports disagree about relevance while looking identical.
///  - **Services only.** The index is built from Services, so Category and
///    Subcategory hits are absent — not empty, absent. The screen renders
///    Services today, so nothing is lost until the canonical source arrives.
///
/// A synonym table is deliberately NOT maintained here. It would be a second
/// taxonomy the Admin portal cannot see, and it would drift from the backend's
/// expansion the first time either side added a term.
library;

import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/modules/search/data/search_data_source.dart';
import 'package:client/modules/search/domain/search_hit.dart';
import 'package:client/modules/search/domain/search_result.dart';

class SearchCompatibilityDataSource implements SearchDataSource {
  SearchCompatibilityDataSource({required CatalogRepository catalog})
      : _catalog = catalog;

  final CatalogRepository _catalog;

  List<SearchResult>? _index;
  List<SearchCategoryChip> _chips = const [];

  /// The built index, for the callers that still want the whole set.
  List<SearchResult> get index => List.unmodifiable(_index ?? const []);

  @override
  Future<List<SearchCategoryChip>> prepare({bool forceRefresh = false}) async {
    if (!forceRefresh && _index != null) return _chips;

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

    _index = results;
    _chips = chips;
    return chips;
  }

  @override
  Future<SearchResults> query(String term, {int limit = 20}) async {
    final q = term.trim();
    if (q.length < kMinSearchQueryLength) return SearchResults.empty;

    await prepare();
    final needle = q.toLowerCase();

    final hits = <SearchHit>[];
    for (final r in _index ?? const <SearchResult>[]) {
      if (!r.searchHaystack.contains(needle)) continue;
      hits.add(SearchHit(
        // The same qualified form the backend emits, so a ref means one thing
        // regardless of which transport produced it.
        ref: 'service:${r.serviceId}',
        type: SearchEntityType.service,
        id: r.serviceId,
        name: r.serviceName,
        context: r.hierarchyPath,
        bookable: r.bookable,
        basePrice: r.minPricePesos,
        categoryId: r.categoryId,
        subcategoryId: r.subcategoryId,
        // 1 = "contains", which is literally what was computed.
        score: 1,
        matchedTerm: q,
      ));
    }

    return SearchResults(
      query: q,
      hits: hits.length > limit ? hits.sublist(0, limit) : hits,
      // The pre-truncation count, matching the server's `total` semantics so
      // `isTruncated` means the same thing on both transports.
      total: hits.length,
    );
  }

  void clearCache() {
    _index = null;
    _chips = const [];
  }
}
