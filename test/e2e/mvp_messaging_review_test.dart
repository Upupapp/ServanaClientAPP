/// TABs 10 and 11 — messaging the provider, and reviewing them afterwards.
///
/// Driven through the real store, repositories and screens over a transport
/// answering with the envelopes the backend actually writes. Every fixture
/// below was read out of the handler on the commit production runs, not
/// invented to agree with the client:
///
///  - `chat.controller.ts#getBookingConversation` — **404** with
///    `{success:false,message:"No conversation for this booking yet"}` when
///    there is none, **403** `"Not allowed for this booking"` when the actor is
///    not a participant.
///  - `customerReviewService.ts#getReviewEligibility` — `{bookingId, eligible,
///    reason, reviewId, reviewWindow, editableUntil, availableActions}`, with
///    `reason` one of BOOKING_NOT_OWNED / REVIEW_RESTRICTED / BOOKING_INVALID /
///    BOOKING_CANCELLED / BOOKING_NOT_COMPLETED.
///  - `providerLocationAccessController.ts#getBookingProvider` —
///    `{success, assigned, worker}`, where `assigned:false, worker:null` is a
///    normal state and not an error.
library;

import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/common/services/error_message_mapper.dart';
import 'package:client/modules/bookings/domain/booking_provider_profile.dart';
import 'package:client/modules/messaging/presentation/stores/messaging_store.dart';
import 'package:client/modules/review/data/reviews_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/screen_test_container.dart';

const _customerUid = 'test-customer-uid';
const _bookingId = '4242';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: const {'content-type': 'application/json'},
    );

/// A transport whose answer for the conversation lookup each test chooses.
class _Chat {
  _Chat({required this.conversationResponse});

  final http.Response Function() conversationResponse;
  Map<String, dynamic>? providerResponse;

  http.Client client() => MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/conversation')) return conversationResponse();
        if (path.contains('/provider')) {
          return _json(providerResponse ??
              {'success': true, 'assigned': false, 'worker': null});
        }
        if (path.contains('/messages')) {
          return _json({'success': true, 'messages': <dynamic>[]});
        }
        return _json(
            {'success': true, 'status': 'success', 'data': <dynamic>[]});
      });
}

Future<void> _signIn() async {
  const key = 'c2VydmFuYS10ZXN0LWNpcGhlci1rZXktMzJieXRlcyE=';
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async => switch (call.method) {
      'readAll' => <String, String>{},
      'read' => key,
      _ => null,
    },
  );
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(UserSessionAdapter());
  }
  await SessionService.saveSession(const UserSession(
    customerID: _customerUid,
    mobileNumber: '09171234567',
    fullname: 'Test Customer',
    token: 'test-token',
  ));
  dpLocator<AuthStateService>().update(AuthStatus.authenticated);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await SessionService.deleteSession();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
    await resetScreenDependencies();
  });

  group('TAB 10 · a conversation that cannot be opened says why', () {
    test('404 is the one case that means "no conversation yet"', () async {
      final chat = _Chat(
        conversationResponse: () => _json(
          {'success': false, 'message': 'No conversation for this booking yet'},
          404,
        ),
      );
      await registerScreenDependencies(client: chat.client());
      await _signIn();

      final conversation =
          await dpLocator<MessagingStore>().resolveConversation(_bookingId);

      expect(conversation, isNull,
          reason: 'null is reserved for genuinely absent, and this is it');
    });

    test('a 500 is NOT reported as "no conversation yet"', () async {
      // The defect. Every failure used to be caught in the store and returned
      // as null, and null is exactly what the chat screen renders as
      // "It opens once a provider accepts the booking." During an outage that
      // told every customer with a live thread that their provider had not
      // accepted — a fact about their booking the app had never learned.
      final chat = _Chat(
        conversationResponse: () =>
            _json({'success': false, 'message': 'Internal error'}, 500),
      );
      await registerScreenDependencies(client: chat.client());
      await _signIn();

      await expectLater(
        dpLocator<MessagingStore>().resolveConversation(_bookingId),
        throwsA(isA<ServanaApiException>()),
        reason: 'the failure must reach the screen, which has copy for it',
      );
    });

    test('a 403 is not reported as "no conversation yet" either', () async {
      final chat = _Chat(
        conversationResponse: () => _json(
          {'success': false, 'message': 'Not allowed for this booking'},
          403,
        ),
      );
      await registerScreenDependencies(client: chat.client());
      await _signIn();

      await expectLater(
        dpLocator<MessagingStore>().resolveConversation(_bookingId),
        throwsA(isA<ServanaApiException>()),
      );
    });
  });

  group('TAB 10 · the copy a failure produces', () {
    // The rule, asserted as a property over the statuses this endpoint really
    // returns, rather than one example of it.
    const lifecycleClaim = 'provider';

    test('no failure claims anything about the provider accepting', () {
      for (final status in const [401, 403, 408, 429, 500, 502, 503, 504]) {
        final message = ErrorMessageMapper.forConversation(
          'whatever the server wrote',
          statusCode: status,
        );
        expect(message.toLowerCase(), isNot(contains(lifecycleClaim)),
            reason: '$status must not make a claim about the booking');
        expect(message.trim(), isNotEmpty, reason: '$status');
      }
    });

    test('a 500 is not reported as a connectivity problem', () {
      final message =
          ErrorMessageMapper.forConversation('boom', statusCode: 500);
      expect(message.toLowerCase(), isNot(contains('offline')));
      expect(message.toLowerCase(), isNot(contains('connection')));
    });

    test('a dead socket IS reported as a connectivity problem', () {
      final message = ErrorMessageMapper.forConversation(
        "SocketException: Failed host lookup: 'api.servana.com.ph'",
      );
      expect(message, ErrorMessageMapper.forNetwork());
      expect(message, isNot(contains('api.servana.com.ph')));
    });

    test('a 403 says the conversation is not available to you, and no more',
        () {
      final message = ErrorMessageMapper.forConversation(
        'Not allowed for this booking',
        statusCode: 403,
      );
      expect(message, contains('not available to you'));
      // §58: nothing about who else is on the thread.
      expect(message.toLowerCase(), isNot(contains('participant')));
    });
  });

  group('TAB 10 · the provider has a name', () {
    test('it comes from the endpoint, not from the stubbed job-order surface',
        () async {
      // `HttpBackend.getJobOrderEmployees` returns [] unconditionally in every
      // release build, so the chat header showed "Service Provider" for a
      // provider the booking screen could name.
      final chat = _Chat(
        conversationResponse: () => _json({
          'success': true,
          'conversation': {'id': 77, 'bookingId': 4242},
        }),
      )..providerResponse = {
          'success': true,
          'assigned': true,
          'worker': {
            'firstName': 'Juan',
            'lastName': 'Dela Cruz',
            'phoneNumber': '+63 917 000 1234',
          },
        };
      await registerScreenDependencies(client: chat.client());
      await _signIn();

      final response =
          await dpLocator<ServanaApiClient>().getBookingProvider(4242);
      final provider = BookingProviderProfile.fromResponse(response);

      expect(provider.assigned, isTrue);
      expect(provider.name, 'Juan Dela Cruz');
      expect(provider.phone, '+63 917 000 1234');
    });

    test('"not matched yet" is a state, not a name', () {
      final provider = BookingProviderProfile.fromResponse(
        const {'success': true, 'assigned': false, 'worker': null},
      );

      expect(provider.assigned, isFalse);
      // Never a placeholder. A caller that wants "Service Provider" on screen
      // must say so itself rather than be handed it as if the server answered.
      expect(provider.name, isNull);
    });

    test('assigned with an unprojectable profile is distinct from unassigned',
        () {
      final provider = BookingProviderProfile.fromResponse(
        const {'success': true, 'assigned': true, 'worker': null},
      );

      expect(provider.assigned, isTrue);
      expect(provider.name, isNull);
    });

    test('falls back through the name fields the projection may carry', () {
      expect(
        BookingProviderProfile.fromResponse(const {
          'success': true,
          'assigned': true,
          'worker': {'name': 'Servana Pro'},
        }).name,
        'Servana Pro',
      );
      expect(
        BookingProviderProfile.fromResponse(const {
          'success': true,
          'assigned': true,
          'worker': {'firstName': '  ', 'lastName': '  ', 'fullName': 'Ana R.'},
        }).name,
        'Ana R.',
      );
    });
  });

  group('TAB 11 · review eligibility is the backend\'s verdict', () {
    late http.Response Function() eligibility;

    Future<void> arrange(http.Response Function() response) async {
      eligibility = response;
      await registerScreenDependencies(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/review-eligibility')) {
            return eligibility();
          }
          // `GET /api/bookings/:id/reviews` 404s with REVIEW_NOT_FOUND when
          // the booking has not been reviewed. `reviewOrEligibility` fires
          // BOTH reads together and folds them, so answering this one with a
          // generic empty envelope makes the fold believe a review exists and
          // report ALREADY_REVIEWED — which is what a first draft of this test
          // did, and it looked like an eligibility parsing bug.
          if (request.url.path.endsWith('/reviews')) {
            return _json({'error': 'REVIEW_NOT_FOUND'}, 404);
          }
          return _json({'success': true, 'data': <dynamic>[]});
        }),
      );
      await _signIn();
    }

    test('a booking that has not been completed is not reviewable', () async {
      await arrange(() => _json({
            'bookingId': _bookingId,
            'eligible': false,
            'reason': 'BOOKING_NOT_COMPLETED',
            'reviewId': null,
            'reviewWindow': null,
            'editableUntil': null,
            'availableActions': <String>[],
          }));

      final result =
          await dpLocator<ReviewsRepository>().getEligibility(_bookingId);

      expect(result.eligible, isFalse);
      // The reason has to survive the parse: it is what the ineligible screen
      // renders instead of inventing an explanation.
      expect(result.reason, isNotNull);
    });

    test('a completed booking with a provider is reviewable', () async {
      await arrange(() => _json({
            'bookingId': _bookingId,
            'eligible': true,
            'reason': null,
            'reviewId': null,
            // `opensAt`/`closesAt`, not `opens`/`closes`. The service's own
            // `reviewWindowFor` returns the short names INTERNALLY and the
            // response renames them on the way out — so reading the helper
            // rather than the response would have declared a contract mismatch
            // that is not there.
            'reviewWindow': {
              'opensAt': '2026-08-20T00:00:00.000Z',
              'closesAt': '2026-09-03T00:00:00.000Z',
            },
            'editableUntil': '2026-08-27T00:00:00.000Z',
            'availableActions': ['CREATE'],
          }));

      final result =
          await dpLocator<ReviewsRepository>().getEligibility(_bookingId);

      expect(result.eligible, isTrue);
      expect(result.reviewWindowOpensAt, isNotNull,
          reason: 'the window keys must match what the response writes');
      expect(result.reviewWindowClosesAt, isNotNull);
    });

    test('every refusal reason the handler can return survives the parse',
        () async {
      // Read out of `getReviewEligibility`. A reason the client drops is a
      // screen that has to invent why the customer cannot review — the same
      // defect as a chat blaming the provider.
      for (final reason in const [
        'BOOKING_NOT_OWNED',
        'REVIEW_RESTRICTED',
        'BOOKING_INVALID',
        'BOOKING_CANCELLED',
        'BOOKING_NOT_COMPLETED',
      ]) {
        await arrange(() => _json({
              'bookingId': _bookingId,
              'eligible': false,
              'reason': reason,
              'reviewId': null,
              'reviewWindow': null,
              'editableUntil': null,
              'availableActions': <String>[],
            }));

        final result =
            await dpLocator<ReviewsRepository>().getEligibility(_bookingId);

        expect(result.eligible, isFalse, reason: reason);
        expect(result.reason, isNotNull, reason: 'reason dropped: $reason');
        await resetScreenDependencies();
      }
    });

    test('a transport failure is not read as ineligibility', () async {
      // The messaging defect, one module over: if a 500 came back as
      // "not eligible", a customer whose review the server never refused would
      // be told they cannot leave one.
      await arrange(() => _json({'error': 'SERVER_ERROR'}, 500));

      await expectLater(
        dpLocator<ReviewsRepository>().getEligibility(_bookingId),
        throwsA(anything),
        reason: 'the form has a separate failed state, and it must reach it',
      );
    });
  });
}
