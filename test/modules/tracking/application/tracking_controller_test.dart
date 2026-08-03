import 'dart:async';

import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/modules/tracking/application/tracking_controller.dart';
import 'package:client/modules/tracking/data/tracking_repository.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake repositories ────────────────────────────────────────────────────────

class _FakeRepo extends Fake implements TrackingRepository {
  int fetchCallCount = 0;
  BookingTrackingState? response;
  Object? error;

  @override
  Future<BookingTrackingState> fetchSnapshot({
    required String bookingId,
    String? knownWorkerUid,
    String? seedName,
    String? seedPhone,
    double? seedLatitude,
    double? seedLongitude,
    String? seedAddress,
  }) async {
    fetchCallCount++;
    if (error != null) throw error!;
    return response!;
  }
}

/// Repository whose fetch completes only when the exposed completer is resolved.
class _SlowRepo extends Fake implements TrackingRepository {
  final Completer<BookingTrackingState> completer = Completer();

  @override
  Future<BookingTrackingState> fetchSnapshot({
    required String bookingId,
    String? knownWorkerUid,
    String? seedName,
    String? seedPhone,
    double? seedLatitude,
    double? seedLongitude,
    String? seedAddress,
  }) =>
      completer.future;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

BookingTrackingState makeSnapshot({
  String bookingId = '42',
  BookingStatus status = BookingStatus.enRoute,
}) =>
    BookingTrackingState(
      bookingId: bookingId,
      bookingStatus: status,
      serviceAddress: '123 Test St',
      serviceLatitude: 14.5995,
      serviceLongitude: 120.9842,
    );

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrackingController.startTracking', () {
    test('calls fetchSnapshot and sets trackingState', () async {
      final repo = _FakeRepo()..response = makeSnapshot();
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');

      expect(ctrl.trackingState, isNotNull);
      expect(ctrl.trackingState!.bookingId, '42');
      expect(repo.fetchCallCount, 1);
      ctrl.dispose();
    });

    test('isLoading is false after successful fetch', () async {
      final repo = _FakeRepo()..response = makeSnapshot();
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');

      expect(ctrl.isLoading, isFalse);
      ctrl.dispose();
    });

    test('isPolling is true after successful non-terminal fetch', () async {
      final repo = _FakeRepo()..response = makeSnapshot();
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');

      expect(ctrl.isPolling, isTrue);
      ctrl.dispose();
    });

    test('duplicate startTracking for same bookingId while polling is ignored',
        () async {
      final repo = _FakeRepo()..response = makeSnapshot();
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');
      final countAfterFirst = repo.fetchCallCount;

      await ctrl.startTracking(bookingId: '42'); // no-op

      expect(repo.fetchCallCount, countAfterFirst);
      ctrl.dispose();
    });

    test('sets error and leaves trackingState null when repository throws',
        () async {
      final repo = _FakeRepo()..error = Exception('network error');
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');

      expect(ctrl.trackingState, isNull);
      expect(ctrl.error, isNotNull);
      expect(ctrl.isLoading, isFalse);
      ctrl.dispose();
    });

    test('error is cleared on successful retry', () async {
      final repo = _FakeRepo()..error = Exception('network error');
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');
      expect(ctrl.error, isNotNull);

      // Fix the repo and manually refresh.
      repo.error = null;
      repo.response = makeSnapshot();
      await ctrl.refresh();

      expect(ctrl.error, isNull);
      expect(ctrl.trackingState, isNotNull);
      ctrl.dispose();
    });
  });

  group('TrackingController.stopTracking', () {
    test('sets isPolling to false', () async {
      final repo = _FakeRepo()..response = makeSnapshot();
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');
      ctrl.stopTracking();

      expect(ctrl.isPolling, isFalse);
      ctrl.dispose();
    });

    test('generation counter prevents stale callback from writing state',
        () async {
      final slowRepo = _SlowRepo();
      final ctrl = TrackingController(repository: slowRepo);

      // Kick off a fetch (it's now in-flight, waiting for slowRepo.completer).
      ctrl.startTracking(bookingId: '42');

      // Immediately stop (bumps _generation).
      ctrl.stopTracking();

      // Complete the in-flight future — the callback should be discarded.
      slowRepo.completer
          .complete(makeSnapshot(status: BookingStatus.completed));
      await Future<void>.delayed(Duration.zero); // pump microtask queue

      expect(ctrl.trackingState, isNull);
      ctrl.dispose();
    });
  });

  group('TrackingController.refresh', () {
    test('calls fetchSnapshot again', () async {
      final repo = _FakeRepo()..response = makeSnapshot();
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');
      final countAfterStart = repo.fetchCallCount;

      await ctrl.refresh();

      expect(repo.fetchCallCount, greaterThan(countAfterStart));
      ctrl.dispose();
    });

    test('refresh is no-op when no active booking', () async {
      final repo = _FakeRepo()..response = makeSnapshot();
      final ctrl = TrackingController(repository: repo);

      await ctrl.refresh(); // no active booking

      expect(repo.fetchCallCount, 0);
    });
  });

  group('TrackingController terminal state', () {
    test('stops polling when booking reaches completed status', () async {
      final repo = _FakeRepo()
        ..response = makeSnapshot(status: BookingStatus.completed);
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');

      expect(ctrl.isPolling, isFalse);
      ctrl.dispose();
    });

    test('stops polling when booking is cancelled', () async {
      final repo = _FakeRepo()
        ..response = makeSnapshot(status: BookingStatus.cancelled);
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');

      expect(ctrl.isPolling, isFalse);
      ctrl.dispose();
    });
  });

  group('TrackingController.dispose', () {
    test('dispose prevents further state writes', () async {
      final repo = _FakeRepo()..response = makeSnapshot();
      final ctrl = TrackingController(repository: repo);

      await ctrl.startTracking(bookingId: '42');
      final stateBeforeDispose = ctrl.trackingState;
      ctrl.dispose();

      // refresh after dispose — should be ignored
      repo.response = makeSnapshot(status: BookingStatus.completed);
      await ctrl.refresh();

      expect(
          ctrl.trackingState?.bookingStatus, stateBeforeDispose?.bookingStatus);
    });

    test('dispose is safe to call multiple times', () {
      final ctrl = TrackingController(
          repository: _FakeRepo()..response = makeSnapshot());
      expect(() {
        ctrl.dispose();
        ctrl.dispose();
      }, returnsNormally);
    });
  });
}
