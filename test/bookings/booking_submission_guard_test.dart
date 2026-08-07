import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final path in [
    'lib/modules/aircon_booking/data/aircon_booking_store.dart',
    'lib/modules/bw_booking/data/bw_booking_store.dart',
  ]) {
    test('$path releases submission guard when authentication is absent', () {
      final source = File(path).readAsStringSync();
      final unauthenticated = source.substring(
        source.indexOf('if (userId.isEmpty)'),
        source.indexOf('// Generate a stable idempotency key once'),
      );

      expect(unauthenticated, contains('isSubmitting = false;'));
      expect(unauthenticated, contains('return;'));
    });

    test('$path validates the create response before resolving its journal',
        () {
      final source = File(path).readAsStringSync();
      expect(source, contains('BookingCreateResponseParser.parse(res)'));
      expect(
        source.indexOf('BookingCreateResponseParser.parse(res)'),
        lessThan(source.indexOf('resolveIdempotencyKey')),
      );
      expect(source, contains('await journal.record'));
      expect(source, contains("type: 'booking.create'"));
    });

    test('$path rejects incomplete drafts before creating an idempotency key',
        () {
      final source = File(path).readAsStringSync();
      final validation = source.indexOf("failureCode: 'invalid_draft'");
      final keyCreation = source.indexOf('_idempotencyKey ??= _uuidV4()');
      expect(validation, greaterThan(-1));
      expect(validation, lessThan(keyCreation));
      expect(source, contains('isSubmitting = false;'));
    });
  }
}
