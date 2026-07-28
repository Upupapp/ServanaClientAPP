import 'package:client/modules/tracking/domain/geo_position_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoPositionSnapshot.fromApiMap', () {
    const validUpdatedAt = '2026-07-28T10:15:00.000Z';

    Map<String, dynamic> makeMap(List<dynamic> coords) => {
          'loc': {
            'type': 'Point',
            'coordinates': coords,
          },
          'updatedAt': validUpdatedAt,
        };

    test('parses valid GeoJSON doc — swaps [lon, lat] to LatLng(lat, lon)', () {
      final map = makeMap([121.0244, 14.5547]);
      final snap = GeoPositionSnapshot.fromApiMap(map);
      expect(snap, isNotNull);
      expect(snap!.latitude, closeTo(14.5547, 0.0001));
      expect(snap.longitude, closeTo(121.0244, 0.0001));
    });

    test('parses doc nested under data envelope', () {
      final inner = makeMap([121.0244, 14.5547]);
      final snap = GeoPositionSnapshot.fromApiMap({'data': inner});
      expect(snap, isNotNull);
    });

    test('returns null when loc is missing', () {
      final map = {'updatedAt': validUpdatedAt};
      expect(GeoPositionSnapshot.fromApiMap(map), isNull);
    });

    test('returns null when coordinates array is empty', () {
      final map = {
        'loc': {'type': 'Point', 'coordinates': []},
        'updatedAt': validUpdatedAt,
      };
      expect(GeoPositionSnapshot.fromApiMap(map), isNull);
    });

    test('returns null when coordinates has only one element', () {
      final map = makeMap([121.0244]);
      expect(GeoPositionSnapshot.fromApiMap(map), isNull);
    });

    test('returns null for null-island (0, 0)', () {
      final map = makeMap([0.0, 0.0]);
      expect(GeoPositionSnapshot.fromApiMap(map), isNull);
    });

    test('returns null for out-of-range latitude', () {
      final map = makeMap([121.0244, 95.0]);
      expect(GeoPositionSnapshot.fromApiMap(map), isNull);
    });

    test('returns null for out-of-range longitude', () {
      final map = makeMap([185.0, 14.5547]);
      expect(GeoPositionSnapshot.fromApiMap(map), isNull);
    });

    test('returns null when updatedAt is missing', () {
      final map = {
        'loc': {
          'type': 'Point',
          'coordinates': [121.0244, 14.5547]
        },
      };
      expect(GeoPositionSnapshot.fromApiMap(map), isNull);
    });

    test('returns null when updatedAt is not a valid ISO-8601 string', () {
      final map = makeMap([121.0244, 14.5547]);
      (map)['updatedAt'] = 'not-a-date';
      expect(GeoPositionSnapshot.fromApiMap(map), isNull);
    });
  });

  group('GeoPositionSnapshot.isStaleAt', () {
    final base = DateTime(2026, 7, 28, 10, 0, 0);

    GeoPositionSnapshot makeSnap(DateTime updatedAt) => GeoPositionSnapshot(
          latitude: 14.5547,
          longitude: 121.0244,
          updatedAt: updatedAt,
        );

    test('returns false when location is 1 minute old (threshold = 3 min)', () {
      final snap = makeSnap(base.subtract(const Duration(minutes: 1)));
      expect(snap.isStaleAt(base), isFalse);
    });

    test('returns false when location is exactly 3 minutes old', () {
      final snap = makeSnap(base.subtract(const Duration(minutes: 3)));
      expect(snap.isStaleAt(base), isFalse);
    });

    test('returns true when location is 4 minutes old', () {
      final snap = makeSnap(base.subtract(const Duration(minutes: 4)));
      expect(snap.isStaleAt(base), isTrue);
    });

    test('respects custom threshold', () {
      final snap = makeSnap(base.subtract(const Duration(minutes: 2)));
      expect(snap.isStaleAt(base, threshold: const Duration(minutes: 1)), isTrue);
      expect(snap.isStaleAt(base, threshold: const Duration(minutes: 3)), isFalse);
    });
  });

  group('GeoPositionSnapshot.latLng', () {
    test('returns correct LatLng', () {
      final snap = GeoPositionSnapshot(
        latitude: 14.5547,
        longitude: 121.0244,
        updatedAt: DateTime.now(),
      );
      expect(snap.latLng.latitude, closeTo(14.5547, 0.0001));
      expect(snap.latLng.longitude, closeTo(121.0244, 0.0001));
    });
  });
}
