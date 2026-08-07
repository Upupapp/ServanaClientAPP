import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('PayMongo success uses payment truth and never assignment state', () {
    final source = read(
      'lib/common/presentation/screens/payment_webview_screen.dart',
    );
    expect(source, contains('PaymentStatusParser.isPaid(booking)'));
    expect(source, isNot(contains('status == BookingStatus.confirmed')));
    expect(source, isNot(contains('status == BookingStatus.assigned')));
    expect(
        source, isNot(contains('status == BookingStatus.awaitingAssignment')));
  });

  test('both checkout paths disclose cancellation terms before submission', () {
    for (final path in [
      'lib/modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart',
      'lib/modules/bw_booking/presentation/screens/bw_checkout_screen.dart',
    ]) {
      final source = read(path);
      final disclosure = source.indexOf('BookingCancellationDisclosure');
      final confirm = source.indexOf("'Confirm Booking'");
      expect(disclosure, greaterThan(0), reason: path);
      expect(confirm, greaterThan(disclosure), reason: path);
      expect(source, contains('Pay provider after service'));
      expect(source, contains('Pay securely now'));
      expect(source, contains('Icons.check_circle'));
    }
  });

  test('booking stages are visible and consistent within each flow', () {
    final aircon = [
      'lib/modules/aircon_booking/presentation/screens/aircon_options_screen.dart',
      'lib/modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart',
      'lib/modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart',
    ].map(read).join('\n');
    expect(RegExp(r'total: 3').allMatches(aircon), hasLength(3));

    final beauty = [
      'lib/modules/bw_booking/presentation/screens/bw_options_screen.dart',
      'lib/modules/bw_booking/presentation/screens/bw_addons_screen.dart',
      'lib/modules/bw_booking/presentation/screens/bw_branch_slot_screen.dart',
      'lib/modules/bw_booking/presentation/screens/bw_checkout_screen.dart',
      'lib/modules/bw_booking/presentation/screens/bw_confirmation_screen.dart',
    ].map(read).join('\n');
    expect(RegExp(r'total: 5').allMatches(beauty), hasLength(5));
  });

  test('customer-facing booking UI consistently uses Provider', () {
    for (final path in [
      'lib/common/presentation/widgets/confirm_assignment_banner.dart',
      'lib/common/presentation/widgets/qr_worker_code_display.dart',
      'lib/modules/bookings/presentation/screens/booking_detail_screen.dart',
    ]) {
      final source = read(path);
      expect(source, isNot(contains("'Technician")), reason: path);
      expect(source, isNot(contains("'technician")), reason: path);
    }
  });

  test('price language separates estimates from completed final total', () {
    final detail = read(
      'lib/modules/bookings/presentation/screens/booking_detail_screen.dart',
    );
    expect(
      detail,
      contains("_isCompleted ? 'Final Total' : 'Estimated Total'"),
    );
  });

  test('shared components expose semantic progress and loading state', () {
    final source = read(
      'lib/common/presentation/widgets/booking_ux_components.dart',
    );
    expect(source, contains(r'Booking step $current of $total'));
    expect(source, contains('liveRegion: true'));
    expect(source, contains('CompactBookingLifecycle'));
    expect(source, contains('ServanaUrls.cancellationPolicy'));
  });
}
