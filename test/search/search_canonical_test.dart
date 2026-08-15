/// TAB 06 — canonical search discovery.
///
/// The acceptance gate is three properties, and each has a test that would fail
/// if the property were lost:
///
///  1. search returns and navigates with canonical ids — asserted through the
///     qualified ref, because a bare integer is not an identity when three
///     entity types share one result set;
///  2. no duplicate visible Service caused by alias responses;
///  3. the existing Search design remains — no widget is touched, and both
///     transports feed the same card view model.
library;

import 'dart:convert';

import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/search/data/search_canonical_data_source.dart';
import 'package:client/modules/search/data/search_data_source.dart';
import 'package:client/modules/search/domain/search_hit.dart';
import 'package:client/modules/search/domain/search_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A hit in the shape `catalogSearchService` emits.
Map<String, dynamic> hitJson({
  String type = 'service',
  int id = 180,
  String name = 'Aircon Cleaning',
  String? context = 'Home Services › Aircon',
  bool? bookable = true,
  num? basePrice = 1500,
  int? categoryId = 3,
  int? subcategoryId = 7,
  int score = 3,
  String matchedTerm = 'air conditioning',
}) =>
    <String, dynamic>{
      'ref': '$type:$id',
      'type': type,
      'id': id,
      'name': name,
      'slug': name.toLowerCase().replaceAll(' ', '-'),
      'context': context,
      'imageUrl': null,
      'bookable': bookable,
      'status': 'active',
      'displayOrder': 0,
      'basePrice': basePrice,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'score': score,
      'matchedTerm': matchedTerm,
    };

Map<String, dynamic> resultsJson(List<Map<String, dynamic>> hits,
        {int? total, List<String> expanded = const ['aircon', 'air conditioning']}) =>
    <String, dynamic>{
      'query': 'aircon',
      'expandedTerms': expanded,
      'total': total ?? hits.length,
      'hits': hits,
      'counts': {'category': 0, 'subcategory': 0, 'service': hits.length},
    };

void main() {
  group('canonical identity', () {
    test('the qualified ref is the identity, not the bare integer', () {
      // services.id 180 and catalog_categories.id 180 are both 180. Keying on
      // the integer would merge them; keying on the ref cannot.
      final results = SearchResults.fromJson(resultsJson([
        hitJson(type: 'service', id: 180, name: 'Aircon Cleaning'),
        hitJson(
          type: 'category',
          id: 180,
          name: 'Home Services',
          context: null,
          bookable: null,
          basePrice: null,
        ),
      ]));

      expect(results.hits, hasLength(2));
      expect(results.hits.map((h) => h.ref), ['service:180', 'category:180']);
    });

    test('a missing ref is synthesised from type and id, never collided', () {
      final raw = hitJson()..remove('ref');
      final results = SearchResults.fromJson(resultsJson([raw]));
      expect(results.hits.single.ref, 'service:180');
    });

    test('an unknown entity type is skipped, not fatal', () {
      final results = SearchResults.fromJson(resultsJson([
        hitJson(),
        hitJson(type: 'provider', id: 9),
      ]));

      // The catalog may grow a level before the app does. Refusing the whole
      // response would empty a search that otherwise worked.
      expect(results.hits, hasLength(1));
      expect(results.hits.single.type, SearchEntityType.service);
    });
  });

  group('alias responses cannot duplicate a Service', () {
    test('two expanded terms hitting one Service render once', () {
      // The backend keeps the best score per row, so it does not emit this
      // today. The gate is about what the customer sees, and alias expansion is
      // exactly the mechanism that would produce it if that scoring moved.
      final results = SearchResults.fromJson(resultsJson([
        hitJson(matchedTerm: 'aircon', score: 3),
        hitJson(matchedTerm: 'air conditioning', score: 4),
      ]));

      expect(results.hits, hasLength(1));
      // First occurrence wins, preserving the server's ranking order.
      expect(results.hits.single.matchedTerm, 'aircon');
    });

    test('total keeps the server pre-truncation count', () {
      final results =
          SearchResults.fromJson(resultsJson([hitJson()], total: 47));
      expect(results.total, 47);
      expect(results.isTruncated, isTrue);
    });
  });

  group('canonical transport', () {
    V1ApiClient clientRecording(List<Uri> into, Object body) => V1ApiClient(
          baseUrl: 'https://api.example.test',
          httpClient: MockClient((request) async {
            into.add(request.url);
            return http.Response(
              jsonEncode({'data': body}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );

    test('queries /api/v1/search with q, types and limit', () async {
      final urls = <Uri>[];
      final source =
          SearchCanonicalDataSource(clientRecording(urls, resultsJson([hitJson()])));

      await source.query('aircon', limit: 20);

      expect(urls.single.path, '/api/v1/search');
      expect(urls.single.queryParameters['q'], 'aircon');
      // Explicit, so a server-side change to the default cannot silently alter
      // what this screen shows.
      expect(urls.single.queryParameters['types'],
          'category,subcategory,service');
      expect(urls.single.queryParameters['limit'], '20');
    });

    test('a too-short query is answered locally, without a round trip',
        () async {
      final urls = <Uri>[];
      final source =
          SearchCanonicalDataSource(clientRecording(urls, resultsJson([])));

      final results = await source.query('a');

      expect(urls, isEmpty, reason: 'the backend would answer this empty too');
      expect(results.isEmpty, isTrue);
    });

    test('expanded terms are carried through, so a hit is explainable',
        () async {
      final source = SearchCanonicalDataSource(
        clientRecording(<Uri>[], resultsJson([hitJson()])),
      );
      final results = await source.query('aircon');
      expect(results.expandedTerms, contains('air conditioning'));
    });

    test('a server failure throws rather than reading as no results', () async {
      final source = SearchCanonicalDataSource(V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((_) async => http.Response('boom', 500)),
      ));

      // "We could not ask" must not render as "nothing matched" — that would
      // be a lie about the catalog.
      await expectLater(source.query('aircon'), throwsA(isA<Object>()));
    });
  });

  group('the card view model survives either transport', () {
    test('a Service hit becomes a card, hierarchy split as the server built it',
        () {
      final hit = SearchHit.fromJson(hitJson());
      final card = SearchResult.fromHit(hit)!;

      expect(card.serviceId, 180);
      expect(card.categoryName, 'Home Services');
      expect(card.subcategoryName, 'Aircon');
      expect(card.hierarchyPath, 'Home Services › Aircon');
      expect(card.priceDisplay, '₱1500');
      // The list key stays the canonical id.
      expect(card.stableId, 'svc_180');
    });

    test('a Category hit is not coerced into a Service card', () {
      final hit = SearchHit.fromJson(hitJson(
        type: 'category',
        id: 3,
        name: 'Home Services',
        context: null,
        bookable: null,
        basePrice: null,
      ));

      // A card shows a price and routes to a detail page. A Category has
      // neither, so rendering one would lie about both.
      expect(SearchResult.fromHit(hit), isNull);
    });

    test('an unexpected context shape degrades the line, never the identity',
        () {
      final hit = SearchHit.fromJson(hitJson(context: 'Something Else'));
      final card = SearchResult.fromHit(hit)!;

      expect(card.categoryName, 'Something Else');
      expect(card.subcategoryName, '');
      // What matters is untouched.
      expect(card.serviceId, 180);
      expect(card.categoryId, 3);
    });
  });

  group('capability gating', () {
    test('search is off in every build today', () {
      const availability = CanonicalAvailability();
      expect(availability.isAvailable(V1Capability.search), isFalse);
      expect(availability.isFullyLegacy, isTrue);
    });

    test('the router selects canonical only when the capability is set', () {
      const off = CanonicalRouter(availability: CanonicalAvailability());
      const on = CanonicalRouter(
        availability: CanonicalAvailability(
          enabled: true,
          capabilities: {V1Capability.search},
        ),
      );

      expect(off.isCanonical(V1Capability.search), isFalse);
      expect(on.isCanonical(V1Capability.search), isTrue);
      // Enabling search must not enable anything else.
      expect(on.isCanonical(V1Capability.catalog), isFalse);
    });

    test('the minimum query length matches the backend', () {
      // catalogSearchService.MIN_QUERY_LENGTH — one character matches most of
      // the catalog, so the client must not send a query it knows is refused.
      expect(kMinSearchQueryLength, 2);
    });
  });
}
