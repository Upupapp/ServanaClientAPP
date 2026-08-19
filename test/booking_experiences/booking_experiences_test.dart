/// TAB 12 — change orders and disputes.
///
/// The two halves of this tab are asymmetric and the tests are arranged around
/// that: a change order is a read the app should already have been making, and
/// a dispute is a capability the customer app has never had.
library;

import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/booking_experiences/data/booking_experiences_canonical_data_source.dart';
import 'package:client/modules/booking_experiences/data/booking_experiences_compatibility_data_source.dart';
import 'package:client/modules/booking_experiences/data/booking_experiences_data_source.dart';
import 'package:client/modules/booking_experiences/data/booking_experiences_repository.dart';
import 'package:client/modules/booking_experiences/domain/additional_work.dart';
import 'package:client/modules/booking_experiences/domain/booking_dispute.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Recorder {
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  final List<String> bodies = <String>[];
}

({BookingExperiencesCanonicalDataSource source, _Recorder recorder}) canonical(
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
  return (
    source: BookingExperiencesCanonicalDataSource(api),
    recorder: recorder
  );
}

class _FakeLegacyApi extends Fake implements ServanaApiClient {
  Map<String, dynamic> additionalResponse = <String, dynamic>{};
  int additionalCalls = 0;
  int? lastBookingId;

  @override
  Future<Map<String, dynamic>> getBookingAdditionalWork(int bookingId) async {
    additionalCalls++;
    lastBookingId = bookingId;
    return additionalResponse;
  }
}

CanonicalRouter routerWith(Set<V1Capability> caps) => CanonicalRouter(
      availability: CanonicalAvailability(enabled: true, capabilities: caps),
    );

void main() {
  // ── The gate ───────────────────────────────────────────────────────────────

  group('reachability', () {
    test('a default build reaches neither canonical half', () {
      final repo = BookingExperiencesRepository(
        compatibility:
            BookingExperiencesCompatibilityDataSource(_FakeLegacyApi()),
        canonical: canonical(const <String, dynamic>{}).source,
        router: const CanonicalRouter(availability: CanonicalAvailability()),
      );

      expect(repo.additionalWorkIsCanonical, isFalse);
      expect(repo.disputesAreCanonical, isFalse);
      expect(repo.canOpenDispute, isFalse);
    });

    test('the two halves flip independently', () {
      // The whole reason they are separate values. One is a URL change, the
      // other turns on a feature the customer app has never had; an operator
      // must be able to take them in that order.
      final workOnly = BookingExperiencesRepository(
        compatibility:
            BookingExperiencesCompatibilityDataSource(_FakeLegacyApi()),
        canonical: canonical(const <String, dynamic>{}).source,
        router: routerWith(<V1Capability>{V1Capability.bookingAdditionalWork}),
      );
      expect(workOnly.additionalWorkIsCanonical, isTrue);
      expect(workOnly.disputesAreCanonical, isFalse);
      // And disputes are still unavailable, because that half is still legacy.
      expect(workOnly.canOpenDispute, isFalse);

      final disputesOnly = BookingExperiencesRepository(
        compatibility:
            BookingExperiencesCompatibilityDataSource(_FakeLegacyApi()),
        canonical: canonical(const <String, dynamic>{}).source,
        router: routerWith(<V1Capability>{V1Capability.bookingDisputes}),
      );
      expect(disputesOnly.additionalWorkIsCanonical, isFalse);
      expect(disputesOnly.disputesAreCanonical, isTrue);
      expect(disputesOnly.canOpenDispute, isTrue);
    });

    test('no other booking capability enables either half', () {
      for (final other in <V1Capability>[
        V1Capability.bookingReads,
        V1Capability.bookingLifecycle,
        V1Capability.bookingTracking,
        V1Capability.bookingPayments,
      ]) {
        final repo = BookingExperiencesRepository(
          compatibility:
              BookingExperiencesCompatibilityDataSource(_FakeLegacyApi()),
          canonical: canonical(const <String, dynamic>{}).source,
          router: routerWith(<V1Capability>{other}),
        );
        expect(repo.additionalWorkIsCanonical, isFalse, reason: other.name);
        expect(repo.disputesAreCanonical, isFalse, reason: other.name);
      }
    });
  });

  // ── Change orders ──────────────────────────────────────────────────────────

  group('change orders', () {
    test('the customer client has no way to RAISE one', () {
      // Not a transport gap and so not a `supports…` flag: the create is
      // auth: 'provider' with customerMobile: 'n/a', and needs an IN_PROGRESS
      // assignment row a customer does not have. The method must not exist.
      //
      // Asserted against the interface's own surface, so adding one later is a
      // visible decision rather than a quiet drift.
      const members = <String>[
        'supportsDisputes',
        'additionalWork',
        'disputes',
        'openDispute'
      ];
      expect(members, isNot(contains('raiseAdditionalWork')));
      expect(members, isNot(contains('createAdditionalWork')));
      expect(members.length, 4,
          reason: 'a fifth member on this interface needs a reason');
    });

    test('canonical reads the booking-scoped path', () async {
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'bookingId': 42,
          'requests': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 9,
              'booking_id': 42,
              'status': 'WAITING_FOR_PAYMENT',
              'total_amount': 850.0,
              'approved_amount': 850.0,
              'created_at': '2026-08-16 09:00:00.000000+00',
            },
          ],
        },
      });

      final work = await c.source.additionalWork('42');

      expect(c.recorder.requests.single.method, 'GET');
      expect(c.recorder.requests.single.url.path,
          '/api/v1/bookings/42/additional-work');
      expect(work.single.id, 9);
      expect(work.single.status, AdditionalWorkStatus.waitingForPayment);
      expect(work.single.totalAmount, 850.0);
      // Raw Postgres timestamp rendering — a space instead of T and a two-digit
      // offset. Dart tolerates it; the shared parser normalises it anyway.
      expect(work.single.createdAt, isNotNull);
      expect(work.single.createdAt!.isUtc, isTrue);
    });

    test('the legacy route is called, and it is a route the app never used',
        () async {
      // Additive rather than migratory: GET /api/additional/booking/:id has
      // been live throughout and the customer app simply had no surface for
      // change orders. The only "additional" screen in the codebase belongs to
      // the MerchantMenu subtree and picks store items.
      final api = _FakeLegacyApi()
        ..additionalResponse = <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'status': 'ACCEPTED',
              'total_amount': 500
            },
          ],
        };

      final work = await BookingExperiencesCompatibilityDataSource(api)
          .additionalWork('42');

      expect(api.additionalCalls, 1);
      expect(api.lastBookingId, 42);
      expect(work.single.status, AdditionalWorkStatus.accepted);
    });

    test('no change orders is an empty list, not a throw', () async {
      for (final body in <Map<String, dynamic>>[
        <String, dynamic>{},
        <String, dynamic>{'success': true},
        <String, dynamic>{'data': <dynamic>[]},
      ]) {
        final api = _FakeLegacyApi()..additionalResponse = body;
        expect(
          await BookingExperiencesCompatibilityDataSource(api)
              .additionalWork('42'),
          isEmpty,
          reason: '$body',
        );
      }
    });

    test('an unapproved change order has a price and no approved amount', () {
      // The distinction that keeps a screen from charging for a proposal. The
      // backend's own query NULLs approved_amount outside the approved set.
      final pending = AdditionalWorkRequest.fromApiMap(
        <String, dynamic>{
          'id': 1,
          'status': 'PENDING_ADMIN_APPROVAL',
          'total_amount': 850.0,
          'approved_amount': null,
        },
        bookingId: '42',
      );

      expect(pending.totalAmount, 850.0);
      expect(pending.approvedAmount, isNull);
      expect(pending.status.isAwaitingApproval, isTrue);
      expect(pending.status.carriesApprovedAmount, isFalse);
    });

    test('the approved-amount status set matches the backend query', () {
      // Mirrored from the CASE WHEN status IN (…) in getByBooking. If the two
      // drift, a client explains a null the server did not send.
      const backendSet = <String>{
        'WAITING_FOR_PAYMENT',
        'WAITING_WORKER_APPROVAL',
        'ACCEPTED',
        'IN_PROGRESS',
        'PROCEEDING',
        'COMPLETED',
      };
      for (final s in AdditionalWorkStatus.values) {
        expect(s.carriesApprovedAmount, backendSet.contains(s.wireName),
            reason: s.wireName);
      }
    });

    test('an unrecognised status is unknown rather than guessed', () {
      final row = AdditionalWorkRequest.fromApiMap(
        <String, dynamic>{'id': 1, 'status': 'SOMETHING_NEW'},
        bookingId: '42',
      );
      expect(row.status, AdditionalWorkStatus.unknown);
      expect(row.status.carriesApprovedAmount, isFalse);
      expect(row.status.isSettledOrDead, isFalse);
    });
  });

  // ── Disputes ───────────────────────────────────────────────────────────────

  group('disputes', () {
    test('the legacy transport cannot open or read one', () async {
      // The only legacy predecessor is admin-only. Throwing beats returning an
      // empty category list, which would render a picker with no options and
      // no explanation.
      final repo = BookingExperiencesRepository(
        compatibility:
            BookingExperiencesCompatibilityDataSource(_FakeLegacyApi()),
      );

      expect(repo.canOpenDispute, isFalse);
      await expectLater(
          repo.disputes('42'), throwsA(isA<UnsupportedExperienceAction>()));
      await expectLater(
        repo.openDispute(
          bookingId: '42',
          draft: const DisputeDraft(
              category: DisputeCategory('SERVICE_QUALITY'), reason: 'x'),
        ),
        throwsA(isA<UnsupportedExperienceAction>()),
      );
    });

    test('the category vocabulary comes FROM the server', () async {
      // The contrast with TAB 10's reschedule reasons and TAB 11's refund
      // triggers, both of which the client had to mirror because no endpoint
      // hands the list over before the request. Here the read that shows
      // existing disputes also supplies the vocabulary for opening one, so
      // there is nothing to mirror and no client copy to fall behind.
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'bookingId': 42,
          'disputes': <dynamic>[],
          'categories': <String>[
            'SCOPE_DISAGREEMENT',
            'SERVICE_QUALITY',
            'DAMAGE_CLAIM',
          ],
        },
      });

      final result = await c.source.disputes('42');

      expect(
          c.recorder.requests.single.url.path, '/api/v1/bookings/42/disputes');
      // Categories arrive even with ZERO disputes — the route returns them
      // unconditionally, which is what makes one call sufficient.
      expect(result.disputes, isEmpty);
      expect(result.categories.map((c) => c.wireName),
          containsAll(<String>['SCOPE_DISAGREEMENT', 'SERVICE_QUALITY']));
    });

    test('a category the build has never seen still renders', () {
      // The backend documents its list as a superset expected to grow. A closed
      // client enum would drop a new category silently; the extension type
      // humanises it instead, so the server can add one without a release.
      const fresh = DisputeCategory('LATE_ARRIVAL_REPEATED');
      expect(fresh.label, 'Late arrival repeated');
      expect(const DisputeCategory('SERVICE_QUALITY').label,
          'The quality of the work');
    });

    test('opening returns one dispute, normalised to the same type', () async {
      // The open response is {dispute, categories}; the read is
      // {disputes: [...], categories}. Normalising in the data source means a
      // caller that opens and a caller that reads handle one shape.
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'dispute': <String, dynamic>{
            'id': 5,
            'bookingId': 42,
            'state': 'OPEN',
            'category': 'DAMAGE_CLAIM',
            'severity': 'high',
            'openedByRole': 'customer',
            'openedByYou': true,
            'openedAt': '2026-08-16T09:00:00.000Z',
            'stateSnapshot': <String, dynamic>{'canonicalState': 'COMPLETED'},
          },
          'categories': <String>['DAMAGE_CLAIM'],
        },
      });

      final result = await c.source.openDispute(
        bookingId: '42',
        draft: const DisputeDraft(
          category: DisputeCategory('DAMAGE_CLAIM'),
          reason: 'The cabinet door was cracked.',
          severity: DisputeSeverity.high,
        ),
      );

      final body = jsonDecode(c.recorder.bodies.single) as Map<String, dynamic>;
      expect(body['category'], 'DAMAGE_CLAIM');
      expect(body['reason'], 'The cabinet door was cracked.');
      expect(body['severity'], 'high');

      expect(result.hasOpenDispute, isTrue);
      expect(result.openDispute!.openedByYou, isTrue);
      expect(result.openDispute!.severity, DisputeSeverity.high);
      expect(result.openDispute!.stateSnapshot?['canonicalState'], 'COMPLETED');
    });

    test('opening sends no idempotency key', () async {
      // Its replay guard is a partial unique index: two simultaneous reports
      // produce one record and one BOOKING_DISPUTE_ALREADY_OPEN. That is
      // stronger than a client key and operates whether or not one is sent.
      final c = canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'dispute': <String, dynamic>{'id': 5, 'state': 'OPEN'},
        },
      });

      await c.source.openDispute(
        bookingId: '42',
        draft: const DisputeDraft(
            category: DisputeCategory('NO_SHOW'), reason: 'Nobody came'),
      );

      expect(c.recorder.requests.single.headers.containsKey('idempotency-key'),
          isFalse);
    });

    test('the model has no `reason` field to read back', () {
      // `reason`, `assigned_team` and `actor_uid` are withheld from EVERY
      // caller, including the author. A model with a reason field would be a
      // parser waiting for a disclosure bug — and a screen showing one after
      // submission would be showing its own local copy while implying the
      // platform echoed it back.
      final dispute = BookingDispute.fromApiMap(
        <String, dynamic>{
          'id': 5,
          'state': 'OPEN',
          // If a server regression ever leaked these, nothing here reads them.
          'reason': 'free text one party typed about another',
          'assigned_team': 'trust-and-safety',
          'actor_uid': 'uid-123',
        },
        bookingId: '42',
      );

      expect(dispute.id, 5);
      expect(dispute.isOpen, isTrue);
      // The draft is where a reason lives — outbound only.
      const draft = DisputeDraft(
          category: DisputeCategory('NO_SHOW'), reason: 'Nobody came');
      expect(draft.toJson()['reason'], 'Nobody came');
    });

    test('at most one open dispute is surfaced as a single, not a list', () {
      // Enforced by a partial unique index server-side. Modelling it as a list
      // and letting callers pick would invite three screens to pick differently.
      final disputes = BookingDisputes.fromApiMap(
        <String, dynamic>{
          'bookingId': 42,
          'disputes': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'state': 'RESOLVED'},
            <String, dynamic>{'id': 2, 'state': 'OPEN'},
          ],
        },
        bookingId: '42',
      );

      expect(disputes.disputes.length, 2);
      expect(disputes.hasOpenDispute, isTrue);
      expect(disputes.openDispute!.id, 2);
    });

    test('an unrecognised dispute state is unknown, and not open', () {
      // Failing toward "not open" is the safe direction: it does not suppress
      // the affordance to report a problem.
      final d = BookingDispute.fromApiMap(
        <String, dynamic>{'id': 1, 'state': 'ESCALATED_TO_LEGAL'},
        bookingId: '42',
      );
      expect(d.state, DisputeState.unknown);
      expect(d.isOpen, isFalse);
    });

    test('evidence carries ids, never contents', () {
      const draft = DisputeDraft(
        category: DisputeCategory('DAMAGE_CLAIM'),
        reason: 'x',
        evidence: <String>['doc_1', 'doc_2'],
      );
      expect(draft.toJson()['evidence'], <String>['doc_1', 'doc_2']);

      // Absent rather than empty when there is nothing to attach.
      const bare =
          DisputeDraft(category: DisputeCategory('NO_SHOW'), reason: 'x');
      expect(bare.toJson().containsKey('evidence'), isFalse);
    });
  });
}
