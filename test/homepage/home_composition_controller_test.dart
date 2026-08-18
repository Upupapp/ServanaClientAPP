/// Home's caller for `HomeCompositionRepository`.
///
/// ## What was wrong
///
/// The repository was registered and the only thing that referenced it was a
/// `CleanupStep('homeComposition')` calling `.clear()` on logout. The app
/// cleared a cache nothing ever filled, and `V1Capability.home` was inert
/// because the object that reads the flag had no callers.
///
/// ## The trap these tests exist for
///
/// The obvious wiring — feed the catalog's categories into Home's grid — would
/// have broken two things silently. The grid's four cards are keyed
/// `beauty_wellness`, `hair_nails`, `massage`, `aircon`, and those keys are
/// what Home's navigation and the category campaign registry look up. The
/// backend's `slugify` produces HYPHENS, so the same category arrives as
/// `beauty-wellness`. A campaign registered against a key the catalog does not
/// use returns null from `forCategoryKey`: no popup, no exception, and tests
/// written against the wrong key pass.
///
/// So the curated four stay exactly as they are and the catalog only adds what
/// they do not cover. These tests pin that boundary.
library;

import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/homepage/application/home_composition_controller.dart';
import 'package:client/modules/homepage/data/home_composition_data_source.dart';
import 'package:client/modules/homepage/data/home_composition_repository.dart';
import 'package:client/modules/homepage/domain/home_composition.dart';
import 'package:client/modules/homepage/presentation/widgets/home_more_categories.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves a scripted categories section.
class _Source implements HomeCompositionDataSource {
  _Source(this._section);

  final HomeSection Function(HomeSectionType type) _section;

  @override
  Future<HomeComposition> fetchComposition() async => HomeComposition(
        sections: <HomeSectionType, HomeSection>{
          for (final type in HomeSectionType.values) type: _section(type),
        },
        fetchedAt: DateTime.utc(2026, 8, 18),
      );

  @override
  Future<HomeSection> fetchSection(HomeSectionType type) async =>
      _section(type);
}

HomeCompositionController controllerServing(HomeSection categories) =>
    HomeCompositionController(
      HomeCompositionRepository(
        compatibility: _Source(
          (type) => type == HomeSectionType.categories
              ? categories
              : HomeSectionAbsent(type),
        ),
      ),
    );

Map<String, dynamic> row({
  Object? id = 3,
  String name = 'Home Cleaning',
  String slug = 'home-cleaning',
  int services = 12,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'slug': slug,
      'serviceCount': services,
    };

void main() {
  group('loading', () {
    test('publishes the catalog categories', () async {
      final c = controllerServing(
        HomeSectionLoaded(HomeSectionType.categories, items: [row()]),
      );

      await c.load();

      final state = c.state as HomeCategoriesReady;
      expect(state.categories.single.id, 3);
      expect(state.categories.single.name, 'Home Cleaning');
      expect(state.categories.single.serviceCount, 12);
      expect(state.isStale, isFalse);
    });

    test('loads once per session unless forced', () async {
      var calls = 0;
      final c = HomeCompositionController(
        HomeCompositionRepository(
          compatibility: _Source((type) {
            if (type == HomeSectionType.categories) calls++;
            return HomeSectionLoaded(type, items: [row()]);
          }),
        ),
      );

      await c.load();
      await c.load();

      // Home rebuilds on every tab switch; re-composing each time would put
      // the catalog behind a request the customer did not ask for.
      expect(calls, 1);

      await c.load(force: true);
      expect(calls, 2);
    });
  });

  group('a failure must leave Home no worse than it was', () {
    test('a failed section becomes a state, not a throw', () async {
      final c = controllerServing(
        HomeSectionFailed(
          HomeSectionType.categories,
          const RetryableFailure(safeMessage: 'offline'),
        ),
      );

      await c.load();

      expect(c.state, isA<HomeCategoriesUnavailable>());
    });

    test('an absent section is unavailable, not failed', () async {
      // The legacy transport genuinely does not offer some sections. There is
      // nothing to retry, so a retry affordance would be a lie.
      final c =
          controllerServing(HomeSectionAbsent(HomeSectionType.categories));

      await c.load();

      expect(c.state, isA<HomeCategoriesUnavailable>());
      expect((c.state as HomeCategoriesUnavailable).failure, isNull);
    });

    test('an empty catalog is treated as unavailable', () async {
      // A heading with nothing under it is worse than no heading.
      final c = controllerServing(
        const HomeSectionLoaded(HomeSectionType.categories, items: []),
      );

      await c.load();

      expect(c.state, isA<HomeCategoriesUnavailable>());
    });
  });

  group('rows that cannot be drawn are dropped', () {
    test('a row with no canonical id is dropped', () async {
      // CatalogRoutes is keyed on catalog_categories.id. No id routes nowhere.
      final c = controllerServing(
        HomeSectionLoaded(
          HomeSectionType.categories,
          items: [row(id: null), row()],
        ),
      );

      await c.load();

      expect((c.state as HomeCategoriesReady).categories, hasLength(1));
    });

    test('a row with no name is dropped', () async {
      final c = controllerServing(
        HomeSectionLoaded(
          HomeSectionType.categories,
          items: [row(name: '  '), row()],
        ),
      );

      await c.load();

      expect((c.state as HomeCategoriesReady).categories, hasLength(1));
    });
  });

  group('the curated four are never duplicated', () {
    test("a backend hyphen slug matches Home's underscore key", () {
      // The whole hazard in one assertion. If this normalisation is dropped,
      // Home draws "Beauty & Wellness" twice — once curated, once from the
      // catalog — and the second one routes somewhere the campaign registry
      // knows nothing about.
      const category = HomeCategory(
        id: 1,
        name: 'Beauty & Wellness',
        slug: 'beauty-wellness',
      );

      expect(category.curatedKey, 'beauty_wellness');
      expect(kCuratedCategoryKeys.contains(category.curatedKey), isTrue);
    });

    test('every curated key is reachable from some backend slug', () {
      for (final key in kCuratedCategoryKeys) {
        final asSlug = key.replaceAll('_', '-');
        final category = HomeCategory(id: 1, name: 'x', slug: asSlug);
        expect(
          category.curatedKey,
          key,
          reason: '$asSlug must normalise back to $key',
        );
      }
    });

    test('a category Home has no card for is not filtered out', () {
      const category = HomeCategory(
        id: 9,
        name: 'Home Cleaning',
        slug: 'home-cleaning',
      );

      expect(kCuratedCategoryKeys.contains(category.curatedKey), isFalse);
    });
  });
}
