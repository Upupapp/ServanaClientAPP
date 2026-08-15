/// Home composition assembled from the calls the app already makes.
///
/// This is the source every shipped build uses. It changes no endpoint and
/// introduces no new traffic — it fetches the same things Home fetches today
/// and arranges them behind [HomeCompositionDataSource], so the screen gains
/// per-section failure isolation without waiting for `/api/v1/home`.
///
/// ## Isolation is the point
///
/// Every section runs in its own guarded future and they run CONCURRENTLY.
/// Today Home loads serially and one throw takes the screen; here a throw
/// becomes a [HomeSectionFailed] value in one slot while the rest render.
///
/// ## Sections it cannot produce
///
/// `featuredServices`, `popularServices` and `recentServices` have no legacy
/// source. They are reported [HomeSectionAbsent], not failed — the backend
/// never offered them on this transport, so there is nothing to retry and a
/// retry button would be a lie. They arrive when the composition endpoint does.
///
/// ## Where each section's truth comes from
///
/// `categories` reads the canonical Catalog V2 hierarchy rather than a
/// Home-specific list, so Home and the catalog cannot disagree about what
/// exists. `promotions` reads the local promotion registry, which is
/// presentation content under a Remote Config kill switch and deliberately not
/// backend truth.
library;

import 'package:client/core/network/api_error_mapper.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/homepage/data/home_composition_data_source.dart';
import 'package:client/modules/homepage/domain/home_composition.dart';

/// Produces the rows for one section. Supplied by the injector so this source
/// depends on behaviour rather than on concrete repositories, and so a test can
/// make any single section fail.
typedef HomeSectionLoader = Future<List<Map<String, dynamic>>> Function();

class HomeCompositionCompatibilityDataSource
    implements HomeCompositionDataSource {
  HomeCompositionCompatibilityDataSource({
    required Map<HomeSectionType, HomeSectionLoader> loaders,
    ApiErrorMapper mapper = const ApiErrorMapper(),
  })  : _loaders = loaders,
        _mapper = mapper;

  final Map<HomeSectionType, HomeSectionLoader> _loaders;
  final ApiErrorMapper _mapper;

  @override
  Future<HomeComposition> fetchComposition() async {
    // Concurrent, not serial. Home's current serial loads mean the slowest
    // section gates every other one; there is no ordering dependency between
    // them, so there is no reason to pay for it.
    final results = await Future.wait(<Future<HomeSection>>[
      for (final type in HomeSectionType.values) fetchSection(type),
    ]);

    return HomeComposition(
      sections: <HomeSectionType, HomeSection>{
        for (final section in results) section.type: section,
      },
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<HomeSection> fetchSection(HomeSectionType type) async {
    final loader = _loaders[type];
    // No loader means this transport does not offer the section at all.
    if (loader == null) return HomeSectionAbsent(type);

    try {
      final items = await loader();
      return HomeSectionLoaded(type, items: items);
    } catch (error) {
      // Contained here, deliberately. Letting this propagate is exactly the
      // behaviour the tab exists to remove.
      return HomeSectionFailed(type, _asFailure(error));
    }
  }

  ApiFailure _asFailure(Object error) =>
      error is ApiFailure ? error : _mapper.fromTransport(error);
}
