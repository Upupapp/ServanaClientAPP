import 'package:client/common/domain/booking/booking_action.dart';
import 'package:client/common/domain/booking/booking_action_resolver.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── resolve() ─────────────────────────────────────────────────────────────

  group('BookingActionResolver.resolve – OTP', () {
    test('pendingOtp booking includes confirmOtp as first action', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.pendingOtp,
        paymentStatus: 'PENDING',
      );
      expect(actions, contains(BookingAction.confirmOtp));
      expect(actions.first, BookingAction.confirmOtp);
    });

    test('confirmed booking does NOT include confirmOtp', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.confirmed,
        paymentStatus: 'PENDING',
      );
      expect(actions, isNot(contains(BookingAction.confirmOtp)));
    });
  });

  group('BookingActionResolver.resolve – payment', () {
    test('pendingPayment with non-cash method includes pay action', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.pendingPayment,
        paymentStatus: 'PENDING',
        paymentMethod: 'GCASH',
      );
      expect(actions, contains(BookingAction.pay));
    });

    test('pendingPayment with PAYMONGO method includes pay action', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.pendingPayment,
        paymentStatus: 'PENDING',
        paymentMethod: 'PAYMONGO',
      );
      expect(actions, contains(BookingAction.pay));
    });

    test('pendingPayment with CASH method does NOT include pay action', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.pendingPayment,
        paymentStatus: 'PENDING',
        paymentMethod: 'CASH',
      );
      expect(actions, isNot(contains(BookingAction.pay)));
    });

    test('paymentProcessing with non-cash includes retryPayment, not pay', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.paymentProcessing,
        paymentStatus: 'PENDING',
        paymentMethod: 'CARD',
      );
      expect(actions, contains(BookingAction.retryPayment));
      expect(actions, isNot(contains(BookingAction.pay)));
    });

    test('paymentPendingConfirmation includes retryPayment, not pay', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.paymentPendingConfirmation,
        paymentStatus: 'PENDING',
        paymentMethod: 'GCASH',
      );
      expect(actions, contains(BookingAction.retryPayment));
      expect(actions, isNot(contains(BookingAction.pay)));
    });

    test('viewReceipt is included when payment is PAID', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.completed,
        paymentStatus: 'PAID',
      );
      expect(actions, contains(BookingAction.viewReceipt));
    });

    test('viewReceipt is NOT included when payment is PENDING', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.completed,
        paymentStatus: 'PENDING',
      );
      expect(actions, isNot(contains(BookingAction.viewReceipt)));
    });
  });

  group('BookingActionResolver.resolve – messaging', () {
    test('assigned booking with workerUid includes message action', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.assigned,
        paymentStatus: 'PENDING',
        workerUid: 'worker-uid-123',
      );
      expect(actions, contains(BookingAction.message));
    });

    test('assigned booking without workerUid does NOT include message', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.assigned,
        paymentStatus: 'PENDING',
        workerUid: null,
      );
      expect(actions, isNot(contains(BookingAction.message)));
    });

    test('terminal booking with workerUid does NOT include message', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.completed,
        paymentStatus: 'PAID',
        workerUid: 'worker-uid-123',
      );
      expect(actions, isNot(contains(BookingAction.message)));
    });
  });

  group('BookingActionResolver.resolve – tracking', () {
    test('enRoute booking includes track action', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.enRoute,
        paymentStatus: 'PAID',
      );
      expect(actions, contains(BookingAction.track));
    });

    test('arrived booking includes track action', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.arrived,
        paymentStatus: 'PAID',
      );
      expect(actions, contains(BookingAction.track));
    });

    test('inProgress booking includes track action', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.inProgress,
        paymentStatus: 'PAID',
      );
      expect(actions, contains(BookingAction.track));
    });

    test('confirmed booking does NOT include track action', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.confirmed,
        paymentStatus: 'PENDING',
      );
      expect(actions, isNot(contains(BookingAction.track)));
    });
  });

  group('BookingActionResolver.resolve – completed', () {
    test('completed booking without review includes reviewService', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.completed,
        paymentStatus: 'PAID',
        hasReview: false,
      );
      expect(actions, contains(BookingAction.reviewService));
    });

    test('completed booking with hasReview=true does NOT include reviewService',
        () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.completed,
        paymentStatus: 'PAID',
        hasReview: true,
      );
      expect(actions, isNot(contains(BookingAction.reviewService)));
    });

    test('completed booking includes bookAgain', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.completed,
        paymentStatus: 'PAID',
      );
      expect(actions, contains(BookingAction.bookAgain));
    });

    test('reviewed booking includes bookAgain', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.reviewed,
        paymentStatus: 'PAID',
      );
      expect(actions, contains(BookingAction.bookAgain));
    });
  });

  group('BookingActionResolver.resolve – cancellation', () {
    test('cancelled booking includes bookAgain', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.cancelled,
        paymentStatus: 'PENDING',
      );
      expect(actions, contains(BookingAction.bookAgain));
    });

    test('cancelled booking does NOT include cancel', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.cancelled,
        paymentStatus: 'PENDING',
      );
      expect(actions, isNot(contains(BookingAction.cancel)));
    });

    test('cancelledByProvider booking does NOT include cancel', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.cancelledByProvider,
        paymentStatus: 'PENDING',
      );
      expect(actions, isNot(contains(BookingAction.cancel)));
    });

    test('inProgress booking (active service) does NOT include cancel', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.inProgress,
        paymentStatus: 'PAID',
      );
      expect(actions, isNot(contains(BookingAction.cancel)));
    });

    test('awaitingAssignment booking (pre-service) includes cancel', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.awaitingAssignment,
        paymentStatus: 'PENDING',
      );
      expect(actions, contains(BookingAction.cancel));
    });

    test('confirmed booking (pre-service) includes cancel', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.confirmed,
        paymentStatus: 'PENDING',
      );
      expect(actions, contains(BookingAction.cancel));
    });

    test('paid booking (pre-service) includes cancel', () {
      final actions = BookingActionResolver.resolve(
        status: BookingStatus.paid,
        paymentStatus: 'PAID',
      );
      expect(actions, contains(BookingAction.cancel));
    });
  });

  group('BookingActionResolver.resolve – contactSupport', () {
    test('every resolved action list always ends with contactSupport', () {
      for (final status in BookingStatus.values) {
        final actions = BookingActionResolver.resolve(
          status: status,
          paymentStatus: 'PENDING',
        );
        expect(
          actions,
          contains(BookingAction.contactSupport),
          reason: 'contactSupport missing for $status',
        );
      }
    });
  });

  // ── primaryAction() ───────────────────────────────────────────────────────

  group('BookingActionResolver.primaryAction', () {
    test('returns confirmOtp for pendingOtp status', () {
      final primary = BookingActionResolver.primaryAction(
        status: BookingStatus.pendingOtp,
        paymentStatus: 'PENDING',
      );
      expect(primary, BookingAction.confirmOtp);
    });

    test('returns pay for pendingPayment with non-cash method', () {
      final primary = BookingActionResolver.primaryAction(
        status: BookingStatus.pendingPayment,
        paymentStatus: 'PENDING',
        paymentMethod: 'GCASH',
      );
      expect(primary, BookingAction.pay);
    });

    test('returns retryPayment for paymentProcessing with non-cash method', () {
      final primary = BookingActionResolver.primaryAction(
        status: BookingStatus.paymentProcessing,
        paymentStatus: 'PENDING',
        paymentMethod: 'CARD',
      );
      expect(primary, BookingAction.retryPayment);
    });

    test('returns null for confirmed status (no primary action required)', () {
      final primary = BookingActionResolver.primaryAction(
        status: BookingStatus.confirmed,
        paymentStatus: 'PAID',
      );
      expect(primary, isNull);
    });

    test('returns null for completed status (review/bookAgain are secondary)',
        () {
      final primary = BookingActionResolver.primaryAction(
        status: BookingStatus.completed,
        paymentStatus: 'PAID',
      );
      expect(primary, isNull);
    });
  });
}
