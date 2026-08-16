/// An unknown coordinate must reach tracking as null, not as zero.
///
/// Round-2 sibling of the "₱0.00 on every booking" finding. Both are the same
/// mistake: a missing value collapsed to a numeric zero, which then reads as
/// real data to everything downstream.
///
/// `TrackingRepository` resolves the service location as
///
///     (b['latitude'] as num?)?.toDouble() ?? seedLatitude ?? 14.5995
///
/// — a deliberate three-step fallback ending at Manila when nothing is known.
/// But `JobOrder.latitude` is a non-nullable double, so the booking detail
/// screen collapses an absent coordinate to `0`, and `0.0` is not null. It wins
/// the `??` chain, the Manila default never runs, and the tracking map opens on
/// 0°N 0°E — the Gulf of Guinea, roughly 11,000 km from any Servana booking.
///
/// This is not a hypothetical. `getBookingById` cannot supply these
/// coordinates: `user_address` has no lat/lon columns at all — they live in
/// MongoDB keyed by `location_id` — so the field is absent from every response
/// and this path is taken every time.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _code(String path) => File(path).readAsLinesSync().where((l) {
      final t = l.trimLeft();
      return !t.startsWith('//') && !t.startsWith('///');
    }).join('\n');

void main() {
  late final String screen;
  late final String repo;

  setUpAll(() {
    screen = _code(
        'lib/modules/bookings/presentation/screens/booking_detail_screen.dart');
    // TAB 10 put a router in front of TrackingRepository, and the two-call
    // stitch this file is about — including the seed chain — moved into the
    // compatibility source verbatim. Following the code rather than relaxing
    // the assertion: the chain is still the thing being pinned, and it is
    // still the one every shipped build runs.
    repo = _code(
        'lib/modules/tracking/data/tracking_compatibility_data_source.dart');
  });

  group('the fallback the fix depends on still exists', () {
    test('TrackingRepository still falls back to Manila', () {
      // If this chain changes, the reasoning behind passing null changes with
      // it. Pinned so the fix cannot be quietly orphaned.
      expect(repo, contains('seedLatitude'));
      expect(repo, contains('14.5995'));
      expect(repo, contains('120.9842'));
    });

    test('it is a null-coalescing chain, so zero would defeat it', () {
      // The distinction the whole fix rests on: `??` falls through on null and
      // NOT on 0.
      expect(repo, contains('?? seedLatitude ??'));
    });
  });

  group('the booking screen does not send zero', () {
    test('it converts a zero coordinate to null', () {
      expect(screen, contains('static double? _nullIfZero(double? v)'));
      expect(screen, contains('(v == null || v == 0) ? null : v'));
    });

    test('both coordinates go through it', () {
      // Fixing one and not the other would seed a map on the equator at the
      // booking's real longitude, which is harder to spot than 0,0.
      expect(screen, contains('serviceLatitude: _nullIfZero('));
      expect(screen, contains('serviceLongitude: _nullIfZero('));
    });

    test('neither is passed raw any more', () {
      expect(screen, isNot(contains('serviceLatitude: _booking?.latitude')));
      expect(screen, isNot(contains('serviceLongitude: _booking?.longitude')));
    });
  });

  group('the conversion behaves', () {
    // The helper is private, so this restates it. Kept because the boundary
    // cases are the point: 0 is unknown, everything else is a location.
    double? nullIfZero(double? v) => (v == null || v == 0) ? null : v;

    test('zero and null both become null', () {
      expect(nullIfZero(0), isNull);
      expect(nullIfZero(0.0), isNull);
      expect(nullIfZero(null), isNull);
    });

    test('a real Philippine coordinate passes through', () {
      // Manila, Taguig, Cebu, and a southern latitude — nothing near zero.
      expect(nullIfZero(14.5995), 14.5995);
      expect(nullIfZero(120.9842), 120.9842);
      expect(nullIfZero(14.5535), 14.5535);
      expect(nullIfZero(10.3157), 10.3157);
    });

    test('a negative coordinate is not treated as unknown', () {
      // Servana is in the Philippines today, but a helper that silently ate
      // southern or western hemispheres would be a trap for whoever expands.
      expect(nullIfZero(-33.8688), -33.8688);
      expect(nullIfZero(-70.6693), -70.6693);
    });

    test('a near-zero-but-real coordinate survives', () {
      // 0.0001° is ~11 metres off the equator. Only exact zero is "unknown".
      expect(nullIfZero(0.0001), 0.0001);
    });
  });
}
