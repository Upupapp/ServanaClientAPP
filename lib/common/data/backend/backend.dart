import 'package:client/common/data/models/job_order_item.dart';
import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/data/models/merchant_category.dart';
import 'package:client/common/data/models/merchant_light.dart';
import 'package:client/common/data/models/merchant_model.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/data/models/merchant_service_option.dart';
import 'package:client/common/data/models/service_coverage_geo.dart';
import 'package:client/common/data/models/user_address_model.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/modules/homepage/data/models/search_service_result.dart';
import 'package:client/modules/job_order/data/models/jo_details.dart';
import 'package:client/modules/job_order/data/models/merchant_user.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract interface class Backend {
  Future<({UserSession? session, String? error, int? statusCode})>
      authenticate({
    required String email,
    required String password,
    String fcmToken = '',
  });

  Future<({bool isSuccess, String? message, int? statusCode})> registerCustomer(
      RegistrationFormModel registration);

  Future<List<MerchantLight>> getNearbyMerchants({
    required double latitude,
    required double longitude,
  });

  Future<List<JobOrder>> getBookings({required String customerId});

  Future<List<SearchServiceResult>> searchService({required String keyword});

  Future<MerchantModel?> getMerchantDetails({required String id});

  Future<JobOrderDetails?> getMerchantJoDetails({required String id});

  Future<List<JobOrderItem>> getJobOrderItems({required String id});

  Future<List<MerchantUser>> getJobOrderEmployees({required String id});

  Future<List<MerchantServiceModel>> getServices({required String merchantId});

  Future<List<MerchantServiceOptionModel>> getMerchantOptions(
      {required String merchantId});

  Future<List<({int key, String value})>> getCategories(
      {required String merchantId});

  Future<bool> toggleService({
    required String id,
    required bool isOn,
  });

  Future<bool> addService({required MerchantServiceModel service});

  Future<({bool isSuccess, String? error})> editService(
      {required MerchantServiceModel service});

  Future<bool> addServiceCategory({required MerchantCategory category});

  Future<bool> insertJobOrder({
    required String merchantId,
    required String address,
    String? note,
    required DateTime schedule,
    required LatLng coords,
    required List<JobOrderItem> items,
    required List<StoreOptionItem> options,
    String? customerId,
  });

  Future<bool> markAsCompleted({required String id});

  Future<({bool isSuccess, String? message})> addUserAddress(
      UserAddressModel address);

  Future<({bool isSuccess, String? message})> makeAddressPrimary(
      {required String addressId});

  Future<ServiceCoverageGeo?> getServiceCoverageGeo(
      {required String serviceId});

  Future<({bool isSuccess, String? message, int? statusCode})>
      resendVerificationEmail({required String email});

  /// Revoke the current session on the backend (best-effort; no-op if unsupported).
  Future<void> logout();
}
