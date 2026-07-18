import 'dart:convert';

import 'package:client/common/data/backend/backend.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
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
import 'package:client/modules/messaging/data/models/chat_message.dart';
import 'package:client/modules/registration/data/models/registration_form_model.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Real HTTP backend that talks to the Servana REST API.
class HttpBackend implements Backend {
  final String baseUrl;
  final http.Client _client;

  HttpBackend({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  // ───────────────────────── Auth ─────────────────────────

  @override
  Future<({UserSession? session, String? error})> authenticate({
    required String email,
    required String password,
    String fcmToken = '',
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/signin');
    final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fcmToken': fcmToken,
        }),
      );
    } catch (e) {
      return (
        session: null,
        error: 'Could not reach server. Please check your connection.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      // The Servana API wraps the payload under "data".
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final token = (data['token'] ?? '') as String;

      return (
        session: UserSession(
          customerID: (data['id'] ?? data['customerID'] ?? '').toString(),
          mobileNumber:
              (data['phoneNumber'] ?? data['mobileNumber'] ?? '').toString(),
          fullname: (data['fullname'] ?? _buildFullName(data)).toString(),
          emailAddress:
              (data['email'] ?? data['emailAddress'] ?? email).toString(),
          token: token,
        ),
        error: null,
      );
    }

    String errorMessage;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = body['message'] as String? ??
          body['error'] as String? ??
          'Login failed.';
    } catch (_) {
      errorMessage = 'Login failed (${response.statusCode}).';
    }

    return (session: null, error: errorMessage);
  }

  static String _buildFullName(Map<String, dynamic> json) {
    final first = (json['firstName'] ?? '').toString().trim();
    final last = (json['lastName'] ?? '').toString().trim();
    return '$first $last'.trim();
  }

  @override
  Future<({bool isSuccess, String? message})> registerCustomer(
      RegistrationFormModel registration) async {
    final fullName = (registration.ownerName ?? '').trim();
    final parts = fullName.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final http.Response response;
    final uri = Uri.parse('$baseUrl/api/auth/signup');
    try {
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': registration.ownerEmail ?? '',
          'password': registration.ownerPassword ?? '',
          'firstName': firstName,
          'lastName': lastName,
          'role': 3,
          'platform': 'mobile',
        }),
      );
    } catch (e) {
      return (
        isSuccess: false,
        message: 'Could not reach server. Please check your connection.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        isSuccess: true,
        message: body['message'] as String? ?? 'Registration successful.',
      );
    }

    String errorMessage;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = body['message'] as String? ??
          body['error'] as String? ??
          'Registration failed.';
    } catch (_) {
      errorMessage = 'Registration failed (${response.statusCode}).';
    }

    return (isSuccess: false, message: errorMessage);
  }

  @override
  Future<void> logout() async {
    // No backend logout endpoint currently. Client-side session clear suffices.
    // TODO: when BE adds POST /api/auth/logout, call it here.
  }

  @override
  Future<({bool isSuccess, String? message})> resendVerificationEmail(
      {required String email}) async {
    final uri = Uri.parse('$baseUrl/api/auth/resendverification')
        .replace(queryParameters: {'email': email});
    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (e) {
      return (
        isSuccess: false,
        message: 'Could not reach server. Please check your connection.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      String? message;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['message'] as String?;
      } catch (_) {}
      return (
        isSuccess: true,
        message: message ?? 'Verification email sent.',
      );
    }

    String errorMessage;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = body['message'] as String? ??
          body['error'] as String? ??
          'Failed to resend verification email.';
    } catch (_) {
      errorMessage =
          'Failed to resend verification email (${response.statusCode}).';
    }

    return (isSuccess: false, message: errorMessage);
  }

  // ───────────────────── User / Address ─────────────────────

  @override
  Future<({bool isSuccess, String? message})> addUserAddress(
      UserAddressModel address) async {
    final uri = Uri.parse('$baseUrl/api/user/adduseraddress');
    final http.Response response;
    try {
      final json = address.toJson();
      if ((json['locationId'] ?? '').toString().isEmpty) {
        json['locationId'] =
            'loc_${address.lat.toStringAsFixed(6)}_${address.lon.toStringAsFixed(6)}';
      }
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(json),
      );
    } catch (e) {
      return (
        isSuccess: false,
        message: 'Could not reach server. Please check your connection.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        isSuccess: true,
        message: body['message'] as String? ?? 'Address saved.',
      );
    }

    String errorMessage;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = body['message'] as String? ??
          body['error'] as String? ??
          'Failed to save address.';
    } catch (_) {
      errorMessage = 'Failed to save address (${response.statusCode}).';
    }

    return (isSuccess: false, message: errorMessage);
  }

  @override
  Future<({bool isSuccess, String? message})> makeAddressPrimary(
      {required String addressId}) async {
    final uri = Uri.parse('$baseUrl/api/user/makeaddressprimary')
        .replace(queryParameters: {'addressId': addressId});
    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (e) {
      return (
        isSuccess: false,
        message: 'Could not reach server. Please check your connection.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      String? message;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['message'] as String?;
      } catch (_) {}
      return (
        isSuccess: true,
        message: message ?? 'Address set as primary.',
      );
    }

    String errorMessage;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = body['message'] as String? ??
          body['error'] as String? ??
          'Failed to set primary address.';
    } catch (_) {
      errorMessage = 'Failed to set primary address (${response.statusCode}).';
    }

    return (isSuccess: false, message: errorMessage);
  }

  // ───────────────────── Services ─────────────────────

  @override
  Future<List<MerchantServiceModel>> getServices(
      {required String merchantId}) async {
    final uri = Uri.parse('$baseUrl/api/services')
        .replace(queryParameters: {'merchantId': merchantId});
    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (e) {
      return [];
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> list = decoded is List
          ? decoded
          : (decoded['data'] ?? decoded['items'] ?? []);
      return list
          .map((e) => MerchantServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  @override
  Future<ServiceCoverageGeo?> getServiceCoverageGeo(
      {required String serviceId}) async {
    final uri = Uri.parse('$baseUrl/api/services/$serviceId/coverage-geo');
    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (_) {
      return null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return ServiceCoverageGeo.fromJson(body);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // ─────────────── Not yet integrated ───────────────

  @override
  Future<List<MerchantLight>> getNearbyMerchants(
      {required double latitude, required double longitude}) {
    throw UnimplementedError('getNearbyMerchants is not yet integrated');
  }

  @override
  Future<List<JobOrder>> getBookings({required String customerId}) async {
    final api = ServanaApiClient(baseUrl: baseUrl);
    try {
      final res = await api.getUserBookings(userId: customerId);
      final List<dynamic> list = res['bookings'] ?? res['data'] ?? [];
      // Dedupe by id — the BE list endpoint occasionally returns the same
      // booking twice when multiple payment-attempt rows exist server-side
      // (duplicates differ in `referenceNo` and `paymentMethodUsed`). The
      // mapper reads BE's `paymentMethod` (per-booking, stable across dupes)
      // not `paymentMethodUsed`, and never reads `referenceNo`, so first-wins
      // is order-independent for the mapped JobOrder. Unique-by-id is a
      // permanent invariant on this endpoint regardless of BE fix.
      final seen = <String, JobOrder>{};
      for (final e in list) {
        final mapped = _mapApiBookingToJobOrder(e as Map<String, dynamic>);
        seen.putIfAbsent(mapped.jobOrderID, () => mapped);
      }
      return seen.values.toList();
    } catch (_) {
      return [];
    }
  }

  static JobOrder _mapApiBookingToJobOrder(Map<String, dynamic> b) {
    final id = b['id']?.toString() ?? '';
    final status = (b['status'] ?? '').toString().toUpperCase();
    final paymentStatus = (b['paymentStatus'] ?? '').toString().toUpperCase();
    final paymentMethod = (b['paymentMethod'] ?? '').toString().toUpperCase();

    // Map API status to JobOrderStatus enum
    JobOrderStatus jobStatus;
    String statusLabel;
    switch (status) {
      case 'PENDING_OTP':
        // Wire status string is still PENDING_OTP — semantically this is now
        // "awaiting technician to enter the customer's worker code at job
        // start". For online methods left at PENDING (e.g. PayMongo "Pay
        // Later"), surface as "Payment Required" so the customer can finish
        // paying from the booking card. For CASH, just show as a normal
        // scheduled booking — payment happens on service.
        // TODO: when the BE renames this status to PENDING_WORKER_CODE (or
        //       similar), update this case literal and the matching equality
        //       check in `booking_detail_screen.dart`'s `_shouldPoll`.
        if (paymentStatus == 'PENDING' &&
            (paymentMethod == 'PAYMONGO' || paymentMethod == 'GCASH')) {
          jobStatus = JobOrderStatus.forReview;
          statusLabel = 'Payment Required';
        } else {
          jobStatus = JobOrderStatus.accepted;
          statusLabel = 'Scheduled';
        }
        break;
      case 'CONFIRMED':
        if (paymentStatus == 'PENDING' && paymentMethod == 'PAYMONGO') {
          jobStatus = JobOrderStatus.forReview;
          statusLabel = 'Payment Required';
        } else {
          jobStatus = JobOrderStatus.accepted;
          statusLabel = 'Confirmed';
        }
        break;
      case 'WORKER_ASSIGNED':
        if (paymentStatus == 'PENDING' && paymentMethod == 'PAYMONGO') {
          jobStatus = JobOrderStatus.forReview;
          statusLabel = 'Payment Required';
        } else {
          jobStatus = JobOrderStatus.accepted;
          statusLabel = 'Worker Assigned';
        }
        break;
      case 'PAID':
        jobStatus = JobOrderStatus.accepted;
        statusLabel = 'Paid';
        break;
      case 'IN_PROGRESS':
        jobStatus = JobOrderStatus.inProgress;
        statusLabel = 'In Progress';
        break;
      case 'COMPLETED':
        jobStatus = JobOrderStatus.completed;
        statusLabel = 'Completed';
        break;
      case 'CANCELLED':
        jobStatus = JobOrderStatus.cancelled;
        statusLabel = 'Cancelled';
        break;
      default:
        jobStatus = JobOrderStatus.none;
        statusLabel = status;
    }

    // Extract service name from pricing breakdown
    String serviceName = 'Beauty & Wellness';
    final breakdown = b['pricingBreakdown'] as Map<String, dynamic>?;
    if (breakdown != null) {
      final addons = breakdown['addons'] as List?;
      if (addons != null && addons.isNotEmpty) {
        final first = addons.first as Map<String, dynamic>?;
        if (first != null && first['level_3'] != null) {
          serviceName = first['level_3'].toString();
        }
      }
    }

    final rawPrice = b['finalPrice'] ?? b['quotedPrice'] ?? 0;
    final totalAmount = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice.toString()) ?? 0;

    return JobOrder(
      jobOrderID: id,
      jobOrderNumber: 'BK-$id',
      merchantName: 'Servana',
      merchantID: 'servana',
      scheduleDate: DateTime.tryParse(b['schedule']?.toString() ?? '') ??
          DateTime.now(),
      jobOrderStatus: jobStatus,
      jobOrderStatusToString: statusLabel,
      address:
          '${b['address'] ?? ''}, ${b['postTown'] ?? ''}'.replaceAll(RegExp(r'^, |, $'), ''),
      latitude: 0,
      longitude: 0,
      numberOfPersonnel: 1,
      distanceFromOffice: 0,
      merchantServiceName: serviceName,
      downPayment: 0,
      totalAmount: totalAmount,
      paymentType: paymentMethod == 'PAYMONGO' ? 3 : 1,
      createdDate: DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      paymentStatus: paymentStatus,
      paymentMethodUsed: paymentMethod,
    );
  }

  @override
  Future<List<SearchServiceResult>> searchService({required String keyword}) {
    throw UnimplementedError('searchService is not yet integrated');
  }

  @override
  Future<MerchantModel?> getMerchantDetails({required String id}) {
    throw UnimplementedError('getMerchantDetails is not yet integrated');
  }

  @override
  Future<JobOrderDetails?> getMerchantJoDetails({required String id}) {
    throw UnimplementedError('getMerchantJoDetails is not yet integrated');
  }

  @override
  Future<List<JobOrderItem>> getJobOrderItems({required String id}) {
    throw UnimplementedError('getJobOrderItems is not yet integrated');
  }

  @override
  Future<List<MerchantUser>> getJobOrderEmployees({required String id}) {
    throw UnimplementedError('getJobOrderEmployees is not yet integrated');
  }

  @override
  Future<List<MerchantServiceOptionModel>> getMerchantOptions(
      {required String merchantId}) {
    throw UnimplementedError('getMerchantOptions is not yet integrated');
  }

  @override
  Future<List<({int key, String value})>> getCategories(
      {required String merchantId}) {
    throw UnimplementedError('getCategories is not yet integrated');
  }

  @override
  Future<bool> toggleService({required String id, required bool isOn}) {
    throw UnimplementedError('toggleService is not yet integrated');
  }

  @override
  Future<bool> addService({required MerchantServiceModel service}) {
    throw UnimplementedError('addService is not yet integrated');
  }

  @override
  Future<({bool isSuccess, String? error})> editService(
      {required MerchantServiceModel service}) {
    throw UnimplementedError('editService is not yet integrated');
  }

  @override
  Future<bool> addServiceCategory({required MerchantCategory category}) {
    throw UnimplementedError('addServiceCategory is not yet integrated');
  }

  @override
  Future<bool> insertJobOrder({
    required String merchantId,
    required String address,
    String? note,
    required DateTime schedule,
    required LatLng coords,
    required List<JobOrderItem> items,
    required List<StoreOptionItem> options,
    String? customerId,
  }) {
    throw UnimplementedError('insertJobOrder is not yet integrated');
  }

  @override
  Future<bool> markAsCompleted({required String id}) {
    throw UnimplementedError('markAsCompleted is not yet integrated');
  }

  @override
  Future<List<ChatMessage>> getJobOrderMessages({required String jobOrderId}) {
    throw UnimplementedError('getJobOrderMessages is not yet integrated');
  }

  @override
  Future<ChatMessage> sendJobOrderMessage({
    required String jobOrderId,
    required String text,
    required bool fromCustomer,
    String? customerId,
  }) {
    throw UnimplementedError('sendJobOrderMessage is not yet integrated');
  }
}
