import 'dart:io';

import 'package:client/common/domain/booking/payment_status_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authoritative PayMongo payment parsing', () {
    test('accepts compatible camel, snake, and nested response shapes', () {
      expect(PaymentStatusParser.isPaid({'paymentStatus': 'paid'}), isTrue);
      expect(PaymentStatusParser.isPaid({'payment_status': 'PAID'}), isTrue);
      expect(
        PaymentStatusParser.isPaid({
          'payment': {'status': 'payment_paid'},
        }),
        isTrue,
      );
    });

    test('never treats booking lifecycle or provider assignment as payment',
        () {
      for (final status in [
        'CONFIRMED',
        'AWAITING_ASSIGNMENT',
        'ASSIGNED',
        'WORKER_ASSIGNED',
        'COMPLETED',
      ]) {
        expect(
          PaymentStatusParser.isPaid({'status': status}),
          isFalse,
          reason: status,
        );
      }
    });

    test('failed PayMongo payments remain actionable for retry', () {
      expect(PaymentStatusParser.requiresPayment('PENDING'), isTrue);
      expect(PaymentStatusParser.requiresPayment('FAILED'), isTrue);
      expect(PaymentStatusParser.requiresPayment('PAYMENT_FAILED'), isTrue);
      expect(PaymentStatusParser.requiresPayment('PAID'), isFalse);
    });

    test('backend payment aliases normalize before UI/action decisions', () {
      expect(PaymentStatusParser.normalize('payment_paid'), 'PAID');
      expect(PaymentStatusParser.normalize('payment_failed'), 'FAILED');
      expect(PaymentStatusParser.requiresPayment('payment_failed'), isTrue);
    });
  });

  test('checkout validates the initial host before loading the WebView', () {
    final source = File(
      'lib/common/presentation/screens/payment_webview_screen.dart',
    ).readAsStringSync();
    final validation = source.indexOf('!_isApprovedHost(uri.host)');
    final load = source.indexOf('..loadRequest(uri)');
    expect(validation, greaterThan(0));
    expect(load, greaterThan(validation));
  });

  test('success redirect waits for webhook instead of returning false', () {
    final source = File(
      'lib/common/presentation/screens/payment_webview_screen.dart',
    ).readAsStringSync();
    final methodStart = source.indexOf('Future<void> _verifyAndClose()');
    final methodEnd =
        source.indexOf('Future<void> _manualCheck()', methodStart);
    final method = source.substring(methodStart, methodEnd);
    expect(method, contains('_startPolling();'));
    expect(method, contains('Waiting for confirmation'));
    expect(method, isNot(contains('Navigator.of(context).pop(paid)')));
  });

  test('callback paths align with backend PayMongo session URLs', () {
    final source = File(
      'lib/common/presentation/screens/payment_webview_screen.dart',
    ).readAsStringSync();
    expect(source, contains("'/payment-success'"));
    expect(source, contains("'/payment-cancel'"));
  });

  test('both stores suppress duplicate session requests and stale URLs', () {
    for (final path in [
      'lib/modules/aircon_booking/data/aircon_booking_store.dart',
      'lib/modules/bw_booking/data/bw_booking_store.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('createdBookingId == null || isPaymentLoading'),
        reason: path,
      );
      expect(source, contains('paymongoCheckoutUrl = null;'), reason: path);
      expect(source, contains('PaymentStatusParser.isPaid(booking)'),
          reason: path);
    }
  });
}
