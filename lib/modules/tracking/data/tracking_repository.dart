import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/modules/tracking/data/tracking_data_source.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';
import 'package:client/modules/tracking/domain/tracking_eta.dart';
import 'package:flutter/foundation.dart';

/// Coordinates two API calls into a single [BookingTrackingState] snapshot.
///
/// TRACK-GAP-002: The backend has no combined tracking-snapshot endpoint, so
/// two requests are made in parallel. A location fetch failure is isolated —
/// it surfaces as a null [providerLocation] rather than throwing, so the
/// booking status and ETA are still displayed even when location is unavailable.
class TrackingRepository {
  const TrackingRepository(this._dataSource);

  final TrackingDataSource _dataSource;

  /// Fetch a fresh [BookingTrackingState] for [bookingId].
  ///
  /// [knownWorkerUid] is passed from the prior state or from [TrackingArgs]
  /// so the location call can be fired in parallel with the booking fetch
  /// without waiting for the booking response to reveal the uid.
  ///
  /// [seedName] / [seedPhone] are used on the first fetch when the booking
  /// response does not include worker profile fields.
  Future<BookingTrackingState> fetchSnapshot({
    required String bookingId,
    String? knownWorkerUid,
    String? seedName,
    String? seedPhone,
    double? seedLatitude,
    double? seedLongitude,
    String? seedAddress,
  }) async {
    final bookingIdInt = int.tryParse(bookingId);
    if (bookingIdInt == null) {
      throw ArgumentError(
          'bookingId must be a numeric string, got: $bookingId');
    }

    // Fire both calls in parallel. Location failure is isolated.
    //
    // The location fetch is keyed on the BOOKING now, not on a worker uid, so
    // it no longer has to wait to learn who is assigned. That removed a real
    // defect as well as a branch: when the uid arrived only with the booking
    // response, the first fetch was skipped and a second one issued afterwards,
    // so the very first tracking frame had no position on it — two round trips
    // to render what one now renders.
    final locationFuture =
        _dataSource.getProviderLocation(bookingIdInt).catchError((e) {
      debugPrint('[TrackingRepo] location fetch failed: $e');
      return null;
    });

    final bookingRaw = await _dataSource.getBookingDetail(bookingIdInt);
    final b = bookingRaw['booking'] as Map<String, dynamic>? ??
        bookingRaw['data'] as Map<String, dynamic>? ??
        bookingRaw;

    final status = BookingStatusMapper.fromString(
      (b['status'] ?? '').toString().toUpperCase(),
    );

    // Still resolved for display (name/phone lookup and the caller's seed), but
    // no longer needed to ask where the provider is.
    final workerUid = b['workerUid']?.toString() ??
        b['worker_uid']?.toString() ??
        b['providerUid']?.toString() ??
        knownWorkerUid;

    final locationResult = await locationFuture;

    final eta = TrackingEta.fromBookingMap(b);

    final serviceLatitude =
        (b['latitude'] as num?)?.toDouble() ?? seedLatitude ?? 14.5995;
    final serviceLongitude =
        (b['longitude'] as num?)?.toDouble() ?? seedLongitude ?? 120.9842;
    final serviceAddress = b['addressLine']?.toString() ??
        b['address']?.toString() ??
        seedAddress ??
        '';

    // Worker name/phone: booking response may include them; fall back to seed.
    final providerName =
        b['workerName']?.toString() ?? b['worker_name']?.toString() ?? seedName;
    final providerPhone = b['workerPhone']?.toString() ??
        b['worker_phone']?.toString() ??
        seedPhone;

    return BookingTrackingState(
      bookingId: bookingId,
      bookingStatus: status,
      providerLocation: locationResult,
      eta: eta,
      providerUid: workerUid,
      providerName: providerName,
      providerPhone: providerPhone,
      serviceAddress: serviceAddress,
      serviceLatitude: serviceLatitude,
      serviceLongitude: serviceLongitude,
    );
  }
}
