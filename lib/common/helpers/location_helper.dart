import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
// import 'package:place_picker/place_picker.dart';
import 'package:client/common/data/models/address_data_model.dart';
import 'package:client/common/data/models/service_coverage_geo.dart';

class LocationHelper {
  /// Ray-casting algorithm: returns true if (lat, lon) is inside [ring].
  /// Each element of [ring] is a [lon, lat] pair (GeoJSON order).
  static bool isPointInPolygon(
      double lat, double lon, List<List<double>> ring) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i][1], yi = ring[i][0]; // lat, lon
      final xj = ring[j][1], yj = ring[j][0];
      final intersect = ((yi > lon) != (yj > lon)) &&
          (lat < (xj - xi) * (lon - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// Returns true if the point falls within any polygon of [coverage].
  static bool isWithinCoverage(
      double lat, double lon, ServiceCoverageGeo coverage) {
    for (final feature in coverage.features) {
      final geo = feature.geometry;
      if (geo.type != 'Polygon' || geo.coordinates.isEmpty) continue;
      // First ring is the outer boundary; subsequent rings are holes.
      if (isPointInPolygon(lat, lon, geo.coordinates.first)) return true;
    }
    return false;
  }

  static String localizedPrice(double amont) {
    return NumberFormat.simpleCurrency(locale: "en_PH", name: "PHP")
        .format(amont);
  }

  /// a static function that solves for distance in kilometers from a lat/long pair
  static double distanceBetween(
      {required double lat1,
      required double long1,
      required double lat2,
      required double long2}) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((long2 - long1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<AddressDataModel?> showPlacePicker(BuildContext context) async {
    return null;

    // var curLocation = await getCurrentLocation();
    // var position = curLocation.result;

    // ignore: use_build_context_synchronously
    // LocationResult result = await Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => PlacePicker(
    //       Keys.googleMapsAPI,
    //     ),
    //   ),
    // );
    // final addressData = AddressDataModel(
    //   barangay: result.subLocalityLevel1?.name,
    //   city: result.city?.name,
    //   country: result.country?.name,
    //   postalCode: result.postalCode,
    //   province: result.administrativeAreaLevel2?.name,
    //   streetAddress: result.formattedAddress,
    //   locationCoordinates: LocationCoordinatesModel(
    //       latitude: result.latLng?.latitude ?? 0,
    //       longhitude: result.latLng?.longitude ?? 0),
    // );

    // return addressData;
  }

  Future<({Position? result, String? error})> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return (result: null, error: 'Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return (result: null, error: 'Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return (
        result: null,
        error:
            'Location permissions are permanently denied, we cannot request permissions.'
      );
    }

    var result = await Geolocator.getCurrentPosition();

    return (result: result, error: null);
  }
}
