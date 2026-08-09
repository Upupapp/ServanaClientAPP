import 'package:client/common/domain/booking/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingStatusMapper.effectiveWireStatus', () {
    test('shows provider acceptance while bookings.status remains assigned',
        () {
      expect(
        BookingStatusMapper.effectiveWireStatus(
          bookingStatus: 'WORKER_ASSIGNED',
          workerStatus: 'ACCEPTED',
        ),
        'ACCEPTED',
      );
    });

    test('booking cancellation overrides a stale accepted assignment', () {
      expect(
        BookingStatusMapper.effectiveWireStatus(
          bookingStatus: 'CANCELLED',
          workerStatus: 'ACCEPTED',
        ),
        'CANCELLED',
      );
    });

    test('prefers the backend effectiveStatus projection', () {
      expect(
        BookingStatusMapper.effectiveWireStatus(
          bookingStatus: 'WORKER_ASSIGNED',
          workerStatus: 'ASSIGNED',
          effectiveStatus: 'ARRIVED',
        ),
        'ARRIVED',
      );
    });
  });

  group('BookingStatusMapper.fromString', () {
    test('maps common backend strings', () {
      expect(BookingStatusMapper.fromString('PENDING_OTP'),
          BookingStatus.pendingOtp);
      expect(
          BookingStatusMapper.fromString('FOR_OTP'), BookingStatus.pendingOtp);
      expect(BookingStatusMapper.fromString('PAID'), BookingStatus.paid);
      expect(
          BookingStatusMapper.fromString('CONFIRMED'), BookingStatus.confirmed);
      expect(
          BookingStatusMapper.fromString('ASSIGNED'), BookingStatus.assigned);
      expect(
          BookingStatusMapper.fromString('ACCEPTED'), BookingStatus.assigned);
      expect(BookingStatusMapper.fromString('AWAITING_ASSIGNMENT'),
          BookingStatus.awaitingAssignment);
      expect(BookingStatusMapper.fromString('FOR_REVIEW'),
          BookingStatus.awaitingAssignment);
    });

    test('is case-insensitive', () {
      expect(BookingStatusMapper.fromString('paid'), BookingStatus.paid);
      expect(
          BookingStatusMapper.fromString('Confirmed'), BookingStatus.confirmed);
    });

    test('returns unknown for unrecognised values', () {
      expect(BookingStatusMapper.fromString('FOOBAR'), BookingStatus.unknown);
      expect(BookingStatusMapper.fromString(''), BookingStatus.unknown);
    });

    test('returns unknown for null input', () {
      expect(BookingStatusMapper.fromString(null), BookingStatus.unknown);
    });
  });

  group('BookingStatusMapper predicates', () {
    test('requiresPayment', () {
      expect(BookingStatusMapper.requiresPayment(BookingStatus.pendingPayment),
          isTrue);
      expect(BookingStatusMapper.requiresPayment(BookingStatus.paid), isFalse);
      expect(BookingStatusMapper.requiresPayment(BookingStatus.confirmed),
          isFalse);
    });

    test('requiresOtp', () {
      expect(BookingStatusMapper.requiresOtp(BookingStatus.pendingOtp), isTrue);
      expect(BookingStatusMapper.requiresOtp(BookingStatus.confirmed), isFalse);
    });

    test('isGenuineSuccess', () {
      expect(BookingStatusMapper.isGenuineSuccess(BookingStatus.confirmed),
          isTrue);
      expect(
          BookingStatusMapper.isGenuineSuccess(BookingStatus.assigned), isTrue);
      expect(BookingStatusMapper.isGenuineSuccess(BookingStatus.paid), isTrue);
      expect(BookingStatusMapper.isGenuineSuccess(BookingStatus.pendingPayment),
          isFalse);
      expect(
          BookingStatusMapper.isGenuineSuccess(BookingStatus.unknown), isFalse);
    });

    test('shouldPollAssignment', () {
      expect(BookingStatusMapper.shouldPollAssignment(BookingStatus.confirmed),
          isTrue);
      expect(
          BookingStatusMapper.shouldPollAssignment(BookingStatus.paid), isTrue);
      expect(
          BookingStatusMapper.shouldPollAssignment(
              BookingStatus.awaitingAssignment),
          isTrue);
      expect(BookingStatusMapper.shouldPollAssignment(BookingStatus.assigned),
          isFalse);
      expect(BookingStatusMapper.shouldPollAssignment(BookingStatus.cancelled),
          isFalse);
    });
  });

  group('BookingStatusMapper.confirmationTitle', () {
    test('produces non-empty string for every status value', () {
      for (final status in BookingStatus.values) {
        final title = BookingStatusMapper.confirmationTitle(status);
        expect(title, isNotEmpty,
            reason: 'confirmationTitle should not be empty for $status');
      }
    });
  });
}
