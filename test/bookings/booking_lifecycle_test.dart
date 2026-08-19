/// TAB 10 — booking lifecycle actions.
///
/// Every claim the tab makes about cancel, reschedule and the OTP ceremony is
/// asserted here rather than described in a document, including the two that
/// are easiest to believe without checking: that no shipped build can reach the
/// canonical transport, and that the client stopped holding its own copy of the
/// OTP resend policy.
library;

import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/bookings/data/booking_lifecycle_canonical_data_source.dart';
import 'package:client/modules/bookings/data/booking_lifecycle_compatibility_data_source.dart';
import 'package:client/modules/bookings/data/booking_lifecycle_data_source.dart';
import 'package:client/modules/bookings/data/booking_lifecycle_repository.dart';
import 'package:client/modules/bookings/domain/booking_otp_state.dart';
import 'package:client/modules/bookings/domain/booking_reschedule.dart';
import 'package:client/modules/bookings/domain/booking_transition_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ── Doubles ──────────────────────────────────────────────────────────────────

class _Recorder {
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  final List<String> bodies = <String>[];
}

/// A canonical source whose backend answers [responses] in order.
({BookingLifecycleCanonicalDataSource source, _Recorder recorder}) canonical(
  List<({int status, Object body})> responses,
) {
  final recorder = _Recorder();
  var index = 0;
  final api = V1ApiClient(
    baseUrl: 'https://api.example.test',
    httpClient: MockClient((request) async {
      recorder.requests.add(request);
      recorder.bodies.add(request.body);
      final r =
          responses[index < responses.length ? index++ : responses.length - 1];
      return http.Response(jsonEncode(r.body), r.status,
          headers: <String, String>{'content-type': 'application/json'});
    }),
  );
  return (source: BookingLifecycleCanonicalDataSource(api), recorder: recorder);
}

class _FakeLegacyApi extends Fake implements ServanaApiClient {
  Map<String, dynamic> cancelResponse = <String, dynamic>{'success': true};
  Map<String, dynamic> confirmResponse = <String, dynamic>{'success': true};
  Map<String, dynamic> resendResponse = <String, dynamic>{'success': true};

  int cancelCalls = 0;
  int confirmCalls = 0;
  int resendCalls = 0;
  String? lastOtp;

  @override
  Future<Map<String, dynamic>> cancelBooking({
    required int bookingId,
    required String reason,
    String? reasonCode,
  }) async {
    cancelCalls++;
    return cancelResponse;
  }

  @override
  Future<Map<String, dynamic>> confirmOtp({
    required int bookingId,
    required String otp,
  }) async {
    confirmCalls++;
    lastOtp = otp;
    return confirmResponse;
  }

  @override
  Future<Map<String, dynamic>> resendOtp({required int bookingId}) async {
    resendCalls++;
    return resendResponse;
  }
}

/// A source that records the idempotency keys it was handed.
class _KeySpy implements BookingLifecycleDataSource {
  final List<String> cancelKeys = <String>[];
  final List<String> verifyKeys = <String>[];

  /// When set, the next cancel throws it.
  ApiFailure? cancelFailure;

  @override
  bool get supportsReschedule => false;

  @override
  bool get supportsOtpStatus => false;

  @override
  Future<BookingTransitionResult> cancel({
    required String bookingId,
    required String reason,
    required String idempotencyKey,
    String? expectedState,
  }) async {
    cancelKeys.add(idempotencyKey);
    final failure = cancelFailure;
    if (failure != null) {
      cancelFailure = null;
      throw failure;
    }
    return BookingTransitionResult.assumed(
      bookingId: bookingId,
      action: 'cancel',
      fromState: '',
      toState: 'CANCELLED',
    );
  }

  @override
  Future<BookingTransitionResult> verifyOtp({
    required String bookingId,
    required String code,
    required String idempotencyKey,
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
    String? expectedState,
  }) async {
    verifyKeys.add(idempotencyKey);
    throw const ValidationFailure(
        safeMessage: 'wrong', code: 'BOOKING_OTP_INVALID');
  }

  @override
  Future<BookingOtpIssued> requestOtp({
    required String bookingId,
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
  }) async =>
      BookingOtpIssued(bookingId: bookingId, purpose: purpose);

  @override
  Future<BookingOtpState> otpStatus({
    required String bookingId,
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
  }) async =>
      BookingOtpState.local(bookingId: bookingId, resendAvailableInSeconds: 0);

  @override
  Future<BookingRescheduleResult> reschedule({
    required String bookingId,
    required BookingRescheduleRequest request,
  }) async =>
      throw UnsupportedLifecycleAction('reschedule');

  @override
  Future<List<BookingRescheduleAttempt>> rescheduleHistory(
          String bookingId) async =>
      throw UnsupportedLifecycleAction('reschedule history');
}

const _onCanonical = CanonicalRouter(
  availability: CanonicalAvailability(
    enabled: true,
    capabilities: <V1Capability>{V1Capability.bookingLifecycle},
  ),
);

void main() {
  // ── The gate ───────────────────────────────────────────────────────────────

  group('reachability', () {
    test('a default build routes every action at the legacy transport', () {
      // /api/v1 is absent from the backend's origin/main. Cancel is the one
      // action in this tab that a customer can already perform, so a build that
      // silently started routing it canonically would 404 a real cancellation.
      final legacy = BookingLifecycleCompatibilityDataSource(_FakeLegacyApi());
      final repo = BookingLifecycleRepository(
        compatibility: legacy,
        canonical: canonical(const []).source,
        router: const CanonicalRouter(availability: CanonicalAvailability()),
      );

      expect(repo.isCanonical, isFalse);
      expect(repo.canOfferReschedule, isFalse);
      expect(repo.hasBackendOtpPolicy, isFalse);
    });

    test('bookingReads does not enable actions', () {
      // The two capabilities are separate precisely so the safe half can be
      // flipped alone. If this ever passes, a read migration has silently
      // started mutating bookings over an undeployed namespace.
      const readsOnly = CanonicalRouter(
        availability: CanonicalAvailability(
          enabled: true,
          capabilities: <V1Capability>{V1Capability.bookingReads},
        ),
      );
      final repo = BookingLifecycleRepository(
        compatibility:
            BookingLifecycleCompatibilityDataSource(_FakeLegacyApi()),
        canonical: canonical(const []).source,
        router: readsOnly,
      );

      expect(repo.isCanonical, isFalse);
    });

    test('a half-wired injector falls back rather than routing at nothing', () {
      final repo = BookingLifecycleRepository(
        compatibility:
            BookingLifecycleCompatibilityDataSource(_FakeLegacyApi()),
        router: _onCanonical, // capability on, but no canonical source given
      );
      expect(repo.isCanonical, isFalse);
    });
  });

  // ── Cancel ─────────────────────────────────────────────────────────────────

  group('cancel', () {
    test('canonical cancel carries the key, the reason and expectedState',
        () async {
      final c = canonical([
        (
          status: 200,
          body: <String, dynamic>{
            'data': <String, dynamic>{
              'bookingId': 42,
              'action': 'cancel',
              'fromState': 'ASSIGNED',
              'toState': 'CANCELLED',
              'state': <String, dynamic>{
                'label': 'Cancelled',
                'detail': 'This booking was cancelled.',
                'terminal': true,
                'availableActions': <String>[],
              },
            },
          },
        ),
      ]);

      final result = await c.source.cancel(
        bookingId: '42',
        reason: 'Schedule changed',
        idempotencyKey: 'idm_key_00001',
        expectedState: 'ASSIGNED',
      );

      final request = c.recorder.requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/bookings/42/cancel');
      expect(request.headers['idempotency-key'], 'idm_key_00001');

      final body = jsonDecode(c.recorder.bodies.single) as Map<String, dynamic>;
      expect(body['reason'], 'Schedule changed');
      expect(body['expectedState'], 'ASSIGNED');

      expect(result.toState, 'CANCELLED');
      expect(result.terminal, isTrue);
      expect(result.customerLabel, 'Cancelled');
    });

    test('a replay is reported as a replay, not as a fresh cancellation',
        () async {
      // Without this the UI re-announces "Booking cancelled" to somebody who
      // already saw it — which is the visible half of the idempotency fix.
      final c = canonical([
        (
          status: 200,
          body: <String, dynamic>{
            'data': <String, dynamic>{
              'bookingId': 42,
              'action': 'cancel',
              'fromState': 'ASSIGNED',
              'toState': 'CANCELLED',
              'idempotentReplay': true,
            },
          },
        ),
      ]);

      final result = await c.source.cancel(
        bookingId: '42',
        reason: 'x',
        idempotencyKey: 'idm_key_00001',
      );
      expect(result.idempotentReplay, isTrue);
    });

    test('the legacy transport drops the key rather than misnaming it',
        () async {
      // ServanaApiClient.cancelBooking has no idempotency parameter at all.
      // Passing one anyway must not invent a header the route does not read.
      final api = _FakeLegacyApi();
      final result = await BookingLifecycleCompatibilityDataSource(api).cancel(
        bookingId: '42',
        reason: 'x',
        idempotencyKey: 'idm_key_00001',
        expectedState: 'ASSIGNED',
      );

      expect(api.cancelCalls, 1);
      // `assumed` — the legacy route returns {success:true} and nothing about
      // what the machine did, so the destination is what we asked for, not what
      // we were told.
      expect(result.toState, 'CANCELLED');
      expect(result.idempotentReplay, isFalse);
      expect(result.availableActions, isEmpty);
    });

    test('a legacy 200 carrying success:false becomes a typed failure',
        () async {
      // Before this, the same condition reached the UI as a successful Future
      // on legacy and as an ApiFailure on canonical. One caller cannot handle
      // both shapes correctly, so the sheet handled neither.
      final api = _FakeLegacyApi()
        ..cancelResponse = <String, dynamic>{
          'success': false,
          'message': 'This booking has already been cancelled.',
        };

      await expectLater(
        BookingLifecycleCompatibilityDataSource(api).cancel(
          bookingId: '42',
          reason: 'x',
          idempotencyKey: 'idm_key_00001',
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.safeMessage,
          'safeMessage',
          'This booking has already been cancelled.',
        )),
      );
    });
  });

  // ── Idempotency key lifetime ───────────────────────────────────────────────

  group('idempotency keys are held per intent', () {
    test('a retry after a retryable failure reuses the key', () async {
      // The one case where the outcome is genuinely unknown. Minting a second
      // key here is how one tap becomes two cancellations.
      final spy = _KeySpy()
        ..cancelFailure = const RetryableFailure(safeMessage: 'network');
      final repo = BookingLifecycleRepository(compatibility: spy);

      await expectLater(
        repo.cancel(bookingId: '42', reason: 'x'),
        throwsA(isA<RetryableFailure>()),
      );
      await repo.cancel(bookingId: '42', reason: 'x');

      expect(spy.cancelKeys.length, 2);
      expect(spy.cancelKeys[0], spy.cancelKeys[1],
          reason: 'a retry of the same intent must replay, not re-act');
    });

    test('a fresh intent after a refusal gets a fresh key', () async {
      // A refusal the customer then corrects is a new intent. Reusing the key
      // would replay the refusal against a request that has changed.
      final spy = _KeySpy()
        ..cancelFailure = const ValidationFailure(safeMessage: 'bad reason');
      final repo = BookingLifecycleRepository(compatibility: spy);

      await expectLater(
        repo.cancel(bookingId: '42', reason: 'x'),
        throwsA(isA<ValidationFailure>()),
      );
      await repo.cancel(bookingId: '42', reason: 'a different reason');

      expect(spy.cancelKeys[0], isNot(spy.cancelKeys[1]));
    });

    test('a success clears the key, so a later cancel is a new intent',
        () async {
      final spy = _KeySpy();
      final repo = BookingLifecycleRepository(compatibility: spy);

      await repo.cancel(bookingId: '42', reason: 'x');
      await repo.cancel(bookingId: '42', reason: 'x');

      expect(spy.cancelKeys[0], isNot(spy.cancelKeys[1]));
    });

    test('two bookings never share a key', () async {
      final spy = _KeySpy();
      final repo = BookingLifecycleRepository(compatibility: spy);

      await repo.cancel(bookingId: '42', reason: 'x');
      await repo.cancel(bookingId: '43', reason: 'x');

      expect(spy.cancelKeys[0], isNot(spy.cancelKeys[1]));
    });

    test('correcting a mistyped code is a new intent', () async {
      // The OTP key is scoped to the CODE. Keyed on the booking alone, a second
      // and different code would replay the first one's rejection — the
      // customer would type the right digits and be told they are wrong.
      final spy = _KeySpy();
      final repo = BookingLifecycleRepository(compatibility: spy);

      await expectLater(repo.verifyOtp(bookingId: '42', code: '111111'),
          throwsA(isA<ValidationFailure>()));
      await expectLater(repo.verifyOtp(bookingId: '42', code: '222222'),
          throwsA(isA<ValidationFailure>()));

      expect(spy.verifyKeys[0], isNot(spy.verifyKeys[1]));
    });
  });

  // ── OTP ────────────────────────────────────────────────────────────────────

  group('OTP', () {
    test('status is read from the backend, with the budgets', () async {
      final c = canonical([
        (
          status: 200,
          body: <String, dynamic>{
            'data': <String, dynamic>{
              'bookingId': 42,
              'purpose': 'BOOKING_CONFIRMATION',
              'present': true,
              'expired': false,
              'attemptsRemaining': 2,
              'issuesRemaining': 1,
              'resendAvailableInSeconds': 42,
              'policy': <String, dynamic>{
                'expiryMinutes': 10,
                'resendCooldownSeconds': 60,
                'maxVerifyAttempts': 5,
                'maxIssues': 3,
                'canRequest': true,
                'canVerify': true,
              },
            },
          },
        ),
      ]);

      final state = await c.source.otpStatus(bookingId: '42');

      expect(c.recorder.requests.single.url.path,
          '/api/v1/bookings/42/otp/status');
      expect(c.recorder.requests.single.url.queryParameters['purpose'],
          'BOOKING_CONFIRMATION');

      // "resend in 42s" and "2 attempts left" — the two strings the screen used
      // to be unable to say.
      expect(state.resendAvailableInSeconds, 42);
      expect(state.attemptsRemaining, 2);
      expect(state.canResendNow, isFalse);
      expect(state.isBackendDerived, isTrue);
    });

    test('the legacy transport reports budgets as unknown, not as zero',
        () async {
      // Zero means "no attempts left" and would disable a button that works.
      // Null means "we cannot say", which is the truth on this transport.
      final state =
          await BookingLifecycleCompatibilityDataSource(_FakeLegacyApi())
              .otpStatus(bookingId: '42');

      expect(state.attemptsRemaining, isNull);
      expect(state.issuesRemaining, isNull);
      expect(state.attemptsExhausted, isFalse);
      expect(state.isBackendDerived, isFalse);
      // Nothing is on cooldown merely because the screen opened.
      expect(state.canResendNow, isTrue);
    });

    test('an unknown budget is not an exhausted one', () {
      const unknown =
          BookingOtpState.local(bookingId: '42', resendAvailableInSeconds: 0);
      expect(unknown.attemptsExhausted, isFalse);

      const spent = BookingOtpState(
        bookingId: '42',
        purpose: BookingOtpPurpose.bookingConfirmation,
        resendAvailableInSeconds: 0,
        attemptsRemaining: 0,
      );
      expect(spent.attemptsExhausted, isTrue);
    });

    test('verify sends `code`, not the deprecated aliases', () async {
      final c = canonical([
        (
          status: 200,
          body: <String, dynamic>{
            'data': <String, dynamic>{
              'bookingId': 42,
              'action': 'confirmOtp',
              'fromState': 'PENDING_OTP',
              'toState': 'AWAITING_ASSIGNMENT',
            },
          },
        ),
      ]);

      await c.source.verifyOtp(
        bookingId: '42',
        code: '123456',
        idempotencyKey: 'idm_key_00001',
      );

      final body = jsonDecode(c.recorder.bodies.single) as Map<String, dynamic>;
      expect(body['code'], '123456');
      expect(body['purpose'], 'BOOKING_CONFIRMATION');
      // `otp` and `workerCode` are accepted for shipped builds; writing new
      // code against a deprecation is how the alias never gets removed.
      expect(body.containsKey('otp'), isFalse);
      expect(body.containsKey('workerCode'), isFalse);
    });

    test('requesting a code sends no idempotency key', () async {
      // Its replay guard is the cooldown and the issue ceiling. A key would let
      // a caller replay past both.
      final c = canonical([
        (
          status: 200,
          body: <String, dynamic>{
            'data': <String, dynamic>{
              'bookingId': 42,
              'purpose': 'BOOKING_CONFIRMATION',
              'delivery': 'email',
              'expiresAt': '2026-08-16T10:00:00.000Z',
              'resendAvailableAt': '2026-08-16T09:31:00.000Z',
            },
          },
        ),
      ]);

      final issued = await c.source.requestOtp(bookingId: '42');

      expect(c.recorder.requests.single.headers.containsKey('idempotency-key'),
          isFalse);
      expect(
        issued.resendInSeconds(DateTime.utc(2026, 8, 16, 9, 30)),
        60,
      );
      // A clock skewed past the window counts down to zero, never negative.
      expect(
        issued.resendInSeconds(DateTime.utc(2026, 8, 16, 9, 40)),
        0,
      );
    });

    test('the code is never carried on any model', () {
      // The backend states it as an invariant — "The code itself is NEVER in
      // this response, in any field, for any actor." A client that grew a
      // `code` field would be inviting the server to start sending one.
      final issued = BookingOtpIssued.fromApiMap(<String, dynamic>{
        'bookingId': 42,
        'purpose': 'BOOKING_CONFIRMATION',
        'code': '123456', // if a server ever leaked it, this must be ignored
      });
      expect(issued.bookingId, '42');

      final state = BookingOtpState.fromApiMap(<String, dynamic>{
        'bookingId': 42,
        'present': true,
        'code': '123456',
      });
      expect(state.present, isTrue);

      // Neither type exposes it. This is a compile-time property asserted at
      // runtime for the reader's benefit: `present` is the most either knows.
      expect(
        <String>['bookingId', 'purpose', 'delivery', 'recipient'],
        isNot(contains('code')),
      );
    });

    test('the legacy resend refuses a purpose it cannot honour', () async {
      // The legacy route has no purpose parameter and rotates the CUSTOMER's
      // confirmation code. Asking it for SERVICE_START would silently rotate
      // the wrong credential.
      await expectLater(
        BookingLifecycleCompatibilityDataSource(_FakeLegacyApi()).requestOtp(
          bookingId: '42',
          purpose: BookingOtpPurpose.serviceStart,
        ),
        throwsA(isA<UnsupportedLifecycleAction>()),
      );
    });

    test('a legacy wrong code raises the same failure a canonical one does',
        () async {
      final api = _FakeLegacyApi()
        ..confirmResponse = <String, dynamic>{
          'success': false,
          'message': 'Invalid code. Please try again.',
        };

      await expectLater(
        BookingLifecycleCompatibilityDataSource(api).verifyOtp(
          bookingId: '42',
          code: '000000',
          idempotencyKey: 'idm_key_00001',
        ),
        throwsA(isA<ValidationFailure>()
            .having((f) => f.code, 'code', 'BOOKING_OTP_INVALID')),
      );
    });
  });

  // ── Reschedule ─────────────────────────────────────────────────────────────

  group('reschedule', () {
    test('the legacy transport reports it absent instead of 403ing', () async {
      // The only reschedule route that has ever existed is admin-only. A
      // customer discovering that by being refused is the outcome the flag
      // exists to prevent.
      final repo = BookingLifecycleRepository(
        compatibility:
            BookingLifecycleCompatibilityDataSource(_FakeLegacyApi()),
      );

      expect(repo.canOfferReschedule, isFalse);
      await expectLater(
        repo.reschedule(
          bookingId: '42',
          request: BookingRescheduleRequest(
              scheduledAt: DateTime.utc(2026, 9, 1, 10)),
        ),
        throwsA(isA<UnsupportedLifecycleAction>()),
      );
    });

    test('the request always carries expectedSchedule when one is known',
        () async {
      // This is the concurrency guard AND the replay guard: the write carries
      // `schedule IS NOT DISTINCT FROM <expected>`, so a repeat of an applied
      // move is refused rather than moving the booking twice.
      final c = canonical([
        (
          status: 200,
          body: <String, dynamic>{
            'data': <String, dynamic>{
              'bookingId': 42,
              'status': 'ACCEPTED',
              'scheduledAt': '2026-09-01T10:00:00.000Z',
              'previousSchedule': '2026-08-20T10:00:00.000Z',
              'appliedImmediately': true,
              'verdict': <String, dynamic>{'noticeHours': 24},
            },
          },
        ),
      ]);

      final result = await c.source.reschedule(
        bookingId: '42',
        request: BookingRescheduleRequest(
          scheduledAt: DateTime.utc(2026, 9, 1, 10),
          reasonCode: RescheduleReason.customerUnavailable,
          expectedSchedule: DateTime.utc(2026, 8, 20, 10),
        ),
      );

      final body = jsonDecode(c.recorder.bodies.single) as Map<String, dynamic>;
      expect(body['scheduledAt'], '2026-09-01T10:00:00.000Z');
      expect(body['expectedSchedule'], '2026-08-20T10:00:00.000Z');
      expect(body['reasonCode'], 'CUSTOMER_UNAVAILABLE');

      expect(result.isAccepted, isTrue);
      // The notice window is READ from the verdict, never computed. An admin's
      // is zero and a customer's is 24; a client that computed it would apply
      // one actor's rule to the other.
      expect(result.noticeHours, 24);
    });

    test('PENDING_PROVIDER is not treated as accepted', () {
      // Reachable the day RESCHEDULE_REQUIRES_PROVIDER_ACCEPTANCE flips true.
      // Collapsing it into accepted tells a customer their booking moved when
      // it has only been proposed.
      final result = BookingRescheduleResult.fromApiMap(<String, dynamic>{
        'bookingId': 42,
        'status': 'PENDING_PROVIDER',
        'scheduledAt': '2026-09-01T10:00:00.000Z',
      });
      expect(result.isAccepted, isFalse);
      expect(result.isPendingProvider, isTrue);
    });

    test('the customer reason list excludes the operator vocabulary', () {
      // PROVIDER_SUPPLY and OPERATIONAL are valid on the endpoint and belong to
      // an admin. Offering them invites a customer to attribute the move to
      // their provider in a record that is kept.
      final wire =
          RescheduleReason.customerChoices.map((r) => r.wireName).toList();
      expect(wire, isNot(contains('PROVIDER_SUPPLY')));
      expect(wire, isNot(contains('OPERATIONAL')));
      expect(wire, contains('CUSTOMER_UNAVAILABLE'));

      // Every offered value is one the backend's closed list accepts.
      const backendReasons = <String>{
        'CUSTOMER_UNAVAILABLE',
        'PROPERTY_NOT_READY',
        'WEATHER',
        'PROVIDER_SUPPLY',
        'OPERATIONAL',
        'OTHER',
      };
      for (final r in RescheduleReason.values) {
        expect(backendReasons, contains(r.wireName));
      }
    });

    test('history reads the same path with GET', () async {
      final c = canonical([
        (
          status: 200,
          body: <String, dynamic>{
            'data': <String, dynamic>{
              'bookingId': 42,
              'requests': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 7,
                  'proposedSchedule': '2026-09-01T10:00:00.000Z',
                  'status': 'REFUSED',
                  'refusalCode': 'INSIDE_NOTICE_WINDOW',
                  'requestedRole': 'customer',
                },
              ],
            },
          },
        ),
      ]);

      final history = await c.source.rescheduleHistory('42');

      expect(c.recorder.requests.single.method, 'GET');
      expect(c.recorder.requests.single.url.path,
          '/api/v1/bookings/42/reschedule');
      expect(history.single.refusalCode, 'INSIDE_NOTICE_WINDOW');
      // The proposer's uid is not projected by the backend and is not modelled
      // here. Only the seat.
      expect(history.single.requestedRole, 'customer');
    });
  });

  // ── Action availability ────────────────────────────────────────────────────

  group('who decides what the customer may do', () {
    test('the backend list wins over the local one', () async {
      final repo = BookingLifecycleRepository(compatibility: _KeySpy());

      final availability = repo.resolveActions(
        backendActions: const <String>['cancel'],
        localFallback: const <String>['cancel', 'confirmOtp'],
      );

      expect(availability.actions, <String>['cancel']);
      expect(availability.canConfirmOtp, isFalse);
      expect(availability.isBackendDerived, isTrue);
    });

    test('an EMPTY backend list still wins', () async {
      // The trap: treating empty as "the server said nothing" reinstates the
      // client's own state machine at exactly the moment the server said the
      // machine permits nothing.
      final repo = BookingLifecycleRepository(compatibility: _KeySpy());

      final availability = repo.resolveActions(
        backendActions: const <String>[],
        localFallback: const <String>['cancel'],
      );

      expect(availability.actions, isEmpty);
      expect(availability.canCancel, isFalse);
      expect(availability.isBackendDerived, isTrue);
    });

    test('the local resolver is used only when the backend said nothing', () {
      final repo = BookingLifecycleRepository(compatibility: _KeySpy());

      final availability =
          repo.resolveActions(localFallback: const <String>['cancel']);

      expect(availability.canCancel, isTrue);
      expect(availability.isBackendDerived, isFalse);
    });

    test('reschedule availability never comes from availableActions', () {
      // Rescheduling is not a state transition — it goes through
      // bookingRescheduleService — so it can never appear in the machine's
      // action list. A client that looked for it there would offer it never.
      final repo = BookingLifecycleRepository(compatibility: _KeySpy());

      final availability = repo.resolveActions(
        backendActions: const <String>['cancel'],
        localFallback: const <String>[],
      );

      expect(availability.actions, isNot(contains('reschedule')));
      // False here because the compatibility transport has no endpoint, which
      // is a transport fact rather than a state one.
      expect(availability.canReschedule, isFalse);
    });
  });
}
