/// Route extras passed from [BookingDetailScreen] to [LiveTrackingScreen].
///
/// Carries pre-fetched worker identity data so the tracking screen does not
/// need to re-fetch the worker profile on open. Booking status, location, and
/// ETA are always fetched fresh from the backend by the tracking controller.
class TrackingArgs {
  const TrackingArgs({
    required this.bookingId,
    required this.workerUid,
    this.workerName,
    this.workerPhone,
    this.serviceAddress,
    this.serviceLatitude,
    this.serviceLongitude,
  });

  final String bookingId;
  final String workerUid;
  final String? workerName;
  final String? workerPhone;
  final String? serviceAddress;
  final double? serviceLatitude;
  final double? serviceLongitude;
}
