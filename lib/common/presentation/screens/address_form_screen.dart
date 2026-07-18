import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/services/location_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart'
    show LatLong;

class AddressFormResult {
  const AddressFormResult({
    required this.address,
    required this.location,
    required this.unit,
    required this.street,
    required this.barangay,
    required this.city,
    required this.province,
    required this.landmark,
  });

  final String address;
  final LatLong location;
  final String unit;
  final String street;
  final String barangay;
  final String city;
  final String province;
  final String landmark;
}

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({
    super.key,
    this.title = 'Location Details',
    this.actionLabel = 'Save',
    this.initialAddress,
    this.initialLocation,
    this.initialUnit,
    this.initialStreet,
    this.initialBarangay,
    this.initialCity,
    this.initialProvince,
    this.initialLandmark,
    this.showGps = true,
  });

  final String title;
  final String actionLabel;
  final String? initialAddress;
  final LatLong? initialLocation;
  final String? initialUnit;
  final String? initialStreet;
  final String? initialBarangay;
  final String? initialCity;
  final String? initialProvince;
  final String? initialLandmark;
  final bool showGps;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  // BGC, Taguig — used when no initial location and GPS unavailable.
  static const LatLng _fallbackCenter = LatLng(14.5535, 121.0220);

  final _addressController = TextEditingController();
  final _unitController = TextEditingController();
  final _streetController = TextEditingController();
  final _barangayController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _landmarkController = TextEditingController();

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  late LatLng _pickedLatLng;
  bool _isGeocoding = false;
  // When the form opens with prefilled text, suppress the FIRST onCameraIdle
  // auto-fill so we don't clobber the user's saved values. Subsequent idles
  // (manual pan, "use my location" tap) still auto-fill.
  bool _suppressNextIdleGeocode = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = (widget.initialAddress ?? '').trim();
    _unitController.text = (widget.initialUnit ?? '').trim();
    _streetController.text = (widget.initialStreet ?? '').trim();
    _barangayController.text = (widget.initialBarangay ?? '').trim();
    _cityController.text = (widget.initialCity ?? '').trim();
    _provinceController.text = (widget.initialProvince ?? '').trim();
    _landmarkController.text = (widget.initialLandmark ?? '').trim();

    // Landmark and unit are excluded — only fields the reverse geocode would
    // overwrite count toward "prefilled" suppression.
    final hasPrefilledText = _addressController.text.isNotEmpty ||
        _streetController.text.isNotEmpty ||
        _barangayController.text.isNotEmpty ||
        _cityController.text.isNotEmpty ||
        _provinceController.text.isNotEmpty;

    final initial = widget.initialLocation;
    _pickedLatLng = initial != null
        ? LatLng(initial.latitude, initial.longitude)
        : _fallbackCenter;

    _suppressNextIdleGeocode = hasPrefilledText;

    if (initial == null) {
      // Try to recenter on GPS once we're mounted. Auto-attempt is silent on
      // failure; only the explicit FAB tap surfaces feedback.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _recenterOnGps(showFailureFeedback: false));
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _unitController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _recenterOnGps({bool showFailureFeedback = true}) async {
    try {
      final position = await LocationService()
          .getLocation()
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      // User explicitly asked for GPS — let the resulting onCameraIdle run
      // the geocode (single source of truth, no double-fire).
      _suppressNextIdleGeocode = false;
      final target = LatLng(position.latitude, position.longitude);
      if (kIsWeb) {
        // No map controller on web — just record the pin and try to geocode.
        setState(() => _pickedLatLng = target);
        await _reverseGeocodeAndFill(target);
      } else {
        await _animateTo(target);
      }
    } catch (_) {
      if (!mounted || !showFailureFeedback) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't get GPS — please type your address manually.",
            ),
            duration: Duration(seconds: 3),
          ),
        );
    }
  }

  Future<void> _animateTo(LatLng target) async {
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(target, 17),
    );
  }

  void _onCameraMove(CameraPosition pos) {
    _pickedLatLng = pos.target;
  }

  Future<void> _onCameraIdle() async {
    if (_suppressNextIdleGeocode) {
      _suppressNextIdleGeocode = false;
      return;
    }
    await _reverseGeocodeAndFill(_pickedLatLng);
  }

  Future<void> _reverseGeocodeAndFill(LatLng target) async {
    setState(() => _isGeocoding = true);
    final place =
        await LocationService().reverseGeocode(target.latitude, target.longitude);
    if (!mounted) return;
    if (place == null) {
      setState(() => _isGeocoding = false);
      return;
    }
    setState(() {
      _addressController.text = _composeAddressLine(place);
      _streetController.text = (place.thoroughfare ?? '').trim();
      _barangayController.text = (place.subLocality ?? '').trim();
      _cityController.text = (place.locality ?? '').trim();
      _provinceController.text = (place.administrativeArea ?? '').trim();
      _isGeocoding = false;
    });
  }

  String _composeAddressLine(Placemark p) {
    final parts = <String>[
      (p.subThoroughfare ?? '').trim(),
      (p.thoroughfare ?? '').trim(),
      (p.subLocality ?? '').trim(),
      (p.locality ?? '').trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final hasAddress = _addressController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryColorDark,
        foregroundColor: ColorPalette.primaryText,
        title: Text(
          widget.title,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            color: ColorPalette.primaryText,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.chevron_left, color: ColorPalette.primaryText),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (kIsWeb) _buildWebGpsBanner() else _buildMapSection(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kIsWeb
                          ? 'Enter your address details below. Tap “Use current GPS” to attach coordinates.'
                          : 'Pan the map to drop the pin where the technician should arrive. Edit any field below if the auto-fill is wrong.',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        color: ColorPalette.accentText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Complete Address'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _addressController,
                      hint: 'House/Unit/Building, Street, Barangay, City, Province',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _label('Details (optional)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller: _unitController,
                            hint: 'Unit / Building',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller: _streetController,
                            hint: 'Street',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller: _barangayController,
                            hint: 'Barangay',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller: _cityController,
                            hint: 'City / Municipality',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: _provinceController,
                      hint: 'Province',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: _landmarkController,
                      hint: 'Landmark (optional)',
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: hasAddress ? _onSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColorDark,
                      foregroundColor: ColorPalette.primaryButtonTextColor,
                      disabledBackgroundColor:
                          ColorPalette.primaryColorDark.withOpacity(.35),
                      disabledForegroundColor:
                          ColorPalette.primaryButtonTextColor.withOpacity(.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      widget.actionLabel,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLatLng,
              zoom: 17,
            ),
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),
          // Centered pin overlay — tip of the pin sits over the camera target.
          IgnorePointer(
            child: Center(
              child: Padding(
                // Lift the icon by ~half its height so the pin's tip — at the
                // bottom of the glyph — sits on the camera target.
                padding: const EdgeInsets.only(bottom: 22),
                child: Icon(
                  Icons.location_on,
                  size: 44,
                  color: ColorPalette.primaryColorDark,
                ),
              ),
            ),
          ),
          if (_isGeocoding)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Locating…',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 12,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.showGps)
            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                heroTag: 'address-form-gps',
                backgroundColor: Colors.white,
                foregroundColor: ColorPalette.primaryColorDark,
                onPressed: _recenterOnGps,
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebGpsBanner() {
    // "Have a non-fallback pin" — either an initialLocation was passed in, or
    // GPS resolved successfully. False when we're still sitting at BGC default.
    final hasPin =
        _pickedLatLng.latitude != _fallbackCenter.latitude ||
            _pickedLatLng.longitude != _fallbackCenter.longitude;
    return Container(
      width: double.infinity,
      color: ColorPalette.secondaryBackground,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: ColorPalette.accentText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasPin
                      ? 'Coordinates attached: ${_pickedLatLng.latitude.toStringAsFixed(5)}, ${_pickedLatLng.longitude.toStringAsFixed(5)}'
                      : 'Map preview is not available on web. Fill in your address below or attach GPS.',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.accentText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (widget.showGps) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _recenterOnGps,
                icon: Icon(Icons.my_location_rounded,
                    color: ColorPalette.primaryColorDark),
                label: Text(
                  'Use current GPS',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ColorPalette.border(.7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: FontPalette.primaryFontFamily,
          color: ColorPalette.secondaryText,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: ColorPalette.secondaryBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorPalette.border(.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: ColorPalette.primaryColorDark,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    Navigator.of(context).pop(
      AddressFormResult(
        location: LatLong(_pickedLatLng.latitude, _pickedLatLng.longitude),
        address: _addressController.text.trim(),
        unit: _unitController.text.trim(),
        street: _streetController.text.trim(),
        barangay: _barangayController.text.trim(),
        city: _cityController.text.trim(),
        province: _provinceController.text.trim(),
        landmark: _landmarkController.text.trim(),
      ),
    );
  }
}
