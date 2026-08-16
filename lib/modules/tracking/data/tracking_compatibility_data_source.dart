/// Tracking as the app does it today: two legacy calls, stitched.
///
/// This is the previous `TrackingRepository.fetchSnapshot` body, moved behind
/// [TrackingSnapshotSource] so the repository has one call path whichever
/// transport answers. Nothing about the requests changed.
///
/// ## The one thing it cannot do
///
/// Say WHY a position is missing. `GET /api/booking/:id/provider-location`
/// distinguishes "not assigned" from "assigned but silent" in its body, and
/// [GeoPositionSnapshot.fromApiMap] returns null for both; the state rule and
/// the movement window do not exist on this route at all. So the verdict this
/// source attaches is [TrackingVisibility.inferred] — `isBackendDerived: false`
/// — and a screen can decline to state a reason it does not have.
library;

import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/modules/tracking/data/tracking_data_source.dart';
import 'package:client/modules/tracking/data/tracking_snapshot_source.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';
import 'package:client/modules/tracking/domain/tracking_eta.dart';
import 'package:client/modules/tracking/domain/tracking_visibility.dart';
import 'package:flutter/foundation.dart';

class TrackingCompatibilityDataSource implements TrackingSnapshotSource {
  const TrackingCompatibilityDataSource(this._dataSource);

  final TrackingDataSource _dataSource;

  @override
  Future<BookingTrackingState> snapshot({
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
    // The location fetch is keyed on the BOOKING, not on a worker uid, so it
    // does not have to wait to learn who is assigned. That removed a real
    // defect as well as a branch: when the uid arrived only with the booking
    // response, the first fetch was skipped and a second one issued afterwards,
    // so the very first tracking frame had no position on it.
    final locationFuture =
        _dataSource.getProviderLocation(bookingIdInt).catchError((e) {
      debugPrint('[TrackingCompat] location fetch failed: $e');
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
      visibility:
          TrackingVisibility.inferred(hasPosition: locationResult != null),
    );
  }
}
