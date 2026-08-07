import 'package:client/common/domain/booking/booking_create_response_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingCreateResponseParser', () {
    test('accepts current booking envelope', () {
      final result = BookingCreateResponseParser.parse({
        'success': true,
        'booking': {'bookingId': 41, 'workerCode': 'ABC123'},
      });

      expect(result.bookingId, 41);
      expect(result.workerCode, 'ABC123');
    });

    test('accepts top-level and backward-compatible snake_case fields', () {
      final result = BookingCreateResponseParser.parse({
        'booking_id': '42',
        'worker_code': ' LEGACY ',
      });

      expect(result.bookingId, 42);
      expect(result.workerCode, 'LEGACY');
    });

    test('accepts data.booking envelope without losing the nested ID', () {
      final result = BookingCreateResponseParser.parse({
        'data': {
          'booking': {'id': '43'},
        },
      });

      expect(result.bookingId, 43);
      expect(result.workerCode, isNull);
    });

    test('rejects missing, zero, negative, and malformed IDs', () {
      for (final response in [
        <String, dynamic>{'success': true},
        <String, dynamic>{
          'booking': {'id': 0}
        },
        <String, dynamic>{
          'data': {'bookingId': -1}
        },
        <String, dynamic>{'bookingId': 'not-an-id'},
      ]) {
        expect(
          () => BookingCreateResponseParser.parse(response),
          throwsFormatException,
        );
      }
    });
  });
}
