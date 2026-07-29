import 'dart:convert';
import 'dart:developer' as dev;

import 'package:client/common/domain/helpers/session_service.dart';
import 'package:http/http.dart' as http;

/// Thin, low-level client that wraps every Servana REST API endpoint.
///
/// Auth is handled automatically: on each request the client reads the current
/// session from [SessionService] and attaches a `Bearer` token if one exists.
/// Callers never need to pass tokens manually.
class ServanaApiClient {
  static const Duration _kTimeout = Duration(seconds: 30);

  final String baseUrl;
  final http.Client _client;

  ServanaApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = _TimeoutClient(client ?? http.Client(), _kTimeout);

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  Future<Map<String, String>> _headers() async {
    final session = await SessionService.getSession();
    final token = session?.token;
    if (token != null && token.isNotEmpty) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  Future<Map<String, dynamic>> _decodeJson(http.Response response) async {
    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      dev.log(
        'HTTP $status ${response.request?.method ?? ''} ${response.request?.url ?? ''}\n${response.body}',
        name: 'ServanaApi',
      );
      throw ServanaApiException(
        statusCode: status,
        body: response.body,
      );
    }
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'data': decoded};
  }

  // ───────────────────────── Auth ─────────────────────────
  // Auth endpoints intentionally skip the auto-token (user isn't logged in yet).

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required int role,
  }) async {
    final uri = _uri('/api/auth/signup');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'platform': 'mobile',
      }),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> signin({
    required String email,
    required String password,
    String fcmToken = '',
  }) async {
    final uri = _uri('/api/auth/signin');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fcmToken': fcmToken,
      }),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> firebaseLogin({
    required String idToken,
    String? fcmToken,
  }) async {
    final uri = _uri('/api/auth/customer-firebase-login');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      }),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> resendVerification(
      {required String email}) async {
    final uri = _uri('/api/auth/resendverification', {'email': email});
    final res = await _client.get(uri);
    return _decodeJson(res);
  }

  // ───────────────────── User / Profile ─────────────────────

  Future<Map<String, dynamic>> addUserAddress({
    required Map<String, dynamic> payload,
  }) async {
    final uri = _uri('/api/user/adduseraddress');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> makeAddressPrimary({
    required String addressId,
  }) async {
    final uri = _uri(
      '/api/user/makeaddressprimary',
      {'addressId': addressId},
    );
    final res = await _client.put(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getAllUserAddresses({
    bool? isArchived,
    int? role,
  }) async {
    final query = <String, dynamic>{};
    if (isArchived != null) query['isArchived'] = isArchived;
    if (role != null) query['role'] = role;
    final uri =
        _uri('/api/user/alluseraddresses', query.isEmpty ? null : query);
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getAddressById({
    required String addressId,
  }) async {
    final uri = _uri('/api/user/getaddressbyid', {'id': addressId});
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> deleteAddress({
    required String addressId,
  }) async {
    final uri = _uri('/api/user/deleteaddress', {'addressId': addressId});
    final res = await _client.delete(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> payload,
  }) async {
    final uri = _uri('/api/user/updateprofile');
    final res = await _client.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getUserProfile({required String id}) async {
    final uri = _uri('/api/user/profile', {'id': id});
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  /// Load the authenticated user's own profile (JWT-scoped, no ID param).
  Future<Map<String, dynamic>> loadProfile() async {
    final uri = _uri('/api/user/profile');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> verifyEmailOtp({required String otp}) async {
    final uri = _uri('/api/auth/verify-email-otp');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'otp': otp}),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> resendEmailOtp() async {
    final uri = _uri('/api/auth/resend-email-otp');
    final res = await _client.post(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getRegisteredUsers({
    bool? isArchived,
    int? role,
  }) async {
    final query = <String, dynamic>{};
    if (isArchived != null) query['isArchived'] = isArchived;
    if (role != null) query['role'] = role;
    final uri = _uri('/api/user/registereduser', query.isEmpty ? null : query);
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  // ───────────────────── Services & Coverage ─────────────────────

  Future<Map<String, dynamic>> listServices() async {
    final uri = _uri('/api/services');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> listLevel2Services({
    required int serviceId,
  }) async {
    final uri = _uri('/api/services/$serviceId/level2');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> listOptionsWithAddons({
    required int serviceId,
  }) async {
    final uri = _uri('/api/services/$serviceId/options-with-addons');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> listFullCatalog() async {
    final uri = _uri('/api/services/full');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getBeautyAndWellnessBranches({
    required int serviceId,
  }) async {
    final uri = _uri('/api/services/$serviceId/branches');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getBranchSlots({
    required int branchId,
    required DateTime date,
  }) async {
    final uri = _uri(
      '/api/branches/$branchId/slots',
      {'date': date.toIso8601String().split('T').first},
    );
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> createGeoCoverage({
    required int serviceId,
    required Map<String, dynamic> payload,
  }) async {
    final uri = _uri('/api/services/$serviceId/coverage-geo');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getGeoCoverage({
    required int serviceId,
  }) async {
    final uri = _uri('/api/services/$serviceId/coverage-geo');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getAirconQuote({
    required Map<String, dynamic> payload,
  }) async {
    final uri = _uri('/api/quote');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getUserBookings({
    required String userId,
  }) async {
    final uri = _uri('/api/users/$userId/bookings');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  // ───────────────────── Workers ─────────────────────

  Future<Map<String, dynamic>> listWorkersByRole(int role) async {
    final uri = _uri('/api/workers/role/$role');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getWorkerByUid(String uid) async {
    final uri = _uri('/api/workers/$uid');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getWorkerLocation(String uid) async {
    final uri = _uri('/api/workers/location/$uid');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> updateWorkerLocation(
      Map<String, dynamic> payload) async {
    final uri = _uri('/api/workers/location');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decodeJson(res);
  }

  // ───────────────────── Bookings & Payment ─────────────────────

  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final uri = _uri('/api/bookings', {'userId': userId});
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getBooking(int bookingId) async {
    final uri = _uri('/api/$bookingId');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  /// Verifies the booking's `otpCode` while it is still in `PENDING_OTP`.
  /// The code travels in the query string with an empty body, and the BE
  /// returns 400 (`{success:false,message:...}`) for a wrong code.
  Future<Map<String, dynamic>> confirmOtp({
    required int bookingId,
    required String otp,
  }) async {
    final uri = _uri('/api/$bookingId/confirm-otp', {'otp': otp});
    final res = await _client.post(uri, headers: await _headers());
    return _decodeJson(res);
  }

  /// Triggers the BE to re-send the booking OTP for [bookingId].
  // ALIGN-C07-001: POST /api/$bookingId/resend-otp must exist on the backend.
  // Verify route is implemented in Upupapp/servana_api before releasing
  // BookingOtpScreen to production — if missing, "Resend code" always fails.
  Future<Map<String, dynamic>> resendOtp({required int bookingId}) async {
    final uri = _uri('/api/$bookingId/resend-otp');
    final res = await _client.post(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getBookingTracking(int bookingId) async {
    final uri = _uri('/api/$bookingId/tracking');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> submitGcashProof({
    required int bookingId,
    required Map<String, dynamic> payload,
  }) async {
    final uri = _uri('/api/$bookingId/gcash-submit');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> approveGcashPayment({
    required int bookingId,
  }) async {
    final uri = _uri('/api/$bookingId/approve');
    final res = await _client.post(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> approveCashPayment({
    required int bookingId,
  }) async {
    final uri = _uri('/api/$bookingId/mark-cash-paid');
    final res = await _client.post(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> createPaymongoSession({
    required int bookingId,
  }) async {
    final uri = _uri('/api/$bookingId/paymongo/create');
    final res = await _client.post(uri, headers: await _headers());
    return _decodeJson(res);
  }

  /// Convenience alias for [getBooking] using a string booking ID.
  ///
  /// The correct customer/mobile detail path is GET /api/<id> (bare numeric ID,
  /// no "bookings" segment).  The path /api/bookings/<id> does NOT exist on the
  /// backend.  This alias accepts a String so call-sites do not need to parse.
  Future<Map<String, dynamic>> getBookingDetail(String bookingId) {
    return getBooking(int.parse(bookingId));
  }

  /// Cancel a booking on behalf of the customer.
  ///
  /// POST /api/bookings/:id/cancel — customer-facing route (GAP-C15-001 closed).
  /// verifyAuthOptional: passes a Firebase token if present for ownership check.
  Future<Map<String, dynamic>> cancelBooking({
    required int bookingId,
    required String reason,
    String? reasonCode,
  }) async {
    final uri = _uri('/api/bookings/$bookingId/cancel');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'reason': reason,
        if (reasonCode != null) 'reasonCode': reasonCode,
      }),
    );
    return _decodeJson(res);
  }

  /// Returns booking timeline events for a given booking.
  ///
  // BACKEND_GAP-C15-002: The full timeline endpoint is admin-only:
  //   GET /api/admin/bookings/:id/timeline
  //   Requires: verifyAuth + verifyRoles([1]) + requirePermission('bookings.timeline.view')
  // The customer-facing equivalent is GET /api/:id/tracking (already wired as
  // [getBookingTracking]).  This method delegates to tracking so the repository
  // has a uniform surface — replace the path once a customer timeline route is
  // available.  Priority: MEDIUM — tracking rows cover the essential use-case.
  Future<Map<String, dynamic>> getBookingTimeline(int bookingId) {
    // Falls back to the customer tracking endpoint (same data, different shape).
    return getBookingTracking(bookingId);
  }

  // ���──────────────────── FCM Token ───────��─────────────

  Future<Map<String, dynamic>> registerFcmToken(String token) async {
    final uri = _uri('/api/user/fcm-token');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'token': token}),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> clearFcmToken() async {
    final uri = _uri('/api/user/fcm-token');
    final res = await _client.delete(uri, headers: await _headers());
    return _decodeJson(res);
  }

  // ─────────────────────── Chat / Messaging ──────────────────────────────────

  /// Resolve or create the conversation for a booking.
  /// Returns the ConversationModel JSON with id, booking_id, unread_count, etc.
  Future<Map<String, dynamic>> getBookingConversation({
    required String bookingId,
  }) async {
    final uri = _uri('/api/bookings/$bookingId/conversation');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  /// List all conversations for the authenticated user with unread counts.
  Future<Map<String, dynamic>> listConversations() async {
    final uri = _uri('/api/chat/conversations');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  /// Fetch a page of messages for a conversation.
  /// [before] is the oldest message id seen (keyset pagination).
  Future<Map<String, dynamic>> getMessages({
    required int conversationId,
    int limit = 40,
    int? before,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (before != null) query['before'] = before;
    final uri = _uri('/api/chat/conversations/$conversationId/messages', query);
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  /// Send a text message. [clientMsgId] is the idempotency key.
  Future<Map<String, dynamic>> sendChatMessage({
    required int conversationId,
    required String body,
    required String clientMsgId,
    String type = 'text',
  }) async {
    final uri = _uri('/api/chat/conversations/$conversationId/messages');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'type': type,
        'body': body,
        'clientMsgId': clientMsgId,
      }),
    );
    return _decodeJson(res);
  }

  /// Mark all messages up to [lastReadMessageId] as read.
  Future<Map<String, dynamic>> markConversationRead({
    required int conversationId,
    required int lastReadMessageId,
  }) async {
    final uri = _uri('/api/chat/conversations/$conversationId/read');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'lastReadMessageId': lastReadMessageId}),
    );
    return _decodeJson(res);
  }

  /// Report a message for moderation.
  Future<Map<String, dynamic>> reportChatMessage({
    required int conversationId,
    required int messageId,
    required String category,
    String? description,
  }) async {
    final uri = _uri('/api/chat/conversations/$conversationId/messages/$messageId/report');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'category': category,
        if (description != null) 'description': description,
      }),
    );
    return _decodeJson(res);
  }

  // ���──────────────────── Customer Notifications ─────────────────────

  Future<Map<String, dynamic>> listNotifications({String? filter}) async {
    final query = <String, dynamic>{};
    if (filter != null) query['filter'] = filter;
    final uri = _uri('/api/user/notifications', query.isEmpty ? null : query);
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getNotificationsUnreadCount() async {
    final uri = _uri('/api/user/notifications/unread-count');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> markNotificationRead(String key) async {
    final uri = _uri('/api/user/notifications/$key/read');
    final res = await _client.patch(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final uri = _uri('/api/user/notifications/mark-all-read');
    final res = await _client.post(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> deleteNotification(String key) async {
    final uri = _uri('/api/user/notifications/$key');
    final res = await _client.delete(uri, headers: await _headers());
    return _decodeJson(res);
  }

  // ─────���─────────────── Admin ─────────────────────

  Future<Map<String, dynamic>> createBranchSlot(
      Map<String, dynamic> payload) async {
    final uri = _uri('/api/branches/slots');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    return _decodeJson(res);
  }

  // ─── Customer Support ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listSupportTickets() async {
    final uri = _uri('/api/support/tickets');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> createSupportTicket({
    required String subject,
    required String description,
    required String category,
    String? clientRequestId,
    String? bookingId,
  }) async {
    final uri = _uri('/api/support/tickets');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'subject': subject,
        'description': description,
        'category': category,
        if (clientRequestId != null) 'clientRequestId': clientRequestId,
        if (bookingId != null) 'bookingId': bookingId,
      }),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getSupportTicketDetail(String ticketKey) async {
    final uri = _uri('/api/support/tickets/$ticketKey');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> addSupportTicketReply({
    required String ticketKey,
    required String message,
  }) async {
    final uri = _uri('/api/support/tickets/$ticketKey/replies');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'message': message}),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> markSupportTicketRead(String ticketKey) async {
    final uri = _uri('/api/support/tickets/$ticketKey/mark-read');
    final res = await _client.post(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> closeSupportTicket(String ticketKey) async {
    final uri = _uri('/api/support/tickets/$ticketKey/close');
    final res = await _client.post(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> reopenSupportTicket(String ticketKey) async {
    final uri = _uri('/api/support/tickets/$ticketKey/reopen');
    final res = await _client.post(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getSupportUnreadCount() async {
    final uri = _uri('/api/support/unread-count');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getSupportEmergencyConfig() async {
    final uri = _uri('/api/support/safety/emergency-config');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> listSafetyIncidents() async {
    final uri = _uri('/api/support/safety/incidents');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> submitSafetyIncident({
    required String clientIncidentId,
    required String category,
    required String severity,
    required String description,
    String? bookingId,
    bool immediateDanger = false,
  }) async {
    final uri = _uri('/api/support/safety/incidents');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'clientIncidentId': clientIncidentId,
        'category': category,
        'severity': severity,
        'description': description,
        if (bookingId != null) 'bookingId': bookingId,
        'immediateDanger': immediateDanger,
      }),
    );
    return _decodeJson(res);
  }

  // ─── Customer Reviews ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getReviewEligibility(String bookingId) async {
    final uri = _uri('/api/bookings/$bookingId/review-eligibility');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> createReview({
    required String bookingId,
    required int overallRating,
    required Map<String, int> dimensions,
    String? publicComment,
    String? privateFeedback,
    String visibility = 'PUBLIC',
    String? clientRequestId,
  }) async {
    final uri = _uri('/api/bookings/$bookingId/reviews');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'overallRating': overallRating,
        'dimensions': dimensions,
        if (publicComment != null) 'publicComment': publicComment,
        if (privateFeedback != null) 'privateFeedback': privateFeedback,
        'visibility': visibility,
        if (clientRequestId != null) 'clientRequestId': clientRequestId,
      }),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getReviewByBooking(String bookingId) async {
    final uri = _uri('/api/bookings/$bookingId/reviews');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getReviewById(String reviewId) async {
    final uri = _uri('/api/reviews/$reviewId');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> editReview({
    required String reviewId,
    required int overallRating,
    required Map<String, int> dimensions,
    String? publicComment,
    String? privateFeedback,
    String visibility = 'PUBLIC',
  }) async {
    final uri = _uri('/api/reviews/$reviewId');
    final res = await _client.put(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'overallRating': overallRating,
        'dimensions': dimensions,
        if (publicComment != null) 'publicComment': publicComment,
        if (privateFeedback != null) 'privateFeedback': privateFeedback,
        'visibility': visibility,
      }),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    final uri = _uri('/api/reviews/$reviewId');
    final res = await _client.delete(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> listMyReviews() async {
    final uri = _uri('/api/reviews/me');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> reportReview({
    required String reviewId,
    required String reason,
    String? details,
  }) async {
    final uri = _uri('/api/reviews/$reviewId/report');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'reason': reason,
        if (details != null) 'details': details,
      }),
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> getProviderAggregate(String providerUid) async {
    final uri = _uri('/api/providers/$providerUid/rating');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }
}

class ServanaApiException implements Exception {
  final int statusCode;
  final String body;

  const ServanaApiException({
    required this.statusCode,
    required this.body,
  });

  @override
  String toString() =>
      'ServanaApiException(statusCode: $statusCode, body: $body)';
}

/// Wraps an [http.Client] and applies a per-request timeout.
/// Timed-out requests throw [ServanaApiException] with status 408.
class _TimeoutClient extends http.BaseClient {
  _TimeoutClient(this._inner, this._timeout);

  final http.Client _inner;
  final Duration _timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(
            _timeout,
            onTimeout: () => throw ServanaApiException(
              statusCode: 408,
              body: 'Request timed out after ${_timeout.inSeconds}s',
            ),
          );

  @override
  void close() => _inner.close();
}
