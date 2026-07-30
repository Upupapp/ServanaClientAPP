import 'dart:convert';
import 'dart:developer';

import 'package:client/common/data/models/job_order_item.dart';
import 'package:flutter/foundation.dart';
import 'package:client/common/data/models/merchant_model.dart';
import 'package:client/common/data/backend/backend.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/modules/job_order/data/models/jo_details.dart';
import 'package:client/modules/job_order/data/models/merchant_user.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class JonOrderRepository {
  final Backend backend;

  JonOrderRepository({required this.backend});

  Future<List<JobOrderItem>> getMerchantJobOrderItems(String joID) async {
    return backend.getJobOrderItems(id: joID);
  }

  Future<List<MerchantUser>> getJobOrderEmployees(String joID) async {
    return backend.getJobOrderEmployees(id: joID);
  }

  Future<JobOrderDetails?> getMerchantJobOrder(String joID) async {
    return backend.getMerchantJoDetails(id: joID);
  }

  Future<MerchantModel?> getMerhcnatDetails(String merchantID) async {
    return backend.getMerchantDetails(id: merchantID);
  }

  Future<bool> insertJobOrder({
    required String merchantId,
    required String address,
    String? note,
    required DateTime schedule,
    required LatLng coords,
    required List<JobOrderItem> items,
    required List<StoreOptionItem> options,
  }) async {
    final session = await SessionService.getSession();
    final services = items
        .map(
          (e) => e.copyWith(
              selectedOptions: options
                  .where((option) => e.serviceId == option.merchantServiceID)
                  .map(
                    (e) => SelectedOption(
                        jobOrderOptionItemID: 0,
                        merchantOptionItemID: e.merchantOptionID,
                        merchantServiceID: items.first.jobOrderItemID,
                        optionAmount: e.amount,
                        transportaion: e.baseFair,
                        merchantOptionItemName: e.merchantOptionItemName,
                        quantity: 1),
                  )
                  .toList()),
        )
        .toList();
    final payload = {
      "customerID": session?.customerID,
      "merchantID": merchantId,
      "items": services
          .map(
            (e) => e.toJson(),
          )
          .toList(),
      "jobOrderNumber": "",
      "jobOrderStatus": 1,
      "scheduleDate": schedule.toIso8601String(),
      "address": address,
      "latitude": coords.latitude,
      "longitude": coords.longitude,
      "note": note,
      "paymentType": 1,
      "createdDate": DateTime.now().toIso8601String(),
    };
    if (kDebugMode) log(jsonEncode(payload));
    return backend.insertJobOrder(
      merchantId: merchantId,
      address: address,
      note: note,
      schedule: schedule,
      coords: coords,
      items: items,
      options: options,
      customerId: session?.customerID,
    );
  }

  Future<bool> addOptionToJo({
    required String jobOrderItemID,
    required String merchantOptionItemID,
    int quantity = 1,
  }) async {
    // No-op in mock mode; options are managed client-side.
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  Future<bool> deleteOptionFromJo({
    required int jobOrderOptionItemID,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  Future<bool> unAssignEmployee(String joID, int merchantUserID) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  Future<bool> addServiceToJo(
      String joID, int serviceId, List<SelectedOption> options) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return true;
  }

  Future<bool> markAsInstransit(String joID) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return true;
  }

  Future<bool> markAsInProgress(String joID) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return true;
  }

  Future<bool> markAsCompleted(String joID) async {
    return backend.markAsCompleted(id: joID);
  }
}
