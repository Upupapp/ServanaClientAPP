import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';
import 'package:client/modules/tracking/domain/geo_position_snapshot.dart';
import 'package:client/modules/tracking/domain/tracking_eta.dart';
import 'package:client/modules/tracking/domain/tracking_freshness.dart';
import 'package:flutter_test/flutter_test.dart';

BookingTrackingState makeState({
  String bookingId = '42',
  BookingStatus status = BookingStatus.enRoute,
  GeoPositionSnapshot? providerLocation,
  TrackingEta? eta,
}) =>
    BookingTrackingState(
      bookingId: bookingId,
      bookingStatus: status,
      serviceAddress: '123 Test St, Manila',
      serviceLatitude: 14.5995,
      serviceLongitude: 120.9842,
      providerLocation: providerLocation,
      eta: eta,
    );

void main() {
  group('BookingTrackingState.isTrackable', () {
    test('returns true for enRoute', () {
      expect(makeState(status: BookingStatus.enRoute).isTrackable, isTrue);
    });

    test('returns true for arrived', () {
      expect(makeState(status: BookingStatus.arrived).isTrackable, isTrue);
    });

    test('returns true for inProgress', () {
      expect(makeState(status: BookingStatus.inProgress).isTrackable, isTrue);
    });

    test('returns true for awaitingCompletion', () {
      expect(
        makeState(status: BookingStatus.awaitingCompletion).isTrackable,
        isTrue,
      );
    });

    test('returns false for confirmed', () {
      expect(makeState(status: BookingStatus.confirmed).isTrackable, isFalse);
    });

    test('returns false for completed', () {
      expect(makeState(status: BookingStatus.completed).isTrackable, isFalse);
    });

    test('returns false for cancelled', () {
      expect(makeState(status: BookingStatus.cancelled).isTrackable, isFalse);
    });
  });

  group('BookingTrackingState.isTerminal', () {
    test('returns true for completed', () {
      expect(makeState(status: BookingStatus.completed).isTerminal, isTrue);
    });

    test('returns true for cancelled', () {
      expect(makeState(status: BookingStatus.cancelled).isTerminal, isTrue);
    });

    test('returns false for enRoute', () {
      expect(makeState(status: BookingStatus.enRoute).isTerminal, isFalse);
    });

    test('returns false for inProgress', () {
      expect(makeState(status: BookingStatus.inProgress).isTerminal, isFalse);
    });
  });

  group('BookingTrackingState.freshness', () {
    test('returns unknown when providerLocation is null', () {
      expect(makeState().freshness, TrackingFreshness.unknown);
    });

    test('returns live when location is recent', () {
      final loc = GeoPositionSnapshot(
        latitude: 14.5547,
        longitude: 121.0244,
        updatedAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(
          makeState(providerLocation: loc).freshness, TrackingFreshness.live);
    });

    test('returns stale when location is older than 3 minutes', () {
      final loc = GeoPositionSnapshot(
        latitude: 14.5547,
        longitude: 121.0244,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(
          makeState(providerLocation: loc).freshness, TrackingFreshness.stale);
    });
  });

  group('BookingTrackingState.copyWith', () {
    test('copies with new status, preserving other fields', () {
      final original = makeState(status: BookingStatus.enRoute);
      final updated = original.copyWith(bookingStatus: BookingStatus.arrived);
      expect(updated.bookingStatus, BookingStatus.arrived);
      expect(updated.bookingId, original.bookingId);
      expect(updated.serviceAddress, original.serviceAddress);
    });

    test('copies with new providerLocation', () {
      final original = makeState();
      final loc = GeoPositionSnapshot(
        latitude: 14.5547,
        longitude: 121.0244,
        updatedAt: DateTime.now(),
      );
      final updated = original.copyWith(providerLocation: loc);
      expect(updated.providerLocation, loc);
      expect(updated.bookingStatus, original.bookingStatus);
    });

    test('copies with new providerName', () {
      final original = makeState();
      final updated = original.copyWith(providerName: 'Juan dela Cruz');
      expect(updated.providerName, 'Juan dela Cruz');
    });

    test('null args in copyWith preserve existing values', () {
      final loc = GeoPositionSnapshot(
        latitude: 14.5547,
        longitude: 121.0244,
        updatedAt: DateTime.now(),
      );
      final original = makeState(providerLocation: loc);
      final updated = original.copyWith();
      expect(updated.providerLocation, loc);
    });
  });
}
