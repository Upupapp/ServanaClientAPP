import 'dart:async';

import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/events/tracking_events.dart';
import 'package:client/modules/tracking/data/tracking_repository.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';

part 'tracking_controller.g.dart';

class TrackingController extends _TrackingController with _$TrackingController {
  TrackingController({required super.repository});
}

abstract class _TrackingController with Store {
  _TrackingController({required this.repository});

  final TrackingRepository repository;

  // ── Lifecycle guard ────────────────────────────────────────────────────────

  bool _disposed = false;

  /// Generation counter — incremented on [stopTracking] so in-flight callbacks
  /// from the previous session do not write to the new one.
  int _generation = 0;

  String? _activeBookingId;
  String? _workerUid;
  String? _workerName;
  String? _workerPhone;
  double? _seedLat;
  double? _seedLng;
  String? _seedAddress;

  Timer? _pollTimer;

  /// Location + status are refreshed together every 10 s (TRACK-GAP-001).
  static const _pollInterval = Duration(seconds: 10);

  // ── Observables ────────────────────────────────────────────────────────────

  @observable
  BookingTrackingState? trackingState;

  @observable
  bool isLoading = false;

  @observable
  bool isPolling = false;

  @observable
  String? error;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Begin tracking [bookingId].
  ///
  /// Safe to call multiple times for the same booking — duplicate calls are
  /// ignored. Call [stopTracking] first before switching to a different booking.
  @action
  Future<void> startTracking({
    required String bookingId,
    String? workerUid,
    String? workerName,
    String? workerPhone,
    double? serviceLatitude,
    double? serviceLongitude,
    String? serviceAddress,
  }) async {
    if (_activeBookingId == bookingId && isPolling) return;
    _activeBookingId = bookingId;
    _workerUid = workerUid;
    _workerName = workerName;
    _workerPhone = workerPhone;
    _seedLat = serviceLatitude;
    _seedLng = serviceLongitude;
    _seedAddress = serviceAddress;
    _generation++;
    final gen = _generation;

    _stopTimer();
    await _fetchSnapshot(gen);
    if (_disposed || _generation != gen) return;
    if (trackingState?.isTerminal != true) _startTimer();
  }

  @action
  Future<void> refresh() async {
    if (_activeBookingId == null) return;
    final gen = _generation;
    await _fetchSnapshot(gen);
  }

  @action
  void stopTracking() {
    _generation++;
    _stopTimer();
    isPolling = false;
    _activeBookingId = null;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _fetchSnapshot(int gen) async {
    final id = _activeBookingId;
    if (id == null || _disposed) return;
    if (trackingState == null) isLoading = true;
    try {
      final snapshot = await repository.fetchSnapshot(
        bookingId: id,
        knownWorkerUid: trackingState?.providerUid ?? _workerUid,
        seedName: trackingState?.providerName ?? _workerName,
        seedPhone: trackingState?.providerPhone ?? _workerPhone,
        seedLatitude: _seedLat,
        seedLongitude: _seedLng,
        seedAddress: _seedAddress,
      );
      if (_disposed || _generation != gen) return;
      trackingState = snapshot;
      error = null;
      if (snapshot.isTerminal) {
        _stopTimer();
        isPolling = false;
      }
      final loc = snapshot.providerLocation;
      final freshness = loc == null
          ? 'unknown'
          : loc.isStaleAt(DateTime.now())
              ? 'stale'
              : 'fresh';
      _track(TrackingSnapshotLoadedEvent(
        freshnessCategory: freshness,
        trackingStatusCategory: snapshot.bookingStatus.name,
      ));
    } catch (e) {
      debugPrint('[TrackingController] fetch error: $e');
      if (_disposed || _generation != gen) return;
      if (trackingState == null) {
        error = 'Could not load tracking data. Pull down to retry.';
      }
    } finally {
      if (!_disposed && _generation == gen) isLoading = false;
    }
  }

  void _startTimer() {
    if (_disposed) return;
    isPolling = true;
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!_disposed) _fetchSnapshot(_generation);
    });
  }

  void _stopTimer() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    _stopTimer();
  }
}
