/// The header name a canonical mutation carries.
///
/// This is the whole reason TAB 10 could not begin with cancel: the client sent
/// `X-Idempotency-Key`, the canonical routes read `idempotency-key`, and
/// nothing in between reported the mismatch. A caller believed it was protected
/// against a double-submit and was not.
///
/// The evidence is `servana_api/src/api/v1/envelope.ts`:
///
///     export const IDEMPOTENCY_HEADER = 'idempotency-key';
///     export function readIdempotencyKey(req) {
///       const raw = req.get(IDEMPOTENCY_HEADER);          // and no other name
///       if (!/^[A-Za-z0-9_.:-]{8,128}$/.test(raw)) throw IDEMPOTENCY_KEY_INVALID;
///     }
///
/// Both halves are pinned here — the name and the shape — because a key that
/// arrives under the right name in the wrong format is rejected just as
/// completely as one that never arrives.
library;

import 'dart:convert';

import 'package:client/core/network/request_id.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.BaseRequest> sent;

  V1ApiClient clientReturning(Object body, {int status = 200}) {
    sent = <http.BaseRequest>[];
    return V1ApiClient(
      baseUrl: 'https://api.example.test',
      httpClient: MockClient((request) async {
        sent.add(request);
        return http.Response(jsonEncode(body), status,
            headers: <String, String>{'content-type': 'application/json'});
      }),
    );
  }

  group('the canonical idempotency header', () {
    test('is sent as Idempotency-Key', () async {
      final api =
          clientReturning(<String, dynamic>{'data': <String, dynamic>{}});

      await api.post('/api/v1/bookings/42/cancel',
          body: <String, dynamic>{'reason': 'x'},
          idempotencyKey: 'idm_abc12345');

      // http.Request lower-cases header names, which is what the wire does too.
      final headers = sent.single.headers;
      expect(headers['idempotency-key'], 'idm_abc12345');
    });

    test('is NOT sent as X-Idempotency-Key', () async {
      // The legacy spelling. `readIdempotencyKey` never looks at it, so a key
      // sent under this name is indistinguishable from no key at all — the
      // exact defect this tab found and the reason to pin it rather than
      // assume the fix stays.
      final api =
          clientReturning(<String, dynamic>{'data': <String, dynamic>{}});

      await api.post('/api/v1/bookings/42/cancel',
          idempotencyKey: 'idm_abc12345');

      expect(sent.single.headers.containsKey('x-idempotency-key'), isFalse);
    });

    test('is absent entirely when no key is supplied', () async {
      // Absent and malformed are different to the backend: absent is allowed on
      // these routes, malformed is IDEMPOTENCY_KEY_INVALID. An empty header
      // would turn one into the other.
      final api =
          clientReturning(<String, dynamic>{'data': <String, dynamic>{}});

      await api.post('/api/v1/bookings/42/otp/request');

      expect(sent.single.headers.containsKey('idempotency-key'), isFalse);
    });
  });

  group('key shape', () {
    test('the generator produces keys the backend accepts', () {
      // ^[A-Za-z0-9_.:-]{8,128}$ — mirrored from envelope.ts. Generating a key
      // the server rejects would spend a round trip to be told our own client
      // is broken.
      for (var i = 0; i < 200; i++) {
        final key = RequestIds.newIdempotencyKey();
        expect(idempotencyKeyPattern.hasMatch(key), isTrue,
            reason: '"$key" is not an acceptable Idempotency-Key');
      }
    });

    test('keys are distinct across calls', () {
      // A stable key is the caller's job; the generator's job is never to
      // collide, or two unrelated cancels would replay each other's result.
      final keys = <String>{
        for (var i = 0; i < 500; i++) RequestIds.newIdempotencyKey(),
      };
      expect(keys.length, 500);
    });

    test('a malformed key trips an assertion rather than being sent', () async {
      final api =
          clientReturning(<String, dynamic>{'data': <String, dynamic>{}});

      // Too short for the 8-character floor, and `@` is outside the alphabet.
      expect(
        () => api.post('/api/v1/bookings/42/cancel', idempotencyKey: 'a@b'),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
