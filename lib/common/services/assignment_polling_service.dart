import 'dart:async';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/injectors/main_injector.dart';

/// Result of a single assignment poll.
class AssignmentPollResult {
  const AssignmentPollResult({
    required this.status,
    this.workerUid,
    this.workerName,
  });

  final BookingStatus status;
  final String? workerUid;
  final String? workerName;

  bool get isAssigned =>
      workerUid != null &&
      workerUid!.isNotEmpty &&
      (status == BookingStatus.assigned || status == BookingStatus.confirmed);
}

/// Lifecycle-aware assignment polling service shared by all confirmation screens.
///
/// Eliminates the ~80-line polling duplicate in [AirconConfirmationScreen] and
/// [BwConfirmationScreen]. Callers:
///   1. Call [start] with the booking ID and an [onUpdate] callback.
///   2. Call [stop] in [dispose] — safe to call even if never started.
///
/// Hard limits: max 12 polls × 5 s = 60 s. Stops immediately on:
///   - Assignment confirmed ([AssignmentPollResult.isAssigned])
///   - Explicit [stop] call
///   - Disposal
class AssignmentPollingService {
  static const _interval = Duration(seconds: 5);
  static const _maxAttempts = 12;

  Timer? _timer;
  int _attempts = 0;
  bool _disposed = false;

  bool get isPolling => _timer?.isActive == true;

  /// Start polling for [bookingId].
  ///
  /// [onUpdate] is invoked on every successful poll (including the immediate
  /// kick). [onTimeout] is called when [_maxAttempts] are exhausted without
  /// assignment.
  void start({
    required int bookingId,
    required void Function(AssignmentPollResult result) onUpdate,
    void Function()? onTimeout,
  }) {
    if (_disposed || isPolling) return;
    _attempts = 0;
    // Immediate kick so the user doesn't wait for the first interval.
    _poll(bookingId: bookingId, onUpdate: onUpdate, onTimeout: onTimeout);
    _timer = Timer.periodic(_interval, (_) {
      _attempts++;
      if (_attempts >= _maxAttempts) {
        stop();
        onTimeout?.call();
        return;
      }
      _poll(bookingId: bookingId, onUpdate: onUpdate, onTimeout: onTimeout);
    });
  }

  /// Stop polling. Safe to call multiple times.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Call from the owning widget's [dispose]. Prevents callbacks firing on
  /// a dead widget.
  void dispose() {
    _disposed = true;
    stop();
  }

  Future<void> _poll({
    required int bookingId,
    required void Function(AssignmentPollResult) onUpdate,
    void Function()? onTimeout,
  }) async {
    if (_disposed) return;
    try {
      final api = dpLocator<ServanaApiClient>();
      final res = await api.getBooking(bookingId);
      if (_disposed) return;

      final booking = res['booking'] as Map<String, dynamic>? ??
          res['data'] as Map<String, dynamic>? ??
          res;

      final status =
          BookingStatusMapper.fromString(booking['status']?.toString());
      final workerUid = booking['workerUid']?.toString();

      String? workerName;
      if (workerUid != null && workerUid.isNotEmpty) {
        workerName = await _fetchWorkerName(workerUid);
      }

      if (_disposed) return;
      final result = AssignmentPollResult(
        status: status,
        workerUid: workerUid,
        workerName: workerName,
      );
      onUpdate(result);

      // Stop once assigned — no need to keep polling.
      if (result.isAssigned) stop();
    } catch (_) {
      // Silent: keep polling until max attempts. Network hiccups are common.
    }
  }

  Future<String?> _fetchWorkerName(String uid) async {
    try {
      final api = dpLocator<ServanaApiClient>();
      final res = await api.getWorkerByUid(uid);
      final w = res['worker'] as Map<String, dynamic>? ??
          res['data'] as Map<String, dynamic>? ??
          res;
      final first = w['firstName']?.toString() ?? '';
      final last = w['lastName']?.toString() ?? '';
      final composed = '$first $last'.trim();
      if (composed.isNotEmpty) return composed;
      return w['name']?.toString();
    } catch (_) {
      return null;
    }
  }
}
