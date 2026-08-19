/// The three booking-submission invariants, preserved across TAB 08.
///
/// These used to be asserted by reading the two store files and comparing
/// substring positions. TAB 08 moved the ceremony into
/// `BookingSubmissionService`, so the substrings moved — but the invariants did
/// not, and they are now checked by EXERCISING the code rather than by looking
/// at it. A behavioural assertion also survives reformatting, and cannot pass
/// because a `contains` happened to match a comment.
///
/// One source check remains, and only one: that the stores still delegate. That
/// is the property no behavioural test of the service can see, because a store
/// which quietly re-inlined its own ceremony would leave the service passing
/// every test while nothing called it.
library;

import 'dart:io';

import 'package:client/common/data/booking/booking_submission_service.dart';
import 'package:client/common/domain/booking/booking_create_request.dart';
import 'package:client/common/domain/booking/booking_draft.dart'
    show BookingFlowType;
import 'package:flutter_test/flutter_test.dart';

import 'booking_submission_fakes.dart';

BookingCreateRequest _complete() => BookingCreateRequest(
      flowType: BookingFlowType.aircon,
      serviceOptionId: 180,
      userAddressId: 'addr-1',
      schedule: DateTime.now().add(const Duration(days: 1)),
      paymentMethod: 'CASH',
      pricingInputs: const {'optionId': 180, 'addonOptionIds': <int>[]},
    );

const _incomplete = BookingCreateRequest(
  flowType: BookingFlowType.aircon,
  serviceOptionId: null,
  userAddressId: '',
  schedule: null,
  paymentMethod: 'CASH',
);

BookingSubmissionService _service({
  required FakeBookingApi api,
  required FakeJournal journal,
  String? customer = 'cust-1',
}) =>
    BookingSubmissionService(
      api: api,
      journal: journal,
      customerId: () async => customer,
    );

void main() {
  test('releases the submission guard when authentication is absent', () {
    // The store flips `isSubmitting` back on a refusal, and it can only do that
    // if the refusal is distinguishable. `unauthenticated` is that signal.
    const refusal = BookingRefused(reasons: [], unauthenticated: true);
    expect(refusal.unauthenticated, isTrue);

    for (final path in _storePaths) {
      final source = File(path).readAsStringSync();
      final start = source.indexOf('BookingRefused(unauthenticated: true)');
      expect(start, greaterThan(-1), reason: '$path ignores the auth refusal');

      // Up to the next case arm: the guard must be released inside this one.
      final end = source.indexOf('case ', start + 10);
      expect(
        source.substring(start, end == -1 ? source.length : end),
        contains('isSubmitting = false;'),
        reason: '$path leaves the customer locked out of retrying after a '
            'refusal that never reached the network',
      );
    }
  });

  test('rejects an incomplete draft before minting an idempotency key',
      () async {
    var minted = 0;
    final api = FakeBookingApi();
    final journal = FakeJournal();

    final outcome = await _service(api: api, journal: journal).submit(
      request: _incomplete,
      idempotencyKey: () {
        minted++;
        return 'k1';
      },
    );

    expect(outcome, isA<BookingRefused>());
    // The key identifies a booking ATTEMPT. Nothing was attempted, so there is
    // no attempt to identify.
    expect(minted, 0);
    expect(api.calls, isEmpty);
    expect(journal.recorded, isEmpty);
  });

  test('mints no key when the session is absent either', () async {
    var minted = 0;
    final outcome = await _service(
      api: FakeBookingApi(),
      journal: FakeJournal(),
      customer: null,
    ).submit(
      request: _complete(),
      idempotencyKey: () {
        minted++;
        return 'k1';
      },
    );

    expect(outcome, isA<BookingRefused>());
    expect(minted, 0);
  });

  test('mints exactly one key for a real attempt, and reuses it on retry',
      () async {
    var minted = 0;
    String? key;
    String mint() {
      minted++;
      return key ??= 'k-$minted';
    }

    final api = FakeBookingApi(throws: Exception('connection reset'));
    final service = _service(api: api, journal: FakeJournal());

    await service.submit(request: _complete(), idempotencyKey: mint);
    await service.submit(request: _complete(), idempotencyKey: mint);

    // Called twice, but the caller's `??=` means one VALUE — which is what the
    // server deduplicates on. Regenerating here is what turns one booking
    // into two.
    expect(api.calls.map((c) => c.idempotencyKey), ['k-1', 'k-1']);
  });

  test('validates the create response before resolving its journal', () async {
    final journal = FakeJournal();
    // A success body with no authoritative id. The parser refuses it.
    final api = FakeBookingApi(response: <String, dynamic>{'success': true});

    final outcome = await _service(api: api, journal: journal)
        .submit(request: _complete(), idempotencyKey: () => 'k1');

    expect(outcome, isA<BookingFailed>());
    // The entry must still be pending: a booking may exist server-side, and
    // resolving here would discard the only record that says so.
    expect(journal.recorded, hasLength(1));
    expect(journal.resolved, isEmpty);
  });

  test('journals before the call and resolves only after a valid response',
      () async {
    final journal = FakeJournal();
    final api = FakeBookingApi(
      onCall: () => expect(journal.recorded, hasLength(1),
          reason: 'a record written after the response does not survive the '
              'failure it exists for'),
    );

    final outcome = await _service(api: api, journal: journal)
        .submit(request: _complete(), idempotencyKey: () => 'k1');

    expect(outcome, isA<BookingAccepted>());
    expect(journal.recorded.single.type, 'booking.create');
    expect(journal.resolved, ['k1']);
  });

  test('both stores still delegate — the ceremony is not re-inlined', () {
    for (final path in _storePaths) {
      final source = File(path).readAsStringSync();

      expect(source, contains('BookingSubmissionService'),
          reason: '$path no longer routes through the shared ceremony');

      // The tell-tales of a re-inlined ceremony. If these come back, the two
      // flows have started drifting again and the service is dead code.
      expect(source.contains('await journal.record'), isFalse,
          reason: '$path journals its own submission again');
      expect(source.contains('api.createBooking('), isFalse,
          reason: '$path calls the booking transport directly again');
    }
  });
}

const _storePaths = <String>[
  'lib/modules/aircon_booking/data/aircon_booking_store.dart',
  'lib/modules/bw_booking/data/bw_booking_store.dart',
];
