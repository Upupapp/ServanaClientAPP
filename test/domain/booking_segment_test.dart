import 'package:client/common/domain/booking/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingStatus enum', () {
    test('fromString maps Action Required statuses correctly', () {
      expect(BookingStatusMapper.fromString('PENDING_OTP'),
          BookingStatus.pendingOtp);
      expect(BookingStatusMapper.fromString('FOR_OTP'),
          BookingStatus.pendingOtp);
      expect(BookingStatusMapper.fromString('PENDING_PAYMENT'),
          BookingStatus.pendingPayment);
      expect(BookingStatusMapper.fromString('PAYMENT_PROCESSING'),
          BookingStatus.paymentProcessing);
    });

    test('fromString maps Upcoming statuses correctly', () {
      expect(BookingStatusMapper.fromString('PAID'), BookingStatus.paid);
      expect(BookingStatusMapper.fromString('AWAITING_ASSIGNMENT'),
          BookingStatus.awaitingAssignment);
      // FOR_REVIEW is the old alias for awaiting-assignment
      expect(BookingStatusMapper.fromString('FOR_REVIEW'),
          BookingStatus.awaitingAssignment);
      expect(
          BookingStatusMapper.fromString('ASSIGNED'), BookingStatus.assigned);
      expect(BookingStatusMapper.fromString('ACCEPTED'),
          BookingStatus.assigned);
      expect(BookingStatusMapper.fromString('CONFIRMED'),
          BookingStatus.confirmed);
    });

    test('fromString maps Active statuses correctly', () {
      expect(BookingStatusMapper.fromString('EN_ROUTE'),
          BookingStatus.enRoute);
      expect(BookingStatusMapper.fromString('IN_TRANSIT'),
          BookingStatus.enRoute);
      expect(BookingStatusMapper.fromString('WORKER_ASSIGNED'),
          BookingStatus.enRoute);
      expect(
          BookingStatusMapper.fromString('ARRIVED'), BookingStatus.arrived);
      expect(BookingStatusMapper.fromString('IN_PROGRESS'),
          BookingStatus.inProgress);
      expect(BookingStatusMapper.fromString('STARTED'),
          BookingStatus.inProgress);
      expect(BookingStatusMapper.fromString('AWAITING_COMPLETION'),
          BookingStatus.awaitingCompletion);
    });

    test('fromString maps Completed statuses correctly', () {
      expect(BookingStatusMapper.fromString('COMPLETED'),
          BookingStatus.completed);
      expect(BookingStatusMapper.fromString('DONE'), BookingStatus.completed);
      expect(BookingStatusMapper.fromString('REVIEWED'),
          BookingStatus.reviewed);
    });

    test('fromString maps Cancelled statuses correctly', () {
      expect(BookingStatusMapper.fromString('CANCELLED'),
          BookingStatus.cancelled);
      expect(BookingStatusMapper.fromString('EXPIRED'),
          BookingStatus.expired);
      expect(BookingStatusMapper.fromString('FAILED'), BookingStatus.failed);
      expect(BookingStatusMapper.fromString('CANCELLED_BY_PROVIDER'),
          BookingStatus.cancelledByProvider);
      expect(BookingStatusMapper.fromString('CANCELLED_BY_ADMIN'),
          BookingStatus.cancelledByAdmin);
      expect(BookingStatusMapper.fromString('REFUNDED'),
          BookingStatus.refunded);
    });

    test('fromString returns unknown for unrecognised values', () {
      expect(BookingStatusMapper.fromString('GIBBERISH'),
          BookingStatus.unknown);
      expect(BookingStatusMapper.fromString(''), BookingStatus.unknown);
      expect(BookingStatusMapper.fromString(null), BookingStatus.unknown);
    });

    test('requiresOtp is true only for pendingOtp', () {
      expect(BookingStatusMapper.requiresOtp(BookingStatus.pendingOtp), isTrue);
      for (final s in BookingStatus.values) {
        if (s != BookingStatus.pendingOtp) {
          expect(BookingStatusMapper.requiresOtp(s), isFalse,
              reason: '${s.name} should NOT require OTP');
        }
      }
    });

    test('requiresPayment covers payment-pending states', () {
      expect(BookingStatusMapper.requiresPayment(BookingStatus.pendingPayment),
          isTrue);
      expect(BookingStatusMapper.requiresPayment(BookingStatus.otpVerified),
          isTrue);
      expect(BookingStatusMapper.requiresPayment(BookingStatus.completed),
          isFalse);
      expect(BookingStatusMapper.requiresPayment(BookingStatus.cancelled),
          isFalse);
    });

    test('isGenuineSuccess is true for success terminal states', () {
      expect(
          BookingStatusMapper.isGenuineSuccess(BookingStatus.confirmed), isTrue);
      expect(
          BookingStatusMapper.isGenuineSuccess(BookingStatus.assigned), isTrue);
      expect(BookingStatusMapper.isGenuineSuccess(BookingStatus.paid), isTrue);
      expect(
          BookingStatusMapper.isGenuineSuccess(BookingStatus.cancelled), isFalse);
      expect(
          BookingStatusMapper.isGenuineSuccess(BookingStatus.failed), isFalse);
    });

    test('confirmationTitle covers all enum values without throwing', () {
      for (final s in BookingStatus.values) {
        expect(() => BookingStatusMapper.confirmationTitle(s), returnsNormally,
            reason: '${s.name} must have a title');
        expect(BookingStatusMapper.confirmationTitle(s), isNotEmpty);
      }
    });

    test('confirmationSubtitle covers all enum values without throwing', () {
      for (final s in BookingStatus.values) {
        expect(
            () => BookingStatusMapper.confirmationSubtitle(s), returnsNormally,
            reason: '${s.name} must have a subtitle');
        expect(BookingStatusMapper.confirmationSubtitle(s), isNotEmpty);
      }
    });

    test('case-insensitive fromString', () {
      expect(BookingStatusMapper.fromString('pending_otp'),
          BookingStatus.pendingOtp);
      expect(BookingStatusMapper.fromString('Completed'),
          BookingStatus.completed);
    });
  });
}
