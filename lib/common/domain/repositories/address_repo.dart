import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:client/common/data/models/barangay.dart';
import 'package:client/common/data/models/city.dart';
import 'package:client/common/data/models/province.dart';

class AddressRepository {
  String _normalizeJson(String input) {
    // Some JSON assets may start with a UTF-8 BOM which breaks jsonDecode.
    return input.startsWith('\ufeff') ? input.substring(1) : input;
  }

  Future<List<CityModel>> fetchCities({String? provinceCode}) async {
    final String response = await rootBundle
        .loadString('assets/jsons/philippine-addresses/city.json');
    final data = jsonDecode(_normalizeJson(response)) as List;
    var list = data.map((e) => CityModel.fromJson(e)).toList();
    if (provinceCode != null) {
      list.removeWhere((element) => element.provinceCode != provinceCode);
    }
    var seen = <String>{};
    List<CityModel> uniquelist =
        list.where((element) => seen.add(element.name)).toList();
    return uniquelist;
  }

  Future<List<ProvinceModel>> fetchProvinces() async {
    final String response = await rootBundle
        .loadString('assets/jsons/philippine-addresses/province.json');
    final data = jsonDecode(_normalizeJson(response)) as List;

    var list = data.map((e) => ProvinceModel.fromJson(e)).toList();
    var seen = <String>{};
    List<ProvinceModel> uniquelist =
        list.where((element) => seen.add(element.name)).toList();
    return uniquelist;
  }

  Future<List<BarangayModel>> fetchBarangays({String? cityCode}) async {
    final String response = await rootBundle
        .loadString('assets/jsons/philippine-addresses/barangay.json');
    final data = jsonDecode(_normalizeJson(response)) as List;
    var list = data.map((e) => BarangayModel.fromJson(e)).toList();
    if (cityCode != null) {
      list.removeWhere((element) => element.cityCode != cityCode);
    }
    var seen = <String>{};
    List<BarangayModel> uniquelist =
        list.where((element) => seen.add(element.name)).toList();
    return uniquelist;
  }
}
