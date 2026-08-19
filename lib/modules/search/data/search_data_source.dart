/// The contract both search transports satisfy.
///
///     SearchRepository
///       → SearchCanonicalDataSource      when V1Capability.search
///       → SearchCompatibilityDataSource  otherwise
///       → the same SearchResults either way
///
/// ## Why `query` is asynchronous on both sides
///
/// The compatibility source searches an in-memory index and could answer
/// synchronously. It does not, because the interface has to fit the canonical
/// source, where a query is a network round trip. Making the *shipping* path
/// async costs one microtask and buys one code path in the controller instead
/// of a fork that would only ever be exercised on one side.
///
/// It also forces the caller to confront request ordering. Search-as-you-type
/// issues overlapping queries, and a slow answer to `fac` arriving after a fast
/// answer to `facial` renders results for a query the customer has already
/// finished typing. `SearchController` sequences them; see its guard.
library;

import 'package:client/modules/search/domain/search_hit.dart';
import 'package:client/modules/search/domain/search_result.dart';

abstract interface class SearchDataSource {
  /// Prepares whatever this transport needs before it can answer.
  ///
  /// Compatibility builds the on-device index from the canonical catalog.
  /// Canonical has nothing to prepare — the server holds the index — so it
  /// returns immediately. Either way the caller gets the Category chips, which
  /// are derived from the catalog and not from a query.
  Future<List<SearchCategoryChip>> prepare({bool forceRefresh = false});

  /// Runs one query.
  ///
  /// Returns an empty result set rather than throwing for a query that is
  /// simply too short — under two characters is "not asking yet", not an error,
  /// and the backend agrees (`MIN_QUERY_LENGTH`, which returns empty, not 400).
  ///
  /// Throws only on a real transport or server failure, so the controller can
  /// distinguish "nothing matched" from "we could not ask".
  Future<SearchResults> query(String term, {int limit});
}

/// Minimum query length, matching `catalogSearchService.MIN_QUERY_LENGTH`.
///
/// Duplicated deliberately and pinned by a comment rather than fetched: one
/// character matches most of the catalog, and the client must not send a query
/// it knows will be refused. If the backend changes this, the client is wrong
/// in the harmless direction — it asks less often than it could.
const int kMinSearchQueryLength = 2;
