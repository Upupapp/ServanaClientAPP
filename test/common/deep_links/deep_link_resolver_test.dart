import 'package:flutter_test/flutter_test.dart';

import 'package:client/common/domain/deep_links/deep_link_resolver.dart';

void main() {
  DeepLinkTarget? resolve(String url) =>
      DeepLinkResolver.resolve(Uri.parse(url));

  group('what the app claims', () {
    test('resolves a booking to its detail route, auth required', () {
      final t = resolve('https://servana.com.ph/bookings/123')!;
      expect(t.location, '/bookings/123');
      expect(t.requiresAuth, isTrue);
      expect(t.returnIntent, isNotNull,
          reason: 'signing in must return the customer to the booking, '
              'not drop them on Home');
    });

    test('a service page needs no session', () {
      // An auth wall on the one link a stranger receives is a funnel with no
      // top.
      final t = resolve('https://servana.com.ph/services/180')!;
      expect(t.location, '/services/180');
      expect(t.requiresAuth, isFalse);
    });

    test('conversations, notifications and booking list all resolve', () {
      expect(resolve('https://servana.com.ph/conversations/9')!.location,
          '/messages/9');
      expect(resolve('https://servana.com.ph/notifications')!.location,
          '/notifications');
      expect(resolve('https://servana.com.ph/bookings')!.location, '/bookings');
    });

    test('every claimed prefix actually resolves', () {
      // The intent filters, the AASA paths and this table must agree. A prefix
      // claimed by the manifest but unresolvable here opens the app to nothing.
      for (final p in DeepLinkResolver.claimedPrefixes) {
        final probe = p == '/services' || p == '/bookings'
            ? 'https://servana.com.ph$p/1'
            : 'https://servana.com.ph$p';
        expect(resolve(probe), isNotNull, reason: 'prefix $p resolved to null');
      }
    });
  });

  group('what it refuses', () {
    test('a host outside the allow-list', () {
      // The only thing standing between a Universal Link handler and an
      // attacker-chosen host.
      expect(resolve('https://evil.example.com/bookings/1'), isNull);
      expect(resolve('https://servana.com.ph.evil.com/bookings/1'), isNull);
    });

    test('a non-https scheme', () {
      expect(resolve('http://servana.com.ph/bookings/1'), isNull);
    });

    test('a path the app does not claim', () {
      // Must be null, not Home. "Open in the browser" and "open the app on the
      // wrong screen" are different answers.
      expect(resolve('https://servana.com.ph/admin/payouts'), isNull);
      expect(resolve('https://servana.com.ph/'), isNull);
    });

    test('a non-numeric or oversized identifier', () {
      expect(resolve('https://servana.com.ph/bookings/abc'), isNull);
      expect(resolve('https://servana.com.ph/bookings/-1'), isNull);
      expect(resolve('https://servana.com.ph/bookings/9999999999999999999999'),
          isNull);
    });
  });

  group('path segments cannot retarget the request', () {
    test('an encoded traversal is rejected, not decoded into the route', () {
      // '/bookings/1%2F..%2Fadmin' looks like one segment and is not.
      expect(resolve('https://servana.com.ph/bookings/1%2F..%2Fadmin'), isNull);
    });

    test('an injected query separator is rejected', () {
      expect(resolve('https://servana.com.ph/bookings/1%3Ffoo%3Dbar'), isNull);
    });

    test('a resolved id round-trips to exactly the digits given', () {
      final t = resolve('https://servana.com.ph/bookings/000123')!;
      expect(t.location, '/bookings/000123');
      expect(t.location.contains('/'), isTrue);
      expect(t.location.split('/').length, 3,
          reason: 'the id must not introduce a segment boundary');
    });
  });

  group('a link is untrusted input', () {
    test('no destination performs a mutation', () {
      // Every claimed destination is a READ. A URL that mutates is a URL that
      // mutates when a mail client prefetches it.
      const mutating = ['cancel', 'confirm', 'pay', 'delete', 'refund', 'otp'];
      for (final p in DeepLinkResolver.claimedPrefixes) {
        for (final verb in mutating) {
          expect(p.contains(verb), isFalse, reason: '$p looks like a mutation');
        }
      }
    });

    test('a password-reset link DROPS its token', () {
      // A one-time code in a path or query reaches the nginx access log on
      // every request, and survives in history and referrer headers.
      final t =
          resolve('https://servana.com.ph/reset-password?token=SECRET123&x=1')!;
      expect(t.location, '/reset-password');
      expect(t.location.contains('SECRET123'), isFalse);
      expect(t.location.contains('token'), isFalse);
      expect(t.requiresAuth, isFalse,
          reason: 'a customer resetting a password cannot sign in first');
    });

    test('a token in a path segment is not forwarded either', () {
      final t = resolve('https://servana.com.ph/reset-password/SECRET123')!;
      expect(t.location.contains('SECRET123'), isFalse);
    });
  });
}
