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
      expect(names, isNot(contains('reviews')));
      expect(names, isNot(contains('support')));
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
