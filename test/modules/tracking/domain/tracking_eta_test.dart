import 'package:client/modules/tracking/domain/tracking_eta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final base = DateTime(2026, 7, 28, 10, 0, 0);

  group('TrackingEta.fromBookingMap', () {
    test('parses camelCase etaMinutes + etaAt', () {
      final eta = TrackingEta.fromBookingMap({
        'etaMinutes': 15,
        'etaAt': base.toIso8601String(),
      });
      expect(eta, isNotNull);
      expect(eta!.etaMinutes, 15);
      expect(eta.etaAt, equals(base));
    });

    test('parses snake_case eta_minutes + eta_at', () {
      final eta = TrackingEta.fromBookingMap({
        'eta_minutes': 20,
        'eta_at': base.toIso8601String(),
      });
      expect(eta, isNotNull);
      expect(eta!.etaMinutes, 20);
    });

    test('camelCase takes priority over snake_case', () {
      final eta = TrackingEta.fromBookingMap({
        'etaMinutes': 10,
        'eta_minutes': 99,
        'etaAt': base.toIso8601String(),
      });
      expect(eta!.etaMinutes, 10);
    });

    test('returns null when etaMinutes is missing', () {
      expect(TrackingEta.fromBookingMap({'etaAt': base.toIso8601String()}),
          isNull);
    });

    test('returns null when etaAt is missing', () {
      expect(TrackingEta.fromBookingMap({'etaMinutes': 15}), isNull);
    });

    test('returns null when etaAt is not a valid ISO string', () {
      expect(
        TrackingEta.fromBookingMap({'etaMinutes': 15, 'etaAt': 'not-a-date'}),
        isNull,
      );
    });

    test('parses etaMinutes as double correctly', () {
      final eta = TrackingEta.fromBookingMap({
        'etaMinutes': 12.7,
        'etaAt': base.toIso8601String(),
      });
      expect(eta!.etaMinutes, 12);
    });
  });

  group('TrackingEta.isExpired', () {
    late TrackingEta eta;

    setUp(() {
      eta = TrackingEta(
        etaMinutes: 15,
        etaAt: base,
        computedAt: base.subtract(const Duration(minutes: 15)),
      );
    });

    test('returns false before eta arrives', () {
      final now = base.subtract(const Duration(minutes: 5));
      expect(eta.isExpired(now), isFalse);
    });

    test('returns false at exactly the etaAt time', () {
      expect(eta.isExpired(base), isFalse);
    });

    test('returns true one second after etaAt', () {
      final now = base.add(const Duration(seconds: 1));
      expect(eta.isExpired(now), isTrue);
    });
  });

  group('TrackingEta.remainingMinutes', () {
    late TrackingEta eta;

    setUp(() {
      eta = TrackingEta(
        etaMinutes: 15,
        etaAt: base,
        computedAt: base.subtract(const Duration(minutes: 15)),
      );
    });

    test('returns minutes remaining when not expired', () {
      final now = base.subtract(const Duration(minutes: 5));
      expect(eta.remainingMinutes(now), 5);
    });

    test('returns 0 when exactly at etaAt', () {
      expect(eta.remainingMinutes(base), 0);
    });

    test('returns 0 (clamped) when expired', () {
      final now = base.add(const Duration(minutes: 10));
      expect(eta.remainingMinutes(now), 0);
    });
  });
}
