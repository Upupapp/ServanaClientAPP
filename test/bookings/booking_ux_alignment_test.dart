import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('PayMongo success uses payment truth and never assignment state', () {
    final source = read(
      'lib/common/presentation/screens/payment_webview_screen.dart',
    );
    // The rule is unchanged: only the payment record may close checkout as
    // paid. TAB 11 moved WHERE that is decided — the screen used to fetch the
    // whole booking and call PaymentStatusParser inline, which was the third
    // copy of the same code. It now asks the one payment ceremony.
    //
    // Following the code rather than relaxing the assertion: the negative
    // clauses below are the actual protection and they are untouched.
    expect(source, contains('PaymentsRepository'));
    expect(source, contains('.isPaid('));
    expect(source, isNot(contains('status == BookingStatus.confirmed')));
    expect(source, isNot(contains('status == BookingStatus.assigned')));
    expect(
        source, isNot(contains('status == BookingStatus.awaitingAssignment')));
  });

  test('payment truth is decided in exactly one place', () {
    // What the assertion above can no longer prove on its own, now that the
    // decision lives behind a repository. Before TAB 11 there were three
    // implementations of "is it paid" — both booking stores and the checkout
    // screen — each with its own envelope fallback chain.
    final decisive = read('lib/modules/payments/data/payments_repository.dart');
    expect(decisive, contains('Future<bool> isPaid('));

    for (final path in [
      'lib/common/presentation/screens/payment_webview_screen.dart',
      'lib/modules/aircon_booking/data/aircon_booking_store.dart',
      'lib/modules/bw_booking/data/bw_booking_store.dart',
    ]) {
      final source = read(path);
      // None of them re-derives the answer from a booking payload any more.
      expect(source, isNot(contains('PaymentStatusParser.isPaid')), reason: path);
      expect(source, contains('PaymentsRepository'), reason: path);
    }
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
