import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deny by default', () {
    test('a default build enables nothing', () {
      // This is the property that keeps /api/v1 out of production while it is
      // absent from the backend's origin/main. If this test ever fails, a
      // build define leaked into the default configuration.
      const availability = CanonicalAvailability();
      expect(availability.enabled, isFalse);
      expect(availability.capabilities, isEmpty);
      expect(availability.isFullyLegacy, isTrue);
      for (final capability in V1Capability.values) {
        expect(availability.isAvailable(capability), isFalse,
            reason: '${capability.name} must be off by default');
      }
    });

    test('the master switch alone moves no traffic', () {
      // An operator who enables v1 and forgets the capability list gets
      // nothing, which is the safe direction.
      const availability =
          CanonicalAvailability(enabled: true, capabilities: <V1Capability>{});
      expect(availability.enabled, isTrue);
      expect(availability.isAvailable(V1Capability.catalog), isFalse);
      expect(availability.isFullyLegacy, isTrue);
    });

    test('a capability alone moves no traffic without the master switch', () {
      const availability = CanonicalAvailability(
        enabled: false,
        capabilities: <V1Capability>{V1Capability.catalog},
      );
      expect(availability.isAvailable(V1Capability.catalog), isFalse);
    });

    test('both together enable exactly that capability and no other', () {
      const availability = CanonicalAvailability(
        enabled: true,
        capabilities: <V1Capability>{V1Capability.notifications},
      );
      expect(availability.isAvailable(V1Capability.notifications), isTrue);
      expect(availability.isAvailable(V1Capability.catalog), isFalse);
      expect(availability.isFullyLegacy, isFalse);
    });
  });

  group('capability vocabulary', () {
    test('omits domains whose canonical surface is incomplete', () {
      // TAB 01 found booking creation has no canonical endpoint, reviews have
      // 4 of 9, and the v1 support relative is narrower than the legacy one.
      // Naming them here would let a build claim a migration it cannot make.
      final names = V1Capability.values.map((c) => c.name).toList();
      expect(names, isNot(contains('bookings')));
      expect(names, isNot(contains('booking')));
      expect(names, isNot(contains('reviews')));
      expect(names, isNot(contains('support')));
    });

    test('a narrowed slice may be named, and must say so', () {
      // TAB 09 migrated the three booking READS, which do have successors,
      // while create still does not. The rule that keeps this honest is about
      // the NAME: `bookings` would claim the domain, `bookingReads` claims the
      // reads. If someone later widens this value to cover cancel or create,
      // the name stops matching what it does — and this test is where that
      // shows up.
      final names = V1Capability.values.map((c) => c.name).toList();
      expect(names, contains('bookingReads'));

      // Nothing in the vocabulary may be named for a booking WRITE while
      // `POST /api/v1/bookings` does not exist.
      for (final forbidden in ['bookingCreate', 'bookingWrites', 'bookingAll']) {
        expect(names, isNot(contains(forbidden)),
            reason: 'no canonical booking write exists — see '
                'docs/convergence-v1/TAB08_ENDPOINT_GAP.md');
      }
    });

    test('TAB 10 adds two more slices, and neither widens to the domain', () {
      // `bookingLifecycle` names actions on an already-existing booking;
      // `bookingTracking` names one read. Creation still has no successor, so
      // the three booking values together still must not add up to a claim
      // that the domain migrated.
      final names = V1Capability.values.map((c) => c.name).toList();
      expect(names, contains('bookingLifecycle'));
      expect(names, contains('bookingTracking'));

      // The rule from TAB 09, re-asserted against the new values: the guard
      // must catch a rename that widens the claim, not just the three strings
      // somebody happened to think of first.
      for (final name in names) {
        final isBookingValue = name.startsWith('booking');
        if (!isBookingValue) continue;
        expect(
          <String>[
            'bookingReads',
            'bookingLifecycle',
            'bookingTracking',
            'bookingPayments',
          ],
          contains(name),
          reason: '"$name" is a new booking capability. A value named for the '
              'booking DOMAIN would claim creation migrated, and it has not — '
              'see docs/convergence-v1/TAB08_ENDPOINT_GAP.md. Add it to this '
              'list only after naming the slice it actually covers.',
        );
      }
    });

    test('reads, actions and tracking are independently switchable', () {
      // The whole reason there are three values. Enabling reads must not start
      // routing a CANCELLATION over an undeployed namespace, and enabling
      // actions must not silently move the position-privacy boundary.
      const readsOnly = CanonicalAvailability(
        enabled: true,
        capabilities: <V1Capability>{V1Capability.bookingReads},
      );
      expect(readsOnly.isAvailable(V1Capability.bookingReads), isTrue);
      expect(readsOnly.isAvailable(V1Capability.bookingLifecycle), isFalse);
      expect(readsOnly.isAvailable(V1Capability.bookingTracking), isFalse);

      const actionsOnly = CanonicalAvailability(
        enabled: true,
        capabilities: <V1Capability>{V1Capability.bookingLifecycle},
      );
      expect(actionsOnly.isAvailable(V1Capability.bookingReads), isFalse);
      expect(actionsOnly.isAvailable(V1Capability.bookingTracking), isFalse);
      expect(actionsOnly.isAvailable(V1Capability.bookingPayments), isFalse);
    });

    test('payments is not named for the finance domain', () {
      // TAB 11. `finance` also contains provider earnings, payouts and admin
      // reconciliation — four surfaces a CUSTOMER app may never call. A value
      // called `finance` would claim them; `bookingPayments` claims the three
      // booking-scoped customer endpoints and nothing else.
      final names = V1Capability.values.map((c) => c.name).toList();
      expect(names, contains('bookingPayments'));
      for (final forbidden in <String>[
        'finance',
        'payments',
        'earnings',
        'payouts',
      ]) {
        expect(names, isNot(contains(forbidden)),
            reason: '"$forbidden" would claim surfaces this client cannot call');
      }
    });
  });

  group('CanonicalRouter', () {
    test('selects the compatibility source when unavailable', () {
      const router =
          CanonicalRouter(availability: CanonicalAvailability());
      expect(
        router.select<String>(V1Capability.notifications,
            canonical: 'v1', compatibility: 'legacy'),
        'legacy',
      );
      expect(router.isCanonical(V1Capability.notifications), isFalse);
    });

    test('selects the canonical source when available', () {
      const router = CanonicalRouter(
        availability: CanonicalAvailability(
          enabled: true,
          capabilities: <V1Capability>{V1Capability.notifications},
        ),
      );
      expect(
        router.select<String>(V1Capability.notifications,
            canonical: 'v1', compatibility: 'legacy'),
        'v1',
      );
      expect(router.isCanonical(V1Capability.notifications), isTrue);
    });

    test('routes each capability independently', () {
      const router = CanonicalRouter(
        availability: CanonicalAvailability(
          enabled: true,
          capabilities: <V1Capability>{V1Capability.catalog},
        ),
      );
      expect(
          router.select<String>(V1Capability.catalog,
              canonical: 'v1', compatibility: 'legacy'),
          'v1');
      expect(
          router.select<String>(V1Capability.notifications,
              canonical: 'v1', compatibility: 'legacy'),
          'legacy');
    });
  });
}
