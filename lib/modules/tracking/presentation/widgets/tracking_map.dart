import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/modules/tracking/domain/booking_tracking_state.dart';
import 'package:client/modules/tracking/domain/tracking_freshness.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A live-tracking Google Map showing two markers:
///   1. The customer's service address (destination pin — always shown).
///   2. The provider's last-reported GPS position (only shown when available).
///
/// SECURITY: The provider marker is drawn only from [BookingTrackingState.providerLocation].
/// No coordinates are synthesised, interpolated, or animated.
///
/// TRACK-GAP-001: Because the backend has no socket location events, the map
/// is refreshed from the parent polling cycle (every 10 s). Marker updates
/// are therefore step-updates, not smooth animations.
class TrackingMap extends StatefulWidget {
  const TrackingMap({
    super.key,
    required this.state,
    this.height = 320,
  });

  final BookingTrackingState state;
  final double height;

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap> {
  GoogleMapController? _mapController;
  bool _cameraMoved = false;

  // Metro Manila centre — used when neither service nor provider location exists.
  static const _defaultCenter = LatLng(14.5995, 120.9842);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prevLoc = oldWidget.state.providerLocation;
    final newLoc = widget.state.providerLocation;
    if (newLoc != null &&
        (prevLoc == null ||
            prevLoc.latitude != newLoc.latitude ||
            prevLoc.longitude != newLoc.longitude)) {
      // Don't override the user's manual pan if they've moved the camera.
      if (!_cameraMoved) _animateCameraToProvider(newLoc.latLng);
    }
  }

  void _animateCameraToProvider(LatLng target) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(target));
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final s = widget.state;

    // Service address marker (destination).
    final servicePos = LatLng(s.serviceLatitude, s.serviceLongitude);
    if (s.serviceLatitude != 0 || s.serviceLongitude != 0) {
      markers.add(
        Marker(
          markerId: const MarkerId('service_address'),
          position: servicePos,
          infoWindow: InfoWindow(
            title: 'Service Location',
            snippet: s.serviceAddress.isNotEmpty ? s.serviceAddress : null,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    // Provider marker — only from a real backend snapshot.
    final loc = s.providerLocation;
    if (loc != null) {
      final isStale = s.freshness == TrackingFreshness.stale;
      markers.add(
        Marker(
          markerId: const MarkerId('provider_location'),
          position: loc.latLng,
          infoWindow: InfoWindow(
            title: s.providerName ?? 'Your Provider',
            snippet: isStale ? 'Last known location' : 'Current location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isStale
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    return markers;
  }

  LatLng _initialCameraTarget() {
    // Prefer provider location, else service address, else Metro Manila.
    final loc = widget.state.providerLocation;
    if (loc != null) return loc.latLng;
    final lat = widget.state.serviceLatitude;
    final lng = widget.state.serviceLongitude;
    if (lat != 0 || lng != 0) return LatLng(lat, lng);
    return _defaultCenter;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        child: Stack(
          children: [
            Semantics(
              label: 'Live tracking map. Provider location and route shown visually.',
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialCameraTarget(),
                  zoom: 15,
                ),
                markers: _buildMarkers(),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (ctrl) {
                  _mapController = ctrl;
                  // Fit both markers if available.
                  final loc = widget.state.providerLocation;
                  if (loc != null) {
                    Timer(const Duration(milliseconds: 300), () {
                      if (!mounted) return;
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(loc.latLng),
                      );
                    });
                  }
                },
                onCameraMoveStarted: () {
                  // Mark camera as user-moved so we stop auto-panning.
                  if (!_cameraMoved) setState(() => _cameraMoved = true);
                },
              ),
            ),

            // Re-centre button (shown after the user pans away).
            if (_cameraMoved)
              Positioned(
                right: 12,
                bottom: 12,
                child: _MapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Centre on provider',
                  onTap: () {
                    setState(() => _cameraMoved = false);
                    final loc = widget.state.providerLocation;
                    if (loc != null) _animateCameraToProvider(loc.latLng);
                  },
                ),
              ),

            // Freshness badge — only when provider location is available.
            if (widget.state.providerLocation != null)
              Positioned(
                top: 12,
                left: 12,
                child: _FreshnessBadge(freshness: widget.state.freshness),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Centre map on provider',
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 8),
              ],
            ),
            child: Icon(icon, size: 20, color: ColorPalette.primaryColorDark),
          ),
        ),
      ),
    );
  }
}

class _FreshnessBadge extends StatelessWidget {
  const _FreshnessBadge({required this.freshness});

  final TrackingFreshness freshness;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;

    switch (freshness) {
      case TrackingFreshness.live:
        bg = const Color(0xFF16A34A);
        fg = Colors.white;
        icon = Icons.circle;
        break;
      case TrackingFreshness.stale:
        bg = const Color(0xFFF59E0B);
        fg = Colors.white;
        icon = Icons.schedule_rounded;
        break;
      case TrackingFreshness.unknown:
        bg = Colors.grey.shade600;
        fg = Colors.white;
        icon = Icons.location_searching_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            freshness.chipLabel,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
