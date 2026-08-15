/// Search feature repository.
///
///     SearchRepository
///       → SearchCanonicalDataSource      when V1Capability.search
///       → SearchCompatibilityDataSource  otherwise
///       → the same SearchResults either way
///
/// [canonical] and [router] are optional. Omitting either pins the repository
/// to the compatibility source, which is what every build does today because
/// `/api/v1` is not deployed.
///
/// ## What moved, and what did not
///
/// The index-building that used to live here now lives in
/// `SearchCompatibilityDataSource`, because it is one transport's private
/// mechanism rather than the feature's contract. What stayed is the property
/// that made it worth writing: the index is derived from `CatalogRepository`,
/// so search and browse cannot disagree about what exists. They previously were
/// two independent fetches of two different endpoints with two different
/// filtering rules, and they did disagree.
///
/// No synonym table is maintained on the device. Aliases belong to the
/// backend's query expansion, which is the whole point of moving search to the
/// server; a client-side alias map would be a second taxonomy the Admin portal
/// cannot see.
library;

import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/search/data/search_compatibility_data_source.dart';
import 'package:client/modules/search/data/search_data_source.dart';
import 'package:client/modules/search/domain/search_hit.dart';
import 'package:client/modules/search/domain/search_result.dart';

class SearchRepository {
  SearchRepository({
    required SearchCompatibilityDataSource compatibility,
    SearchDataSource? canonical,
    CanonicalRouter? router,
  })  : _compatibility = compatibility,
        _canonical = canonical,
        _router = router;

  final SearchCompatibilityDataSource _compatibility;
  final SearchDataSource? _canonical;
  final CanonicalRouter? _router;

  List<SearchCategoryChip> _chips = const [];

  /// Category chips for the current catalog, in the backend's display order.
  /// Empty until the first successful [prepare].
  ///
  /// Always sourced from the catalog, never from a query result — a chip row
  /// that changed with each keystroke would move the filter targets under the
  /// customer's finger.
  List<SearchCategoryChip> get categoryChips => List.unmodifiable(_chips);

  /// The transport answering right now. Falls back to compatibility whenever
  /// the canonical source or router is absent, so a half-wired injector cannot
  /// route at a transport that does not exist.
  SearchDataSource get _source {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<SearchDataSource>(
      V1Capability.search,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  /// True when queries are answered by `/api/v1/search`. Diagnostics only.
  bool get isCanonical =>
      _canonical != null && (_router?.isCanonical(V1Capability.search) ?? false);

  /// Prepares the active transport and refreshes the chips.
  ///
  /// Chips come from the compatibility source even when canonical answers
  /// queries: they are a projection of the catalog, and the catalog is the same
  /// canonical hierarchy either way.
  Future<List<SearchCategoryChip>> prepare({bool forceRefresh = false}) async {
    _chips = await _compatibility.prepare(forceRefresh: forceRefresh);
    return _chips;
  }

  /// Runs one query through whichever transport is active.
  Future<SearchResults> search(String term, {int limit = 50}) =>
      _source.query(term, limit: limit);

  /// The whole on-device index.
  ///
  /// Retained for the "no query yet" state, where the screen lists everything
  /// rather than showing an empty page. The canonical transport has no
  /// equivalent — a server-side search with no term is not a browse — so this
  /// stays on the compatibility source by design, and the browse experience it
  /// feeds is really the catalog's, not search's.
  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async {
    await prepare(forceRefresh: forceRefresh);
    return _compatibility.index;
  }

  void clearCache() {
    _compatibility.clearCache();
    _chips = const [];
  }
}
