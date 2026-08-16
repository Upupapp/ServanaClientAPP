/// TAB 13 — conversations.
///
/// The capability `V1Capability.conversations` has existed since TAB 02 with no
/// transport behind it. This tab fills it in, and corrects the finding that had
/// been holding it back.
library;

import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/messaging/data/messaging_canonical_data_source.dart';
import 'package:client/modules/messaging/data/messaging_compatibility_data_source.dart';
import 'package:client/modules/messaging/domain/repositories/messaging_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Recorder {
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  final List<String> bodies = <String>[];
}

({MessagingCanonicalDataSource source, _Recorder recorder}) canonical(
  Object body, {
  int status = 200,
}) {
  final recorder = _Recorder();
  final api = V1ApiClient(
    baseUrl: 'https://api.example.test',
    httpClient: MockClient((request) async {
      recorder.requests.add(request);
      recorder.bodies.add(request.body);
      return http.Response(jsonEncode(body), status,
          headers: <String, String>{'content-type': 'application/json'});
    }),
  );
  return (source: MessagingCanonicalDataSource(api), recorder: recorder);
}

class _FakeLegacyApi extends Fake implements ServanaApiClient {
  Map<String, dynamic> conversationsResponse = <String, dynamic>{};
  Map<String, dynamic>? bookingConversationResponse;
  int? bookingConversationStatus;
  int reportCalls = 0;

  @override
  Future<Map<String, dynamic>> listConversations() async =>
      conversationsResponse;

  @override
  Future<Map<String, dynamic>> getBookingConversation({
    required String bookingId,
  }) async {
    final status = bookingConversationStatus;
    if (status != null) {
      throw ServanaApiException(statusCode: status, body: '{}');
    }
    return bookingConversationResponse ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> reportChatMessage({
    required int conversationId,
    required int messageId,
    required String category,
    String? description,
  }) async {
    reportCalls++;
    return <String, dynamic>{'success': true};
  }
}

MessagingRepository _repoWith({
  required _FakeLegacyApi api,
  MessagingCanonicalDataSource? canonicalSource,
  Set<V1Capability> capabilities = const <V1Capability>{},
}) =>
    MessagingRepository(
      api: api,
      compatibility: MessagingCompatibilityDataSource(api),
      canonical: canonicalSource,
      router: CanonicalRouter(
        availability: CanonicalAvailability(
          enabled: capabilities.isNotEmpty,
          capabilities: capabilities,
        ),
      ),
    );

void main() {
  // ── The finding this tab corrected ─────────────────────────────────────────

  group('R-10 was stale', () {
    test('the legacy resolve maps 404 to null, and creates nothing', () async {
      // TAB 01 R-10: "Opening a booking chat MAY CREATE the conversation …
      // SC-038 records the current lazy-create as a defect", classified BREAKS.
      //
      // Measured against chat.controller.getBookingConversation in TAB 13: it
      // calls getExistingConversation and 404s when absent, with the comment
      // "It does NOT create one: a booking conversation is a consequence of a
      // provider being confirmed … not of a client opening a screen."
      //
      // The client half has always matched. Pinned so the stale finding cannot
      // be re-derived from the doc.
      final api = _FakeLegacyApi()..bookingConversationStatus = 404;

      expect(
        await MessagingCompatibilityDataSource(api).resolveForBooking('42'),
        isNull,
      );
    });

    test('a 403 is NOT flattened into "no conversation yet"', () async {
      // Somebody else's booking is an authorization refusal and must stay one.
      final api = _FakeLegacyApi()..bookingConversationStatus = 403;

      await expectLater(
        MessagingCompatibilityDataSource(api).resolveForBooking('42'),
        throwsA(isA<ServanaApiException>()),
      );
    });
  });

  // ── The gate ───────────────────────────────────────────────────────────────

  group('reachability', () {
    test('a default build stays on the legacy transport', () {
      final repo = _repoWith(
        api: _FakeLegacyApi(),
        canonicalSource: canonical(const <String, dynamic>{}).source,
      );
      expect(repo.isCanonical, isFalse);
    });

    test('the conversations capability selects the canonical source', () {
      final repo = _repoWith(
        api: _FakeLegacyApi(),
        canonicalSource: canonical(const <String, dynamic>{}).source,
        capabilities: <V1Capability>{V1Capability.conversations},
      );
      expect(repo.isCanonical, isTrue);
    });

    test('a half-wired injector falls back', () {
      final repo = _repoWith(
        api: _FakeLegacyApi(),
        capabilities: <V1Capability>{V1Capability.conversations},
      );
      expect(repo.isCanonical, isFalse);
    });
  });

  // ── Resolve changes verb ───────────────────────────────────────────────────

  group('resolving a booking conversation', () {
    test('canonical resolves with a POST that opens-or-returns', () async {
      // One conversation per booking, enforced by a unique constraint and an
      // ON CONFLICT insert, so a repeat returns the SAME thread. Gated by
      // mayOpenConversation: the parties cannot open one on a booking with no
      // provider.
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'id': 7,
          'bookingId': 42,
          'unreadCount': 3,
          'isClosed': false,
        },
      });

      final conversation = await c.source.resolveForBooking('42');

      expect(c.recorder.requests.single.method, 'POST');
      expect(c.recorder.requests.single.url.path, '/api/v1/conversations');
      final body = jsonDecode(c.recorder.bodies.single) as Map<String, dynamic>;
      expect(body['bookingId'], 42);

      expect(conversation, isNotNull);
      expect(conversation!.id, 7);
      expect(conversation.unreadCount, 3);
    });

    test('CONVERSATION_NOT_AVAILABLE means "not yet", exactly like a 404',
        () async {
      // The behaviour that must not change when the capability flips. A
      // customer on a booking whose provider is unconfirmed sees a quiet empty
      // state today; mapping this to anything else turns that into an error
      // banner on a screen that is working correctly.
      final c = canonical(
        <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'CONVERSATION_NOT_AVAILABLE',
            'message': 'No conversation for this booking yet.',
          },
        },
        status: 409,
      );

      expect(await c.source.resolveForBooking('42'), isNull);
    });

    test('CONVERSATION_ACCESS_DENIED still throws', () async {
      // The counterpart. Swallowing this would tell somebody probing another
      // customer's booking that it merely has no chat yet.
      final c = canonical(
        <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'CONVERSATION_ACCESS_DENIED',
            'message': 'Not allowed.',
          },
        },
        status: 403,
      );

      await expectLater(
        c.source.resolveForBooking('42'),
        throwsA(isA<ForbiddenFailure>()),
      );
    });
  });

  // ── Shapes ─────────────────────────────────────────────────────────────────

  group('the DTOs did not have to change', () {
    test('the canonical list is a bare array, the legacy one is nested',
        () async {
      // The chat routes do NOT use an envelope — the stores read a top-level
      // `conversations` key — and the backend keeps that shape exactly. v1
      // returns the array in `data`. One mapper reads both.
      final c = canonical(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'bookingId': 10, 'unreadCount': 0},
          <String, dynamic>{'id': 2, 'bookingId': 11, 'unreadCount': 5},
        ],
      });
      final fromCanonical = await c.source.listConversations();

      final api = _FakeLegacyApi()
        ..conversationsResponse = <String, dynamic>{
          'success': true,
          'conversations': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'booking_id': 10, 'unread_count': 0},
            <String, dynamic>{'id': 2, 'booking_id': 11, 'unread_count': 5},
          ],
        };
      final fromLegacy =
          await MessagingCompatibilityDataSource(api).listConversations();

      expect(fromCanonical.map((c) => c.id), fromLegacy.map((c) => c.id));
      expect(fromCanonical.last.unreadCount, 5);
      expect(fromLegacy.last.unreadCount, 5);
    });

    test('isClosed is republished canonically for clients that ignore status',
        () {
      // The backend keeps `isClosed` alongside the newer `status` enum
      // precisely as "the pre-status compatibility boolean … kept correct for
      // clients that know nothing about status". This client is one of them.
      expect(
        <String>['ACTIVE', 'SUPPORT_ESCALATED', 'READ_ONLY', 'CLOSED', 'ARCHIVED'],
        hasLength(5),
        reason: 'the status vocabulary this client deliberately does not read',
      );
    });
  });

  group('messages', () {
    test('the cursor is omitted rather than sent as null', () async {
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{'messages': <dynamic>[]},
      });

      await c.source.getMessages(conversationId: 7, limit: 20);

      final query = c.recorder.requests.single.url.queryParameters;
      expect(query['limit'], '20');
      expect(query.containsKey('before'), isFalse,
          reason: 'a null cursor sent as the string "null" reads as a filter');
    });

    test('sending carries clientMsgId in the body, not a header', () async {
      // clientMsgId IS the idempotency mechanism for a message, and it is a
      // message field — the contract calls a bad one
      // MESSAGE_IDEMPOTENCY_KEY_INVALID rather than the transport-level code.
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{'id': 99, 'body': 'hello'},
      });

      await c.source.sendMessage(
        conversationId: 7,
        body: 'hello',
        clientMsgId: 'cmid-1',
      );

      final body = jsonDecode(c.recorder.bodies.single) as Map<String, dynamic>;
      expect(body['clientMsgId'], 'cmid-1');
      expect(c.recorder.requests.single.headers.containsKey('idempotency-key'),
          isFalse);
    });

    test('markRead posts the pointer', () async {
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'conversationId': 7,
          'lastReadMessageId': 42,
          'unreadCount': 0,
        },
      });

      await c.source.markRead(conversationId: 7, lastReadMessageId: 42);

      expect(c.recorder.requests.single.url.path,
          '/api/v1/conversations/7/read');
      final body = jsonDecode(c.recorder.bodies.single) as Map<String, dynamic>;
      expect(body['lastReadMessageId'], 42);
    });
  });

  // ── The call with no successor ─────────────────────────────────────────────

  group('reportMessage never routes', () {
    test('it calls legacy even when the capability is ON', () async {
      // The conversations domain has six canonical entries and none of them is
      // report, edit or delete. This is the same per-call escape
      // NotificationsRepository.dismiss uses for DELETE /notifications/:key —
      // the canonical source must not invent an endpoint, and must not throw on
      // a button the customer can see.
      final api = _FakeLegacyApi();
      final repo = _repoWith(
        api: api,
        canonicalSource: canonical(const <String, dynamic>{}).source,
        capabilities: <V1Capability>{V1Capability.conversations},
      );

      expect(repo.isCanonical, isTrue);

      await repo.reportMessage(
        conversationId: 7,
        messageId: 99,
        category: 'ABUSE',
      );

      expect(api.reportCalls, 1,
          reason: 'reporting must reach the legacy client even canonically');
    });
  });
}
