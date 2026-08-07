import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/modules/bookings/presentation/screens/booking_detail_screen.dart',
  ).readAsStringSync();

  test('paid and cash bookings remain awaiting assignment without a worker',
      () {
    expect(source, contains("statusLabel = paymentMethod == 'PAYMONGO'"));
    expect(source, contains("? 'PENDING_PAYMENT'"));
    expect(source, contains(": 'AWAITING_ASSIGNMENT'"));
    expect(source, isNot(contains("else if (paymentStatus == 'PAID')")));
  });

  test('awaiting-assignment bookings continue polling for a worker', () {
    expect(source, contains("s == 'AWAITING_ASSIGNMENT'"));
    expect(
      source,
      isNot(contains(
        'if (_needsPayment) return false; // assignment only happens after payment',
      )),
    );
  });

  test('confirmation screens separate creation, assignment, and payment', () {
    for (final path in [
      'lib/modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart',
      'lib/modules/bw_booking/presentation/screens/bw_confirmation_screen.dart',
    ]) {
      final confirmation = File(path).readAsStringSync();
      expect(confirmation, contains("'Booking Created'"));
      expect(
        confirmation,
        contains('Awaiting an assigned worker.'),
      );
      expect(confirmation, contains('store.createPaymongoSession();'));
      expect(confirmation, contains("'PayMongo — available now'"));
      expect(
        confirmation,
        contains("'Cash — pay provider after service'"),
      );
      expect(
        confirmation,
        contains('if (store.createdBookingId != null) ...['),
      );
      expect(
        confirmation,
        isNot(contains('(!isPaymongo || _paymongoCompleted)')),
      );
    }
  });
}
