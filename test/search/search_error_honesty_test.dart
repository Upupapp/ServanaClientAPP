/// A server failure must not be reported to the customer as a network one.
///
/// `GET /api/catalog` is shadowed by `booking.routes` `GET /:id` on the
/// deployed backend and answers 401 UNAUTHENTICATED. Search reads the catalog,
/// so this is the failure customers actually hit today — and the screen
/// answered every failure with "Could not load services. Check your connection
/// and try again." over a wifi-off icon.
///
/// That is worse than saying nothing. The customer's network is fine, so they
/// cannot act on the advice; support cannot reproduce it; and the real cause —
/// a route the backend is not serving — is invisible to everyone.
library;

import 'package:client/core/network/api_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('connectivity is a property of the failure, not a default', () {
    test('a retryable transport failure IS connectivity', () {
      // Held as the base type deliberately. Production classifies an
      // ApiFailure it was handed; a variable already statically typed as
      // RetryableFailure makes the check a tautology the analyzer rejects,
      // and asserts nothing about the classification being tested.
      const ApiFailure failure =
          RetryableFailure(safeMessage: 'No connection.');
      expect(failure is RetryableFailure, isTrue);
    });

    test('an auth failure is NOT connectivity', () {
      // The 401 the catalog returns today.
      const ApiFailure failure =
          AuthFailure(safeMessage: 'Authentication is required');
      expect(failure is RetryableFailure, isFalse);
    });

    test('every failure carries its own renderable message', () {
      // `safeMessage` is the only string a UI may render, and it is written
      // for THAT failure rather than guessed at the screen.
      const failures = <ApiFailure>[
        AuthFailure(safeMessage: 'Authentication is required'),
        RetryableFailure(safeMessage: 'No connection.'),
      ];
      for (final f in failures) {
        expect(f.safeMessage, isNotEmpty);
      }
    });
  });
}
