/// Booking detail's caller for `BookingExperiencesRepository`.
///
/// ## What was wrong
///
/// The repository was registered and referenced by no screen and no
/// controller. Two capabilities — `bookingAdditionalWork` and
/// `bookingDisputes` — were declared complete against a surface a customer
/// could not enter. A provider could request extra work, the backend recorded
/// it, `GET /api/additional/booking/:bookingId` returned it, and the person
/// being asked to pay had nowhere to see it.
///
/// ## The asymmetry these tests protect
///
/// Change orders work on the shipped transport. Disputes do NOT — the only
/// legacy dispute route is admin-only, so `canOpenDispute` is false in every
/// build that exists and the compatibility source throws rather than
/// returning an empty category list. A screen that offered the action anyway
/// would fail at the worst moment: the customer has already decided to
/// complain by the time they find out.
library;

import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/booking_experiences/application/booking_experiences_controller.dart';
import 'package:client/modules/booking_experiences/data/booking_experiences_data_source.dart';
import 'package:client/modules/booking_experiences/data/booking_experiences_repository.dart';
import 'package:client/modules/booking_experiences/domain/additional_work.dart';
import 'package:client/modules/booking_experiences/domain/booking_dispute.dart';
import 'package:flutter_test/flutter_test.dart';

class _Source implements BookingExperiencesDataSource {
  _Source({
    this.requests = const <AdditionalWorkRequest>[],
    this.error,
    this.supportsDisputes = false,
  });

  final List<AdditionalWorkRequest> requests;
  final Object? error;

  @override
  final bool supportsDisputes;

  @override
  Future<List<AdditionalWorkRequest>> additionalWork(String bookingId) async {
    final failure = error;
    if (failure != null) throw failure;
    return requests;
  }

  @override
  Future<BookingDisputes> disputes(String bookingId) async =>
      throw UnsupportedExperienceAction('reading disputes');

  @override
  Future<BookingDisputes> openDispute({
    required String bookingId,
    required DisputeDraft draft,
  }) async =>
      throw UnsupportedExperienceAction('opening a dispute');
}

AdditionalWorkRequest request({
  int id = 1,
  AdditionalWorkStatus status = AdditionalWorkStatus.waitingForPayment,
  double? total = 750,
  double? approved,
}) =>
    AdditionalWorkRequest(
      id: id,
      bookingId: '42',
      status: status,
      totalAmount: total,
      approvedAmount: approved,
    );

BookingExperiencesController controllerWith(_Source source) =>
    BookingExperiencesController(
      BookingExperiencesRepository(compatibility: source),
    );

void main() {
  group('change orders are read on the transport every build uses', () {
    test('publishes what the booking has', () async {
      final c = controllerWith(_Source(requests: [request()]));

      await c.load('42');

      final state = c.state as ChangeOrdersReady;
      expect(state.requests, hasLength(1));
      expect(state.isEmpty, isFalse);
    });

    test('no change orders is a ready-and-empty state, not a failure',
        () async {
      // The overwhelmingly common case. It must be distinguishable from "could
      // not read", because the screen draws nothing for one and could
      // reasonably say something for the other.
      final c = controllerWith(_Source());

      await c.load('42');

      expect(c.state, isA<ChangeOrdersReady>());
      expect((c.state as ChangeOrdersReady).isEmpty, isTrue);
    });

    test('a failure is a state, never a throw', () async {
      final c = controllerWith(
        _Source(error: const RetryableFailure(safeMessage: 'offline')),
      );

      await c.load('42');

      expect(c.state, isA<ChangeOrdersUnavailable>());
    });
  });

  group('only what waits on the CUSTOMER is counted as awaiting them', () {
    test('WAITING_FOR_PAYMENT is theirs to act on', () async {
      final c = controllerWith(
        _Source(
          requests: [request(status: AdditionalWorkStatus.waitingForPayment)],
        ),
      );

      await c.load('42');

      expect((c.state as ChangeOrdersReady).awaitingCustomer, hasLength(1));
    });

    test('waiting on the admin or the provider is not theirs', () async {
      // Both are unfinished, and neither is something the customer can do
      // anything about. Counting them would ask a customer to act on
      // somebody else's decision.
      final c = controllerWith(
        _Source(
          requests: [
            request(id: 1, status: AdditionalWorkStatus.pendingAdminApproval),
            request(id: 2, status: AdditionalWorkStatus.waitingWorkerApproval),
          ],
        ),
      );

      await c.load('42');

      expect((c.state as ChangeOrdersReady).awaitingCustomer, isEmpty);
      expect((c.state as ChangeOrdersReady).requests, hasLength(2));
    });

    test('a completed change order is not awaiting anybody', () async {
      final c = controllerWith(
        _Source(requests: [request(status: AdditionalWorkStatus.completed)]),
      );

      await c.load('42');

      expect((c.state as ChangeOrdersReady).awaitingCustomer, isEmpty);
    });
  });

  group('disputes are not offered on a transport that cannot serve them', () {
    test('canDispute is false on every build that exists today', () {
      // The only legacy dispute route is admin-only and a customer token
      // cannot use it. A button here would throw at the moment of use.
      final c = controllerWith(_Source(supportsDisputes: false));

      expect(c.canDispute, isFalse);
    });

    test('it flips the moment a transport supports them', () {
      // Nothing else has to change for the affordance to appear: this is the
      // whole switch.
      final c = controllerWith(_Source(supportsDisputes: true));

      expect(c.canDispute, isTrue);
    });
  });
}
