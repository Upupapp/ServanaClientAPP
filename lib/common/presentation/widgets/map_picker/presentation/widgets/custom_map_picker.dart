import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/data/models/address_data_model.dart';
import 'package:client/common/data/models/location_coordinates_model.dart';

class CustomMapPicker extends StatefulWidget {
  const CustomMapPicker({
    super.key,
    this.label = "Pick Location",
    this.onChange,
    this.controller,
    this.inputType,
    this.onTap,
    this.error,
    this.value,
    this.location,
  });

  final CameraPosition nemo = const CameraPosition(
    target: LatLng(0, 0),
  );

  final String label;
  final String? error;
  final String? value;
  final LocationCoordinatesModel? location;
  final void Function(AddressDataModel value)? onChange;
  final void Function()? onTap;
  final TextEditingController? controller;
  final TextInputType? inputType;

  @override
  State<CustomMapPicker> createState() => _CustomMapPickerState();
}

class _CustomMapPickerState extends State<CustomMapPicker> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  Future<void> _goToLocation() async {
    final GoogleMapController controller = await _controller.future;
    if (widget.location != null) {
      final position = CameraPosition(
        zoom: 15,
        target: LatLng(widget.location!.latitude, widget.location!.longhitude),
      );
      try {
        await controller
            .animateCamera(CameraUpdate.newCameraPosition(position));
      } catch (e) {
        FirebaseCrashlytics.instance.log(e.toString());
      }
    }
  }

  @override
  void didUpdateWidget(covariant CustomMapPicker oldWidget) {
    if (oldWidget.location == null || oldWidget.location != widget.location) {
      _goToLocation();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme themeColor = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              color: ColorPalette.secondaryText,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(5),
          widget.location != null
              ? Container(
                  height: 254,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          offset: Offset.zero,
                          color: ColorPalette.shadow(.1),
                        ),
                      ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: widget.nemo,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      zoomGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      onTap: (_) {
                        widget.onTap?.call();
                      },
                      markers: {
                        if (widget.location != null)
                          Marker(
                            markerId: const MarkerId("store"),
                            draggable: false,
                            position: LatLng(widget.location!.latitude,
                                widget.location!.longhitude),
                          )
                      },
                      onMapCreated: (GoogleMapController controller) {
                        try {
                          _goToLocation();
                        } catch (e) {
                          FirebaseCrashlytics.instance.log(e.toString());
                        }
                        _controller.complete(controller);
                      },
                    ),
                  ),
                )
              : Container(
                  height: 254,
                  decoration: BoxDecoration(
                    color: (widget.error != null)
                        ? themeColor.errorContainer
                        : ColorPalette.primaryColorLight,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        offset: Offset.zero,
                        color: ColorPalette.shadow(.1),
                      )
                    ],
                    border: (widget.error != null)
                        ? Border.all(
                            color: themeColor.error,
                            width: 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/icons/map_pin.png",
                      fit: BoxFit.contain,
                      height: 60,
                    ),
                  ),
                ),
          if (widget.error != null) ...[
            const SizedBox(
              height: 5,
            ),
            Row(
              children: [
                const SizedBox(
                  width: 10,
                ),
                Text(
                  widget.error!,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: themeColor.error,
                  ),
                ),
              ],
            )
          ],
        ],
      ),
    );
  }
}
