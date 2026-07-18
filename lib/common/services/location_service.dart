import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:toastification/toastification.dart';

class LocationService {
  Position? locationCache;

  Future<Position> getLocation() async {
    Location location = Location();

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      toastification.show(
        title: const Text(
            'App needs location services to search for nearby merchants. Please enable location services.'),
        type: ToastificationType.warning,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(days: 1),
        showProgressBar: false,
      );
      await location.requestService();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.

        toastification.show(
          title: const Text(
              'App needs location services to search for nearby merchants. Please enable location services.'),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(days: 1),
          showProgressBar: false,
        );

        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    var position = await Geolocator.getCurrentPosition();
    locationCache = position;

    return position;
  }

  Future<Stream<Position>> getLocationStream() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    var stream = Geolocator.getPositionStream();

    return stream;
  }

  /// Reverse-geocode a coordinate to a [Placemark] using the platform-native
  /// geocoder (Android Geocoder, iOS CLGeocoder). Free; no Google Geocoding
  /// API billing. Returns null if the lookup fails or yields no results.
  Future<Placemark?> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      return placemarks.first;
    } catch (_) {
      return null;
    }
  }
}
