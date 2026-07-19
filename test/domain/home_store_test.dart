import 'package:client/common/data/backend/backend.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/services/location_service.dart';
import 'package:client/modules/homepage/data/repositories/home_repo.dart.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBackend extends Mock implements Backend {}

HomeStore _buildStore() {
  final repo = HomeRepository(
    backend: MockBackend(),
    locationService: LocationService(),
  );
  return HomeStore(repo: repo, locationSerive: LocationService());
}

JobOrder _job(String id) => JobOrder(
      jobOrderID: id,
      jobOrderNumber: 'BK-$id',
      scheduleDate: DateTime(2026),
      createdDate: DateTime(2026),
      address: '123 Test St',
      numberOfPersonnel: 1,
      distanceFromOffice: 0,
      merchantServiceName: 'Aircon Clean',
      latitude: 0,
      longitude: 0,
      downPayment: 0,
      totalAmount: 500,
      paymentType: 1,
      jobOrderStatusToString: 'For Review',
      jobOrderStatus: JobOrderStatus.forReview,
    );

void main() {
  group('HomeStore.resetPrivateData', () {
    test('clears bookings, session, location, merchants, searchResults', () {
      final store = _buildStore();
      store.addBooking(_job('j1'));
      expect(store.bookings, hasLength(1));

      store.resetPrivateData();

      expect(store.bookings, isEmpty);
      expect(store.session, isNull);
      expect(store.currentLocation, isNull);
      expect(store.merchants, isEmpty);
      expect(store.searchResults, isEmpty);
    });

    test('multiple calls are safe', () {
      final store = _buildStore();
      store.addBooking(_job('j1'));
      store.resetPrivateData();
      expect(() => store.resetPrivateData(), returnsNormally);
      expect(store.bookings, isEmpty);
    });
  });

  group('HomeStore.addBooking', () {
    test('inserts a booking at index 0', () {
      final store = _buildStore();
      store.addBooking(_job('j1'));

      expect(store.bookings, hasLength(1));
      expect(store.bookings.first.jobOrderID, equals('j1'));
    });

    test('prepends newer bookings ahead of older ones', () {
      final store = _buildStore();
      store.addBooking(_job('j1'));
      store.addBooking(_job('j2'));

      expect(store.bookings.first.jobOrderID, equals('j2'));
    });

    test('upserts by jobOrderID — no duplicates', () {
      final store = _buildStore();
      store.addBooking(_job('j1'));
      store.addBooking(_job('j1'));

      expect(store.bookings, hasLength(1));
    });

    test('upsert moves existing booking to front', () {
      final store = _buildStore();
      store.addBooking(_job('j1'));
      store.addBooking(_job('j2'));
      store.addBooking(_job('j1'));

      expect(store.bookings.first.jobOrderID, equals('j1'));
      expect(store.bookings, hasLength(2));
    });
  });
}
