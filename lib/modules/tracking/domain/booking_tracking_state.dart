import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/modules/tracking/domain/geo_position_snapshot.dart';
import 'package:client/modules/tracking/domain/tracking_eta.dart';
import 'package:client/modules/tracking/domain/tracking_freshness.dart';
import 'package:client/modules/tracking/domain/tracking_visibility.dart';

/// Immutable snapshot of all tracking-relevant state for an active booking.
///
/// Every field that is displayed on the live tracking screen must come from
/// a verified backend resource. Nothing in this class is synthesised,
/// interpolated, or animated.
class BookingTrackingState {
  const BookingTrackingState({
    required this.bookingId,
    required this.bookingStatus,
    required this.serviceAddress,
    required this.serviceLatitude,
    required this.serviceLongitude,
    this.providerLocation,
    this.eta,
    this.providerUid,
    this.providerName,
    this.providerPhone,
    TrackingVisibility? visibility,
  }) : _visibility = visibility;

  final String bookingId;

  /// Current lifecycle status mapped from the backend status string.
  final BookingStatus bookingStatus;

  /// GPS coordinates of the *provider*'s last-reported position.
  ///
  /// Null when: provider has not yet pushed a location, or the location
  /// fetch failed. The UI must not show a pin when this is null.
  final GeoPositionSnapshot? providerLocation;

  /// Estimate-once ETA. See TRACK-GAP-003 — not a live countdown.
  final TrackingEta? eta;

  /// Firebase UID of the assigned provider.
  final String? providerUid;

  /// Display name of the assigned provider (fetched from worker profile).
  final String? providerName;

  /// Phone number of the assigned provider.
  final String? providerPhone;

  /// Customer's service address string.
  final String serviceAddress;

  /// Latitude of the customer's service location.
  final double serviceLatitude;

  /// Longitude of the customer's service location.
  final double serviceLongitude;

  final TrackingVisibility? _visibility;

  /// Why the position is or is not on the map.
  ///
  /// Never null to a caller: when the transport supplied no verdict, one is
  /// inferred from whether a position arrived and marked
  /// `isBackendDerived: false`. That keeps every screen on one code path while
  /// still letting it tell a measured answer from a guess.
  TrackingVisibility get visibility =>
      _visibility ??
      TrackingVisibility.inferred(hasPosition: providerLocation != null);

  /// Whether the booking has reached a terminal state and tracking can stop.
  bool get isTerminal => BookingStatusMapper.isTerminal(bookingStatus);

  /// Whether the tracking view should show the provider map.
  bool get isTrackable =>
      bookingStatus == BookingStatus.enRoute ||
      bookingStatus == BookingStatus.arrived ||
      bookingStatus == BookingStatus.inProgress ||
      bookingStatus == BookingStatus.awaitingCompletion;

  /// Current freshness of the provider location.
  TrackingFreshness get freshness {
    final loc = providerLocation;
    if (loc == null) return TrackingFreshness.unknown;
    return loc.isStaleAt(DateTime.now())
        ? TrackingFreshness.stale
        : TrackingFreshness.live;
  }

  BookingTrackingState copyWith({
    BookingStatus? bookingStatus,
    GeoPositionSnapshot? providerLocation,
    TrackingEta? eta,
    String? providerName,
    String? providerPhone,
    TrackingVisibility? visibility,
  }) {
    return BookingTrackingState(
      bookingId: bookingId,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      serviceAddress: serviceAddress,
      serviceLatitude: serviceLatitude,
      serviceLongitude: serviceLongitude,
      providerLocation: providerLocation ?? this.providerLocation,
      eta: eta ?? this.eta,
      providerUid: providerUid,
      providerName: providerName ?? this.providerName,
      providerPhone: providerPhone ?? this.providerPhone,
      visibility: visibility ?? _visibility,
    );
  }
}
