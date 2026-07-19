import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/domain/booking/booking_submission_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingSubmissionResult factories', () {
    test('success carries bookingId and status', () {
      final result = BookingSubmissionResult.success(
        bookingId: 42,
        status: BookingStatus.confirmed,
      );
      expect(result.success, isTrue);
      expect(result.bookingId, 42);
      expect(result.errorMessage, isNull);
    });

    test('failure carries message and category', () {
      final result = BookingSubmissionResult.failure(
        message: 'Something went wrong',
        category: BookingErrorCategory.networkUnavailable,
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Something went wrong');
      expect(result.errorCategory, BookingErrorCategory.networkUnavailable);
    });

    test('missingBookingId is not a success', () {
      final result = BookingSubmissionResult.missingBookingId();
      expect(result.success, isFalse);
      expect(result.errorCategory, BookingErrorCategory.serverFailure);
    });
  });

  group('BookingErrorMapper.fromException', () {
    test('network category for socket-like message', () {
      final (:category, :message) =
          BookingErrorMapper.fromException(Exception('SocketException'));
      expect(category, BookingErrorCategory.networkUnavailable);
    });

    test('duplicate category for "already" message', () {
      final (:category, :message) =
          BookingErrorMapper.fromException(Exception('already exists'));
      expect(category, BookingErrorCategory.duplicateSubmission);
    });

    test('slot unavailable for slot message', () {
      final (:category, :message) =
          BookingErrorMapper.fromException(Exception('slot unavailable'));
      expect(category, BookingErrorCategory.slotUnavailable);
    });

    test('returns serverFailure for unknown exception', () {
      final (:category, :message) =
          BookingErrorMapper.fromException(Exception('some random error xyz'));
      expect(category, BookingErrorCategory.serverFailure);
      expect(message, isNotEmpty);
    });
  });
}
