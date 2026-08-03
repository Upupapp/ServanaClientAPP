import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/modules/tracking/data/tracking_data_source.dart';
import 'package:client/modules/tracking/data/tracking_repository.dart';
import 'package:client/modules/tracking/domain/geo_position_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake data sources ────────────────────────────────────────────────────────

class _FakeDataSource extends Fake implements TrackingDataSource {
  Map<String, dynamic> bookingResponse = {};
  GeoPositionSnapshot? locationResponse;
  Object? locationError;
  int locationCallCount = 0;
  int bookingCallCount = 0;

  @override
  Future<Map<String, dynamic>> getBookingDetail(int bookingId) async {
    bookingCallCount++;
    return bookingResponse;
  }

  @override
  Future<GeoPositionSnapshot?> getProviderLocation(String workerUid) async {
    locationCallCount++;
    if (locationError != null) throw locationError!;
    return locationResponse;
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

GeoPositionSnapshot makeLocation() => GeoPositionSnapshot(
      latitude: 14.5547,
      longitude: 121.0244,
      updatedAt: DateTime.now(),
    );

Map<String, dynamic> makeBookingBody({
  String status = 'ENROUTE',
  String? workerUid,
  String? workerName,
  double? latitude,
  double? longitude,
}) =>
    {
      'status': status,
      if (workerUid != null) 'workerUid': workerUid,
      if (workerName != null) 'workerName': workerName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('TrackingRepository.fetchSnapshot — argument validation', () {
    test('throws ArgumentError when bookingId is not numeric', () async {
      final ds = _FakeDataSource();
      final repo = TrackingRepository(ds);
      expect(
        () => repo.fetchSnapshot(bookingId: 'not-a-number'),
        throwsArgumentError,
      );
    });
  });

  group('TrackingRepository.fetchSnapshot — known UID (parallel path)', () {
    test('fires location call in parallel when knownWorkerUid is provided',
        () async {
      final ds = _FakeDataSource()
        ..bookingResponse = makeBookingBody(workerUid: 'uid-001')
        ..locationResponse = makeLocation();

      final repo = TrackingRepository(ds);
      await repo.fetchSnapshot(bookingId: '42', knownWorkerUid: 'uid-001');

      expect(ds.bookingCallCount, 1);
      expect(ds.locationCallCount, 1);
    });

    test('returns state with providerLocation when location call succeeds',
        () async {
      final loc = makeLocation();
      final ds = _FakeDataSource()
        ..bookingResponse = makeBookingBody(workerUid: 'uid-001')
        ..locationResponse = loc;

      final repo = TrackingRepository(ds);
      final state =
          await repo.fetchSnapshot(bookingId: '42', knownWorkerUid: 'uid-001');

      expect(state.providerLocation, loc);
    });

    test('location failure is isolated — booking status still returned',
        () async {
      final ds = _FakeDataSource()
        ..bookingResponse =
            makeBookingBody(status: 'INPROGRESS', workerUid: 'uid-001')
        ..locationError = Exception('network error');

      final repo = TrackingRepository(ds);
      final state =
          await repo.fetchSnapshot(bookingId: '42', knownWorkerUid: 'uid-001');

      expect(state.providerLocation, isNull);
      expect(state.bookingStatus, BookingStatus.inProgress);
    });

    test('does not fire location call when knownWorkerUid is empty', () async {
      final ds = _FakeDataSource()..bookingResponse = makeBookingBody();

      final repo = TrackingRepository(ds);
      await repo.fetchSnapshot(bookingId: '42', knownWorkerUid: '');

      expect(ds.locationCallCount, 0);
    });
  });

  group('TrackingRepository.fetchSnapshot — late UID discovery', () {
    test('fires second location call when UID discovered in booking response',
        () async {
      final ds = _FakeDataSource()
        ..bookingResponse = makeBookingBody(workerUid: 'uid-from-booking')
        ..locationResponse = makeLocation();

      final repo = TrackingRepository(ds);
      await repo.fetchSnapshot(
          bookingId: '42', knownWorkerUid: null); // no prior UID

      expect(ds.bookingCallCount, 1);
      expect(ds.locationCallCount, 1);
    });

    test('late UID location failure is isolated', () async {
      final ds = _FakeDataSource()
        ..bookingResponse =
            makeBookingBody(status: 'ENROUTE', workerUid: 'uid-from-booking')
        ..locationError = Exception('timeout');

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '42');

      expect(state.providerLocation, isNull);
      expect(state.bookingStatus, BookingStatus.enRoute);
    });

    test('does not fire location call when booking response has no UID',
        () async {
      final ds = _FakeDataSource()..bookingResponse = makeBookingBody();

      final repo = TrackingRepository(ds);
      await repo.fetchSnapshot(bookingId: '42');

      expect(ds.locationCallCount, 0);
    });
  });

  group('TrackingRepository.fetchSnapshot — field alias resolution', () {
    test('reads worker name from camelCase workerName', () async {
      final ds = _FakeDataSource()
        ..bookingResponse = {
          'status': 'ENROUTE',
          'workerUid': 'uid-001',
          'workerName': 'Maria Santos',
        };

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '42');

      expect(state.providerName, 'Maria Santos');
    });

    test('reads worker name from snake_case worker_name', () async {
      final ds = _FakeDataSource()
        ..bookingResponse = {
          'status': 'ENROUTE',
          'workerUid': 'uid-001',
          'worker_name': 'Maria Santos',
        };

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '42');

      expect(state.providerName, 'Maria Santos');
    });

    test('reads worker UID from snake_case worker_uid', () async {
      final ds = _FakeDataSource()
        ..bookingResponse = {
          'status': 'ENROUTE',
          'worker_uid': 'uid-snake',
        }
        ..locationResponse = makeLocation();

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '42');

      expect(state.providerUid, 'uid-snake');
    });

    test('seed name used when booking response omits worker name', () async {
      final ds = _FakeDataSource()
        ..bookingResponse = {'status': 'ENROUTE', 'workerUid': 'uid-001'};

      final repo = TrackingRepository(ds);
      final state =
          await repo.fetchSnapshot(bookingId: '42', seedName: 'Seeded Name');

      expect(state.providerName, 'Seeded Name');
    });

    test('service address falls back to seedAddress', () async {
      final ds = _FakeDataSource()..bookingResponse = {'status': 'ENROUTE'};

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(
          bookingId: '42', seedAddress: '123 Seed Street');

      expect(state.serviceAddress, '123 Seed Street');
    });

    test('service coordinates fall back to Metro Manila default', () async {
      final ds = _FakeDataSource()..bookingResponse = {'status': 'ENROUTE'};

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '42');

      expect(state.serviceLatitude, closeTo(14.5995, 0.001));
      expect(state.serviceLongitude, closeTo(120.9842, 0.001));
    });

    test('reads service coordinates from booking body when present', () async {
      final ds = _FakeDataSource()
        ..bookingResponse = {
          'status': 'ENROUTE',
          'latitude': 14.6760,
          'longitude': 121.0437,
        };

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '42');

      expect(state.serviceLatitude, closeTo(14.6760, 0.001));
      expect(state.serviceLongitude, closeTo(121.0437, 0.001));
    });
  });

  group('TrackingRepository.fetchSnapshot — envelope handling', () {
    test('unwraps booking key from response envelope', () async {
      final ds = _FakeDataSource()
        ..bookingResponse = {
          'booking': {
            'status': 'ARRIVED',
            'workerUid': 'uid-001',
          }
        };

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '42');

      expect(state.bookingStatus, BookingStatus.arrived);
    });

    test('unwraps data key from response envelope', () async {
      final ds = _FakeDataSource()
        ..bookingResponse = {
          'data': {
            'status': 'INPROGRESS',
          }
        };

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '42');

      expect(state.bookingStatus, BookingStatus.inProgress);
    });

    test('uses raw response body when no envelope key is present', () async {
      final ds = _FakeDataSource()..bookingResponse = {'status': 'COMPLETED'};

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '42');

      expect(state.bookingStatus, BookingStatus.completed);
    });
  });

  group('TrackingRepository.fetchSnapshot — bookingId propagation', () {
    test('returned state has the correct bookingId', () async {
      final ds = _FakeDataSource()..bookingResponse = {'status': 'ENROUTE'};

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '99');

      expect(state.bookingId, '99');
    });
  });

  group('TrackingRepository.fetchSnapshot — phone alias and fallback', () {
    test('reads worker phone from snake_case worker_phone', () async {
      final ds = _FakeDataSource()
        ..bookingResponse = {
          'status': 'ENROUTE',
          'workerUid': 'uid-001',
          'worker_phone': '+639171234567',
        };

      final repo = TrackingRepository(ds);
      final state = await repo.fetchSnapshot(bookingId: '42');

      expect(state.providerPhone, '+639171234567');
    });

    test('seed phone used when booking response omits worker phone', () async {
      final ds = _FakeDataSource()
        ..bookingResponse = {'status': 'ENROUTE', 'workerUid': 'uid-001'};

      final repo = TrackingRepository(ds);
      final state =
          await repo.fetchSnapshot(bookingId: '42', seedPhone: '+639179999999');

      expect(state.providerPhone, '+639179999999');
    });

    test(
        'knownWorkerUid surfaces as providerUid in output state when body omits uid',
        () async {
      final ds = _FakeDataSource()
        ..bookingResponse = {'status': 'ENROUTE'} // no uid in body
        ..locationResponse = makeLocation();

      final repo = TrackingRepository(ds);
      final state =
          await repo.fetchSnapshot(bookingId: '42', knownWorkerUid: 'seed-uid');

      expect(state.providerUid, 'seed-uid');
    });
  });
}
