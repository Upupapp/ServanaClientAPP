import 'package:client/common/domain/auth/auth_return_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthReturnIntent.validated — allow-list', () {
    test('known routeName passes validation', () {
      final intent = AuthReturnIntent.validated(
        destination: ProtectedDestination.bookings,
        routeName: 'Bookings',
      );
      expect(intent, isNotNull);
      expect(intent!.routeName, equals('Bookings'));
    });

    test('unknown routeName returns null (open-redirect guard)', () {
      final intent = AuthReturnIntent.validated(
        destination: ProtectedDestination.bookings,
        routeName: 'http://evil.example.com',
      );
      expect(intent, isNull);
    });

    test('null routeName is allowed (uses destination default)', () {
      final intent = AuthReturnIntent.validated(
        destination: ProtectedDestination.profile,
        routeName: null,
      );
      expect(intent, isNotNull);
      expect(intent!.routeName, isNull);
    });

    test('all allowed route names pass', () {
      const allowed = ['Bookings', 'BookingDetail', 'Messages', 'BookingChat', 'Profile', 'Notifications'];
      for (final r in allowed) {
        final intent = AuthReturnIntent.validated(
          destination: ProtectedDestination.bookings,
          routeName: r,
        );
        expect(intent, isNotNull, reason: '$r should be allowed');
      }
    });
  });

  group('AuthReturnIntent.displayReason', () {
    test('uses custom gateReason when provided', () {
      const intent = AuthReturnIntent(
        destination: ProtectedDestination.bookings,
        gateReason: 'to view your upcoming jobs',
      );
      expect(intent.displayReason, equals('to view your upcoming jobs'));
    });

    test('falls back to destination default when gateReason is null', () {
      const intent = AuthReturnIntent(
        destination: ProtectedDestination.bookings,
      );
      expect(intent.displayReason, contains('booking'));
    });

    test('each destination has a non-empty default reason', () {
      for (final dest in ProtectedDestination.values) {
        final intent = AuthReturnIntent(destination: dest);
        expect(intent.displayReason, isNotEmpty,
            reason: '${dest.name} must have a display reason');
      }
    });
  });
}
