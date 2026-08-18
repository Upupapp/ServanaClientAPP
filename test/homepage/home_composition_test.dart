/// TAB 05 — Home composition.
///
/// The two tests that matter most here are regressions against defects found
/// by reading the backend rather than by running the app:
///
///  1. `parses the canonical array-of-envelopes body` — an earlier parser
///     expected `sections` to be a map keyed by type. The real
///     `GET /api/v1/home` returns an ARRAY. The parser fell through to the root
///     keys, matched neither `sections` nor `meta`, and produced an empty
///     composition, which `isUsable` reads as a blank Home.
///  2. `fetchSection narrows /api/v1/home, never the registry` — an earlier
///     implementation called `/api/v1/home/sections?section=…` for content.
///     That route is `homeService.describeSections`: metadata, no account, no
///     resource, and no such parameter.
library;

import 'dart:convert';

import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/homepage/data/home_composition_canonical_data_source.dart';
import 'package:client/modules/homepage/data/home_composition_compatibility_data_source.dart';
import 'package:client/modules/homepage/data/home_composition_data_source.dart';
import 'package:client/modules/homepage/data/home_composition_repository.dart';
import 'package:client/modules/homepage/domain/home_composition.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The body `composeHome` actually produces: an array of section envelopes
/// plus a `meta` block. Mirrors `src/services/home/homeService.ts`.
Map<String, dynamic> homeFeedJson() => <String, dynamic>{
      'sections': [
        {
          'type': 'categories',
          'status': 'ok',
          'items': [
            {'id': 3, 'name': 'Personal Care', 'slug': 'personal-care'},
          ],
          'reason': null,
          'ttlSeconds': 300,
        },
        {
          'type': 'recentServices',
          'status': 'ok',
          'items': <dynamic>[],
          // A new customer, not a broken backend.
          'reason': 'EMPTY',
          'ttlSeconds': 60,
        },
        {
          'type': 'activeBooking',
          'status': 'ok',
          'items': <dynamic>[],
          'reason': 'REQUIRES_AUTH',
          'ttlSeconds': 0,
        },
        {
          'type': 'banners',
          'status': 'ok',
          'items': <dynamic>[],
          'reason': 'NOT_CONFIGURED',
          'ttlSeconds': 300,
        },
        {
          'type': 'popularServices',
          'status': 'unavailable',
          'items': <dynamic>[],
          'reason': 'UNAVAILABLE',
          'ttlSeconds': 300,
        },
      ],
      'meta': {
        'requested': ['categories'],
        'unavailable': ['popularServices'],
        'personalized': false,
        'generatedAt': '2026-08-16T00:00:00.000Z',
      },
    };

/// A source that returns whatever it is handed, and records the calls.
class _StubSource implements HomeCompositionDataSource {
  _StubSource({this.composition, this.error});

  final HomeComposition? composition;
  final Object? error;
  int compositionCalls = 0;

  @override
  Future<HomeComposition> fetchComposition() async {
    compositionCalls++;
    if (error != null) throw error!;
    return composition ?? HomeComposition.empty;
  }

  @override
  Future<HomeSection> fetchSection(HomeSectionType type) async =>
      HomeSectionAbsent(type);
}

HomeComposition _loadedWith({
  List<Map<String, dynamic>> categories = const [
    {'id': 1}
  ],
}) =>
    HomeComposition(
      sections: {
        HomeSectionType.categories:
            HomeSectionLoaded(HomeSectionType.categories, items: categories),
      },
    );

void main() {
  group('canonical body parsing', () {
    test('parses the canonical array-of-envelopes body', () {
      final composition = HomeComposition.fromJson(homeFeedJson());

      // The regression: five envelopes in, five sections out. A parser that
      // only understands the map form yields zero here.
      expect(composition.sections, hasLength(5));
      expect(composition.itemsOf(HomeSectionType.categories).single['name'],
          'Personal Care');
      expect(composition.isUsable, isTrue);
      expect(composition.isBlank, isFalse);
    });

    test('reason decides the outcome type, not just the copy', () {
      final composition = HomeComposition.fromJson(homeFeedJson());

      // EMPTY is a real answer with no rows — "no recent services", not a retry.
      final recent = composition.sectionOf(HomeSectionType.recentServices);
      expect(recent, isA<HomeSectionLoaded>());
      expect((recent as HomeSectionLoaded).isEmpty, isTrue);

      // REQUIRES_AUTH is a Home without personalization, not a failure.
      expect(composition.sectionOf(HomeSectionType.activeBooking),
          isA<HomeSectionAbsent>());

      // NOT_CONFIGURED — the backend has no promotions source and says so.
      expect(composition.sectionOf(HomeSectionType.promotions),
          isA<HomeSectionAbsent>());

      // UNAVAILABLE genuinely failed server-side, so a retry makes sense.
      final popular = composition.sectionOf(HomeSectionType.popularServices);
      expect(popular, isA<HomeSectionFailed>());
      expect((popular as HomeSectionFailed).isRetryable, isTrue);
    });

    test('`banners` reads as promotions, and promotions asks for `banners`',
        () {
      // The registry calls it banners; this enum calls it promotions. Reading
      // accepts both. Asking must emit the backend's spelling, because
      // composeHome drops an unknown name and then falls back to EVERY section
      // — so a mis-spelled request silently widens the response.
      expect(HomeSectionType.fromWire('banners'), HomeSectionType.promotions);
      expect(HomeSectionType.promotions.requestName, 'banners');
      expect(HomeSectionType.categories.requestName, 'categories');
    });

    test('an unknown section key is ignored, not fatal', () {
      final body = homeFeedJson();
      (body['sections'] as List).add({
        'type': 'somethingAddedLater',
        'status': 'ok',
        'items': [
          {'id': 9}
        ],
      });

      final composition = HomeComposition.fromJson(body);

      // The registry is append-only by design. An older build must render the
      // sections it knows rather than refusing the whole page.
      expect(composition.sections, hasLength(5));
      expect(composition.isUsable, isTrue);
    });

    test('the assembled map form still parses, for the compatibility source',
        () {
      final composition = HomeComposition.fromJson({
        'sections': {
          'categories': [
            {'id': 3}
          ],
        },
      });
      expect(composition.itemsOf(HomeSectionType.categories), hasLength(1));
    });
  });

  group('canonical transport', () {
    test('fetchSection narrows /api/v1/home, never the registry', () async {
      final requests = <Uri>[];
      final client = V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            jsonEncode({'data': homeFeedJson()}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await HomeCompositionCanonicalDataSource(client)
          .fetchSection(HomeSectionType.promotions);

      expect(requests.single.path, '/api/v1/home');
      expect(requests.single.path, isNot(contains('/home/sections')));
      // …and it asks in the backend's spelling.
      expect(requests.single.queryParameters['sections'], 'banners');
    });

    test('fetchComposition hits /api/v1/home once', () async {
      final requests = <Uri>[];
      final client = V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            jsonEncode({'data': homeFeedJson()}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final composition =
          await HomeCompositionCanonicalDataSource(client).fetchComposition();

      // The performance half of the tab: one round trip, not one per section.
      expect(requests, hasLength(1));
      expect(requests.single.path, '/api/v1/home');
      expect(composition.isUsable, isTrue);
    });

    test('a failed section retry comes back as a value, not a throw', () async {
      final client = V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((_) async => http.Response('boom', 500)),
      );

      final section = await HomeCompositionCanonicalDataSource(client)
          .fetchSection(HomeSectionType.categories);

      expect(section, isA<HomeSectionFailed>());
    });
  });

  group('compatibility transport', () {
    test('one failing section does not take the others with it', () async {
      final source = HomeCompositionCompatibilityDataSource(
        loaders: {
          HomeSectionType.categories: () async => [
                {'id': 1}
              ],
          HomeSectionType.recentServices: () async =>
              throw const RetryableFailure(safeMessage: 'nope'),
        },
      );

      final composition = await source.fetchComposition();

      // The whole point of the tab: a throw is a value in one slot.
      expect(composition.isUsable, isTrue);
      expect(composition.sectionOf(HomeSectionType.recentServices),
          isA<HomeSectionFailed>());
      expect(composition.failures, hasLength(1));
    });

    test('a section with no loader is absent, not failed', () async {
      final source = HomeCompositionCompatibilityDataSource(
        loaders: {
          HomeSectionType.categories: () async => const [],
        },
      );

      final composition = await source.fetchComposition();

      // This transport never offered featuredServices, so there is nothing to
      // retry and a retry button would be a lie.
      expect(composition.sectionOf(HomeSectionType.featuredServices),
          isA<HomeSectionAbsent>());
      expect(composition.failures, isEmpty);
    });
  });

  group('repository routing and staleness', () {
    const routerOff = CanonicalRouter(availability: CanonicalAvailability());
    const routerOn = CanonicalRouter(
      availability: CanonicalAvailability(
        enabled: true,
        capabilities: {V1Capability.home},
      ),
    );

    test('every build today answers from compatibility', () async {
      final canonical = _StubSource(composition: _loadedWith());
      final compatibility = _StubSource(composition: _loadedWith());

      final repo = HomeCompositionRepository(
        compatibility: compatibility,
        canonical: canonical,
        router: routerOff,
      );
      await repo.load();

      expect(compatibility.compositionCalls, 1);
      expect(canonical.compositionCalls, 0);
      expect(repo.isCanonical, isFalse);
    });

    test('the capability moves the traffic and nothing else', () async {
      final canonical = _StubSource(composition: _loadedWith());
      final compatibility = _StubSource(composition: _loadedWith());

      final repo = HomeCompositionRepository(
        compatibility: compatibility,
        canonical: canonical,
        router: routerOn,
      );
      await repo.load();

      expect(canonical.compositionCalls, 1);
      expect(compatibility.compositionCalls, 0);
      expect(repo.isCanonical, isTrue);
    });

    test('a half-wired injector cannot route at a missing transport', () async {
      final compatibility = _StubSource(composition: _loadedWith());
      // Canonical omitted while the capability is ON.
      final repo = HomeCompositionRepository(
        compatibility: compatibility,
        router: routerOn,
      );
      await repo.load();

      expect(compatibility.compositionCalls, 1);
      expect(repo.isCanonical, isFalse);
    });

    test('a total failure serves the last good composition, marked stale',
        () async {
      var shouldFail = false;
      final flaky = _FlakySource(() => shouldFail);

      final repo = HomeCompositionRepository(compatibility: flaky);
      await repo.load();
      shouldFail = true;
      final second = await repo.load();

      expect(second.isUsable, isTrue);
      expect(second.hasStaleContent, isTrue,
          reason: 'stale content must never be presented as live');
    });

    test('with nothing cached, a total failure is the answer', () async {
      final repo = HomeCompositionRepository(
        compatibility: _StubSource(
          error: const RetryableFailure(safeMessage: 'offline'),
        ),
      );
      await expectLater(repo.load(), throwsA(isA<RetryableFailure>()));
    });

    test('clear() drops the cache so one account cannot see another', () async {
      final flaky = _FlakySource(() => false);
      final repo = HomeCompositionRepository(compatibility: flaky);
      await repo.load();
      expect(repo.cached, isNotNull);

      repo.clear();

      expect(repo.cached, isNull);
    });

    test('an all-failed composition is never cached as good', () async {
      const blank = HomeComposition(
        sections: {
          HomeSectionType.categories: HomeSectionFailed(
            HomeSectionType.categories,
            RetryableFailure(safeMessage: 'nope'),
          ),
        },
      );
      final repo = HomeCompositionRepository(
          compatibility: _StubSource(composition: blank));
      await repo.load();

      // Caching a blank composition would turn one bad launch into a permanent
      // "stale" badge over an empty screen.
      expect(repo.cached, isNull);
    });

    test('retrySection never throws', () async {
      final repo = HomeCompositionRepository(
        compatibility: _StubSource(
          error: const RetryableFailure(safeMessage: 'offline'),
        ),
      );
      final section = await repo.retrySection(HomeSectionType.categories);
      expect(section, isA<HomeSectionAbsent>());
    });
  });
}

/// Succeeds, then fails on demand, so staleness can be exercised.
class _FlakySource implements HomeCompositionDataSource {
  _FlakySource(this._shouldFail);

  final bool Function() _shouldFail;

  @override
  Future<HomeComposition> fetchComposition() async {
    if (_shouldFail()) {
      throw const RetryableFailure(safeMessage: 'offline');
    }
    return _loadedWith();
  }

  @override
  Future<HomeSection> fetchSection(HomeSectionType type) async =>
      HomeSectionAbsent(type);
}
