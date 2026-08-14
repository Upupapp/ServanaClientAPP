import 'dart:convert';

import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/request_id.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/core/recovery/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const base = 'https://api.example.test';

  /// Records every request and answers with a scripted sequence.
  ({V1ApiClient client, List<http.BaseRequest> sent}) clientThat(
    List<http.Response> responses, {
    Future<String?> Function()? tokenProvider,
    void Function()? onUnauthorized,
  }) {
    final sent = <http.BaseRequest>[];
    var i = 0;
    final mock = MockClient((request) async {
      sent.add(request);
      final response = responses[i < responses.length ? i : responses.length - 1];
      i++;
      return response;
    });
    return (
      client: V1ApiClient(
        baseUrl: base,
        httpClient: mock,
        tokenProvider: tokenProvider,
        onUnauthorized: onUnauthorized,
      ),
      sent: sent,
    );
  }

  http.Response ok(Object body) =>
      http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

  group('URL construction', () {
    test('joins the base URL with a canonical path and never hard-codes a host',
        () async {
      final c = clientThat([ok({'data': {}})]);
      await c.client.get(V1Endpoints.notifications());
      expect(c.sent.single.url.toString(),
          'https://api.example.test/api/v1/notifications');
    });

    test('tolerates a base URL with a trailing slash', () async {
      final sent = <http.BaseRequest>[];
      final client = V1ApiClient(
        baseUrl: '$base/',
        httpClient: MockClient((r) async {
          sent.add(r);
          return ok({'data': {}});
        }),
      );
      await client.get(V1Endpoints.me());
      expect(sent.single.url.path, '/api/v1/me');
    });

    test('drops null query parameters instead of sending "null"', () async {
      final c = clientThat([ok({'data': {}})]);
      await c.client
          .get(V1Endpoints.notifications(), query: {'filter': null, 'limit': 10});
      final q = c.sent.single.url.queryParameters;
      expect(q.containsKey('filter'), isFalse);
      expect(q['limit'], '10');
    });

    test('percent-encodes path segments', () {
      // An id from a deep link containing a slash must not retarget the route.
      expect(V1Endpoints.booking('7/../admin'),
          '/api/v1/bookings/7%2F..%2Fadmin');
    });
  });

  group('headers', () {
    test('sends a unique request id on every request', () async {
      final c = clientThat([ok({'data': {}}), ok({'data': {}})]);
      await c.client.get(V1Endpoints.me());
      await c.client.get(V1Endpoints.me());
      final ids = c.sent
          .map((r) => r.headers[RequestIds.requestHeader])
          .whereType<String>()
          .toSet();
      expect(ids.length, 2, reason: 'request ids must not repeat');
      expect(ids.every((id) => id.startsWith('req_')), isTrue);
    });

    test('sends the correlation id across the calls of one intent', () async {
      final c = clientThat([ok({'data': {}}), ok({'data': {}})]);
      final intent = CorrelationContext.start();
      await c.client.get(V1Endpoints.me(), correlation: intent);
      await c.client.post(V1Endpoints.conversations(), correlation: intent);
      final correlations = c.sent
          .map((r) => r.headers[RequestIds.correlationHeader])
          .toSet();
      expect(correlations, <String>{intent.correlationId});
    });

    test('attaches the bearer token when one resolves', () async {
      final c = clientThat([ok({'data': {}})],
          tokenProvider: () async => 'tok_123');
      await c.client.get(V1Endpoints.me());
      expect(c.sent.single.headers['Authorization'], 'Bearer tok_123');
    });

    test('sends no Authorization header for an anonymous call', () async {
      final c = clientThat([ok({'data': {}})], tokenProvider: () async => null);
      await c.client.get(V1Endpoints.catalog());
      expect(c.sent.single.headers.containsKey('Authorization'), isFalse);
    });

    test('a throwing token provider does not fail the request', () async {
      // Secure storage can throw for reasons unrelated to this call, and a
      // public endpoint needs no token at all.
      final c = clientThat([ok({'data': {}})],
          tokenProvider: () async => throw StateError('keychain locked'));
      await c.client.get(V1Endpoints.catalog());
      expect(c.sent.single.headers.containsKey('Authorization'), isFalse);
    });

    test('forwards the idempotency key when supplied', () async {
      final c = clientThat([ok({'data': {}})]);
      await c.client.post(V1Endpoints.conversations(), idempotencyKey: 'key_1');
      expect(c.sent.single.headers['X-Idempotency-Key'], 'key_1');
    });
  });

  group('failure mapping', () {
    test('throws a typed failure rather than a status code', () async {
      final c = clientThat([
        http.Response('{"error":{"code":"BOOKING_TERMINAL","message":"Done"}}', 409)
      ]);
      await expectLater(
        c.client.get(V1Endpoints.booking('1')),
        throwsA(isA<StateConflictFailure>()
            .having((f) => f.code, 'code', 'BOOKING_TERMINAL')),
      );
    });

    test('a 401 notifies the session layer exactly once', () async {
      var calls = 0;
      final c = clientThat(
        [http.Response('{"error":{"code":"TOKEN_EXPIRED","message":"x"}}', 401)],
        onUnauthorized: () => calls++,
      );
      await expectLater(
          c.client.get(V1Endpoints.me()), throwsA(isA<AuthFailure>()));
      expect(calls, 1);
    });

    test('a 2xx with an unparseable body is unknown, not silently retried',
        () async {
      final c = clientThat([http.Response('not json', 200)]);
      await expectLater(
          c.client.get(V1Endpoints.me()), throwsA(isA<UnknownFailure>()));
      expect(c.sent.length, 1);
    });

    test('an empty 2xx body is a success with a null payload', () async {
      final c = clientThat([http.Response('', 204)]);
      final envelope = await c.client.post(V1Endpoints.notificationsReadAll());
      expect(envelope.data, isNull);
    });
  });

  group('retry classification', () {
    test('retries a GET on a retryable failure and then succeeds', () async {
      final c = clientThat([
        http.Response('{"error":{"code":"INTERNAL","message":"x"}}', 500),
        ok({'data': {'id': 1}}),
      ]);
      final envelope = await c.client.get(
        V1Endpoints.me(),
        retry: const RetryPolicy(
            maxAttempts: 2, baseDelay: Duration.zero, jitter: false),
      );
      expect(envelope.asMap['id'], 1);
      expect(c.sent.length, 2);
    });

    test('does not retry a non-retryable failure', () async {
      final c = clientThat([
        http.Response('{"error":{"code":"FORBIDDEN","message":"x"}}', 403),
      ]);
      await expectLater(
        c.client.get(V1Endpoints.me(),
            retry: const RetryPolicy(
                maxAttempts: 3, baseDelay: Duration.zero, jitter: false)),
        throwsA(isA<ForbiddenFailure>()),
      );
      expect(c.sent.length, 1);
    });

    test('never blind-retries a mutation without an idempotency key', () async {
      // The result of the first attempt is unknown; repeating it could double
      // a side effect. This is the C20 rule enforced at the transport.
      final c = clientThat([
        http.Response('{"error":{"code":"INTERNAL","message":"x"}}', 500),
        ok({'data': {}}),
      ]);
      await expectLater(
        c.client.post(V1Endpoints.conversations(),
            retry: const RetryPolicy(
                maxAttempts: 3, baseDelay: Duration.zero, jitter: false)),
        throwsA(isA<RetryableFailure>()),
      );
      expect(c.sent.length, 1, reason: 'the mutation must be attempted once');
    });

    test('retries a mutation that carries an idempotency key', () async {
      final c = clientThat([
        http.Response('{"error":{"code":"INTERNAL","message":"x"}}', 500),
        ok({'data': {'ok': true}}),
      ]);
      final envelope = await c.client.post(
        V1Endpoints.conversations(),
        idempotencyKey: 'key_1',
        retry: const RetryPolicy(
            maxAttempts: 2, baseDelay: Duration.zero, jitter: false),
      );
      expect(envelope.asMap['ok'], isTrue);
      expect(c.sent.length, 2);
      expect(
        c.sent.map((r) => r.headers['X-Idempotency-Key']).toSet(),
        <String>{'key_1'},
        reason: 'the key must be stable across attempts',
      );
    });

    test('a GET is retried by default without the caller opting in', () async {
      final c = clientThat([
        http.Response('{"error":{"code":"INTERNAL","message":"x"}}', 500),
        ok({'data': {}}),
      ]);
      await c.client.get(V1Endpoints.me());
      expect(c.sent.length, greaterThan(1));
    });
  });

  group('pagination', () {
    test('sends limit and offset and maps rows', () async {
      final c = clientThat([
        ok({
          'data': {
            'notifications': [
              {'id': 1},
              {'id': 2},
            ]
          },
          'meta': {
            'page': {'limit': 2, 'offset': 0, 'total': 5, 'hasMore': true}
          }
        })
      ]);
      final page = await c.client.getPage<int>(
        V1Endpoints.notifications(),
        mapItem: (row) => row['id'] as int,
        itemsKey: 'notifications',
        limit: 2,
      );
      expect(page.items, <int>[1, 2]);
      expect(page.hasMore, isTrue);
      expect(page.nextOffset, 2);
      final q = c.sent.single.url.queryParameters;
      expect(q['limit'], '2');
      expect(q['offset'], '0');
    });

    test('a response without meta is one complete page, not an endless one',
        () async {
      // Guessing hasMore would make a list paginate forever against a fixed
      // response.
      final c = clientThat([
        ok({
          'data': {
            'notifications': [
              {'id': 1}
            ]
          }
        })
      ]);
      final page = await c.client.getPage<int>(
        V1Endpoints.notifications(),
        mapItem: (row) => row['id'] as int,
        itemsKey: 'notifications',
      );
      expect(page.hasMore, isFalse);
      expect(page.nextOffset, isNull);
    });
  });
}
