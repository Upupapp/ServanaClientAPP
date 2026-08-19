/// Search over the canonical `GET /api/v1/search`.
///
/// ## Not reachable in any shipped build
///
/// Selected only when `CanonicalAvailability.isAvailable(V1Capability.search)`,
/// which requires `--dart-define=CANONICAL_V1_ENABLED=true` AND `search` in
/// `CANONICAL_V1_CAPABILITIES`. No production build passes either.
///
/// ## What this buys that the device cannot do
///
/// This is the first **server-side** search in the customer app. Today the app
/// downloads the catalog and greps it locally, which means:
///
///  - **Aliases cannot work.** `aircon` and `air conditioning` are different
///    strings to `String.contains`. The backend expands the query into terms
///    and scores against all of them, so both find the same Services with the
///    same ids — widening what a term MATCHES without changing what exists.
///  - **Ranking cannot work.** A local `contains` has no notion of an exact
///    name match outranking a description mention. The backend scores
///    4/3/2/1 and puts the bookable thing first, because somebody typing
///    "facial" wants to book a facial rather than browse the category.
///  - **Categories and Subcategories are invisible.** The device index is built
///    from Services only.
///
/// ## Why `/search` and not `/catalog/search`
///
/// The contract mounts both, and they call the same function — two paths, one
/// implementation. `/search` is the primary id (`search.query`);
/// `/catalog/search` is documented as its alias. Calling one of them, rather
/// than either, means a future divergence between the two shows up as a
/// behaviour change here instead of as an unnoticed inconsistency.
library;

import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/search/data/search_data_source.dart';
import 'package:client/modules/search/domain/search_hit.dart';
import 'package:client/modules/search/domain/search_result.dart';

class SearchCanonicalDataSource implements SearchDataSource {
  SearchCanonicalDataSource(this._api, {this.chips = const []});

  final V1ApiClient _api;

  /// Category chips still come from the catalog, not from search. A chip list
  /// that changed with every query would make the filter row jump around.
  final List<SearchCategoryChip> chips;

  @override
  Future<List<SearchCategoryChip>> prepare({bool forceRefresh = false}) async =>
      chips;

  @override
  Future<SearchResults> query(String term, {int limit = 20}) async {
    final q = term.trim();
    // Short-circuited locally rather than sent. The backend answers a short
    // query with an empty result, so sending it would spend a round trip to be
    // told what is already known.
    if (q.length < kMinSearchQueryLength) return SearchResults.empty;

    final envelope = await _api.get(
      V1Endpoints.search(),
      query: <String, dynamic>{
        'q': q,
        // Explicit rather than relying on the default, so a server-side change
        // to "default all three" cannot silently alter what this screen shows.
        'types': 'category,subcategory,service',
        'limit': limit,
      },
    );

    return SearchResults.fromJson(envelope.asMap);
  }
}
