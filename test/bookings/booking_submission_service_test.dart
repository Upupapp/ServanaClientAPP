/// TAB 08 — the unified booking-create ceremony.
///
/// These two money paths had ZERO direct coverage before this tab, which is
/// why the tests came before the stores were pointed at the service.
///
/// The endpoint gap is real and asserted rather than assumed: there is no
/// `POST /api/v1/bookings`, so this exercises the legacy transport both flows
/// already used. What TAB 08 removes is the duplicate ceremony around it.
library;

import 'package:client/common/data/booking/booking_submission_service.dart';
import 'package:client/common/domain/booking/booking_create_request.dart';
import 'package:client/common/domain/booking/booking_draft.dart'
    show BookingFlowType;
import 'package:flutter_test/flutter_test.dart';

import 'booking_submission_fakes.dart';

BookingCreateRequest aircon({
  Object? serviceOptionId = 180,
  String addressId = 'addr-1',
  DateTime? schedule,
  String paymentMethod = 'CASH',
}) =>
    BookingCreateRequest(
      flowType: BookingFlowType.aircon,
      serviceOptionId: serviceOptionId,
      userAddressId: addressId,
      schedule: schedule ?? DateTime.now().add(const Duration(days: 1)),
      paymentMethod: paymentMethod,
      pricingInputs: const {
        'optionId': 180,
        'hpKey': '1.5',
        'addonOptionIds': <int>[],
      },
    );

BookingCreateRequest beautyWellness({Object? branchId = 'branch-9'}) =>
    BookingCreateRequest(
      flowType: BookingFlowType.beautyWellness,
      serviceOptionId: 44,
      userAddressId: 'addr-2',
      schedule: DateTime.now().add(const Duration(days: 2)),
      paymentMethod: 'PAYMONGO',
      branchId: branchId,
      requiresBranch: true,
      pricingInputs: const {'addonOptionIds': <int>[]},
    );

void main() {
  group('the request validates before anything leaves the device', () {
    test('a complete aircon request is valid', () {
      expect(aircon().validate(), isEmpty);
    });

    test('a schedule in the past is distinct from no schedule', () {
      // Different customer mistakes: one has not chosen, the other chose a time
      // that passed while they filled in the rest of the form.
      expect(
        aircon(schedule: DateTime.now().subtract(const Duration(hours: 1)))
            .validate(),
        [BookingRequestInvalidity.scheduleInPast],
      );
      expect(
        const BookingCreateRequest(
          flowType: BookingFlowType.aircon,
          serviceOptionId: 180,
          userAddressId: 'addr-1',
          schedule: null,
          paymentMethod: 'CASH',
        ).validate(),
        [BookingRequestInvalidity.noSchedule],
      );
    });

    test('an unsupported payment method is refused', () {
      expect(aircon(paymentMethod: 'BITCOIN').validate(),
          contains(BookingRequestInvalidity.noPaymentMethod));
      expect(aircon(paymentMethod: '').validate(),
          contains(BookingRequestInvalidity.noPaymentMethod));
    });

    test('a missing service or address is refused', () {
      expect(aircon(serviceOptionId: null).validate(),
          contains(BookingRequestInvalidity.noService));
      expect(aircon(addressId: '   ').validate(),
          contains(BookingRequestInvalidity.noAddress));
    });

    test('only a branch-requiring flow demands a branch', () {
      expect(beautyWellness(branchId: null).validate(),
          contains(BookingRequestInvalidity.noBranch));
      // Aircon has no branch and must not be asked for one.
      expect(aircon().validate(),
          isNot(contains(BookingRequestInvalidity.noBranch)));
    });

    test('every problem is reported, not just the first', () {
      final problems = const BookingCreateRequest(
        flowType: BookingFlowType.beautyWellness,
        serviceOptionId: null,
        userAddressId: '',
        schedule: null,
        paymentMethod: 'NOPE',
        requiresBranch: true,
      ).validate();

      expect(problems, hasLength(5));
    });
  });

  group('the payload carries inputs, never money', () {
    test('no total, fee or discount is sent', () {
      final payload = aircon().toPayload();
      final flat = payload.toString().toLowerCase();

      // The checkout screens show a quote. A quote is a projection for the
      // customer to read, never the number a booking is created with.
      for (final forbidden in ['total', 'grandtotal', 'fee', 'discount']) {
        expect(flat.contains(forbidden), isFalse,
            reason: '$forbidden must be computed by the backend');
      }
    });

    test('the schedule is UTC ISO-8601', () {
      final at = DateTime.now().add(const Duration(days: 1));
      final payload = aircon(schedule: at).toPayload();

      expect(payload['schedule'], at.toUtc().toIso8601String());
      expect(payload['schedule'], endsWith('Z'));
    });

    test('each flow keeps the pricing shape it already sent', () {
      // Aircon repeats optionId inside pricing; Beauty & Wellness does not.
      // Normalising that difference would change a live money payload for
      // tidiness, which is not this tab's mandate.
      expect((aircon().toPayload()['pricing'] as Map)['optionId'], 180);
      expect((beautyWellness().toPayload()['pricing'] as Map)
          .containsKey('optionId'), isFalse);
    });

    test('branchId appears only when the flow has one', () {
      expect(aircon().toPayload().containsKey('branchId'), isFalse);
      expect(beautyWellness().toPayload()['branchId'], 'branch-9');
    });

    test('one category label per flow, so the two cannot drift', () {
      expect(aircon().categoryLabel, 'aircon');
      expect(beautyWellness().categoryLabel, 'beauty_wellness');
    });
  });

  group('the ceremony', () {
    test('refuses without a session, and never touches the network', () async {
      final api = FakeBookingApi();
      final journal = FakeJournal();
      final service = BookingSubmissionService(
        api: api,
        journal: journal,
        customerId: () async => null,
      );

      final outcome =
          await service.submit(request: aircon(), idempotencyKey: () => 'k1');

      expect(outcome, isA<BookingRefused>());
      expect((outcome as BookingRefused).unauthenticated, isTrue);
      expect(api.calls, isEmpty);
      expect(journal.recorded, isEmpty,
          reason: 'nothing was attempted, so there is nothing to reconcile');
    });

    test('refuses an incomplete draft without journalling it', () async {
      final api = FakeBookingApi();
      final journal = FakeJournal();
      final service = BookingSubmissionService(
        api: api,
        journal: journal,
        customerId: () async => 'cust-1',
      );

      final outcome = await service.submit(
        request: aircon(serviceOptionId: null),
        idempotencyKey: () => 'k1',
      );

      expect(outcome, isA<BookingRefused>());
      expect((outcome as BookingRefused).reasons,
          contains(BookingRequestInvalidity.noService));
      expect(api.calls, isEmpty);
      expect(journal.recorded, isEmpty);
    });

    test('journals BEFORE the call, so a process kill is reconcilable',
        () async {
      final journal = FakeJournal();
      final api = FakeBookingApi(
        onCall: () => expect(
          journal.recorded, hasLength(1),
          reason: 'a record written after the response does not exist for '
              'exactly the failure it is meant to survive',
        ),
      );
      final service = BookingSubmissionService(
        api: api,
        journal: journal,
        customerId: () async => 'cust-1',
      );

      await service.submit(request: aircon(), idempotencyKey: () => 'k1');

      expect(journal.recorded.single.type, 'booking.create');
      expect(journal.recorded.single.idempotencyKey, 'k1');
    });

    test('passes the idempotency key through to the transport', () async {
      final api = FakeBookingApi();
      final service = BookingSubmissionService(
        api: api,
        journal: FakeJournal(),
        customerId: () async => 'cust-1',
      );

      await service.submit(request: aircon(), idempotencyKey: () => 'stable-key');

      expect(api.calls.single.idempotencyKey, 'stable-key');
    });

    test('the same key submitted twice reaches the server twice, unchanged',
        () async {
      // The client does not deduplicate. Reusing the key is what lets the
      // SERVER collapse a retry; suppressing the second call here would hide a
      // genuine retry after a lost response.
      final api = FakeBookingApi();
      final service = BookingSubmissionService(
        api: api,
        journal: FakeJournal(),
        customerId: () async => 'cust-1',
      );

      await service.submit(request: aircon(), idempotencyKey: () => 'k1');
      await service.submit(request: aircon(), idempotencyKey: () => 'k1');

      expect(api.calls, hasLength(2));
      expect(api.calls.map((c) => c.idempotencyKey), ['k1', 'k1']);
    });

    test('resolves the journal entry once accepted', () async {
      final journal = FakeJournal();
      final service = BookingSubmissionService(
        api: FakeBookingApi(),
        journal: journal,
        customerId: () async => 'cust-1',
      );

      final outcome =
          await service.submit(request: aircon(), idempotencyKey: () => 'k1');

      expect(outcome, isA<BookingAccepted>());
      expect((outcome as BookingAccepted).bookingId, 4242);
      expect(journal.resolved, ['k1']);
    });

    test('a failure LEAVES the journal entry standing', () async {
      final journal = FakeJournal();
      final service = BookingSubmissionService(
        api: FakeBookingApi(throws: Exception('connection reset')),
        journal: journal,
        customerId: () async => 'cust-1',
      );

      final outcome =
          await service.submit(request: aircon(), idempotencyKey: () => 'k1');

      expect(outcome, isA<BookingFailed>());
      // The request may have been accepted and the response lost. Clearing the
      // entry would erase the only evidence a booking might exist.
      expect(journal.recorded, hasLength(1));
      expect(journal.resolved, isEmpty);
    });

    test('both flows submit through this one path', () async {
      final api = FakeBookingApi();
      final service = BookingSubmissionService(
        api: api,
        journal: FakeJournal(),
        customerId: () async => 'cust-1',
      );

      await service.submit(request: aircon(), idempotencyKey: () => 'k1');
      await service.submit(request: beautyWellness(), idempotencyKey: () => 'k2');

      // The acceptance gate: one contract, no per-category state machine.
      expect(api.calls, hasLength(2));
      expect(api.calls[0].payload.containsKey('branchId'), isFalse);
      expect(api.calls[1].payload['branchId'], 'branch-9');
    });

    test('the customer id comes from the session, not from the request',
        () async {
      final api = FakeBookingApi();
      final service = BookingSubmissionService(
        api: api,
        journal: FakeJournal(),
        customerId: () async => 'session-cust',
      );

      await service.submit(request: aircon(), idempotencyKey: () => 'k1');

      expect(api.calls.single.userId, 'session-cust');
      // It is not in the payload at all — the legacy route takes it as a query
      // parameter, and that remains the endpoint's gap, not the screen's.
      expect(api.calls.single.payload.containsKey('userId'), isFalse);
    });
  });
}
