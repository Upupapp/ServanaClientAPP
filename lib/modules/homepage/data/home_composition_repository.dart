/// Home composition feature repository.
///
///     HomeCompositionRepository
///       → HomeCompositionCanonicalDataSource      when V1Capability.home
///       → HomeCompositionCompatibilityDataSource  otherwise
///       → HomeComposition either way
///
/// [canonical] and [router] are optional. Omitting either pins the repository
/// to the compatibility source, which is what every build does today because
/// `/api/v1` is not deployed.
///
/// ## Stale-safe, and honest about it
///
/// A total composition failure serves the last good composition when there is
/// one, with every loaded section re-marked [HomeSectionOrigin.cached] so the
/// screen can say "this is what we had" rather than implying it is live. That
/// follows the recovery architecture the catalog already uses: real data that
/// was true when fetched, never a placeholder (§50).
///
/// With no cache and a total failure it rethrows — the one case that genuinely
/// warrants a full-screen error, and the caller distinguishes offline from
/// server-side through the typed failure.
library;

import 'package:client/core/network/api_error_mapper.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/homepage/data/home_composition_data_source.dart';
import 'package:client/modules/homepage/domain/home_composition.dart';

class HomeCompositionRepository {
  HomeCompositionRepository({
    required HomeCompositionDataSource compatibility,
    HomeCompositionDataSource? canonical,
    CanonicalRouter? router,
    ApiErrorMapper mapper = const ApiErrorMapper(),
  })  : _compatibility = compatibility,
        _canonical = canonical,
        _router = router,
        _mapper = mapper;

  final HomeCompositionDataSource _compatibility;
  final HomeCompositionDataSource? _canonical;
  final CanonicalRouter? _router;
  final ApiErrorMapper _mapper;

  /// The last composition that produced anything, for stale-safe serving.
  HomeComposition? _lastGood;

  /// The transport answering right now. Falls back to compatibility whenever
  /// the canonical source or router is absent, so a half-wired injector cannot
  /// route at a transport that does not exist.
  HomeCompositionDataSource get _source {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<HomeCompositionDataSource>(
      V1Capability.home,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  /// True when Home is composed by `/api/v1/home`. Diagnostics only.
  bool get isCanonical =>
      _canonical != null && (_router?.isCanonical(V1Capability.home) ?? false);

  /// The last composition this session produced, without touching the network.
  HomeComposition? get cached => _lastGood;

  /// Loads Home.
  ///
  /// Never throws for a section-level failure — those are values inside the
  /// returned composition. Throws only when the composition could not be
  /// produced at all AND nothing is cached.
  Future<HomeComposition> load() async {
    try {
      final composition = await _source.fetchComposition();
      // Only remember a composition that actually produced something. Caching
      // an all-failed composition would turn one bad launch into a permanent
      // "stale" badge over an empty screen.
      if (!composition.isBlank) _lastGood = composition;
      return composition;
    } catch (error) {
      final fallback = _lastGood;
      if (fallback != null) return _asCached(fallback);
      rethrow;
    }
  }

  /// Retries one section. Never throws — a retry tap cannot crash Home.
  Future<HomeSection> retrySection(HomeSectionType type) async {
    try {
      final section = await _source.fetchSection(type);
      final last = _lastGood;
      if (last != null && section is HomeSectionLoaded) {
        _lastGood = last.mergeSection(section);
      }
      return section;
    } catch (error) {
      return HomeSectionFailed(
        type,
        error is ApiFailure ? error : _mapper.fromTransport(error),
      );
    }
  }

  /// Drops the cached composition. Called on logout so one customer's Home
  /// cannot be served to the next person on the device.
  void clear() => _lastGood = null;

  /// Re-marks every loaded section as cached, so the UI cannot present stale
  /// content as live.
  static HomeComposition _asCached(HomeComposition composition) =>
      HomeComposition(
        fetchedAt: composition.fetchedAt,
        sections: <HomeSectionType, HomeSection>{
          for (final entry in composition.sections.entries)
            entry.key: switch (entry.value) {
              HomeSectionLoaded(items: final items) => HomeSectionLoaded(
                  entry.key,
                  items: items,
                  origin: HomeSectionOrigin.cached,
                ),
              final HomeSection other => other,
            },
        },
      );
}
