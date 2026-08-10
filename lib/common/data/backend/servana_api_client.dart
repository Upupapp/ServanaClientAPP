import 'dart:convert';
import 'dart:developer' as dev;

import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Thin, low-level client that wraps every Servana REST API endpoint.
///
/// Auth is handled automatically: on each request the client resolves a token
/// via [tokenProvider] and attaches it as a `Bearer` header if one exists.
/// Callers never need to pass tokens manually.
///
/// ## Why [tokenProvider] exists
///
/// This used to read `SessionService.getSession()?.token` directly — a token
/// persisted once at sign-in and never renewed. The backend verifies it with
/// `admin.auth().verifyIdToken()` (servana_api/src/middleware/verifyAuth.ts:36),
/// so it is a **Firebase ID token, which expires after one hour**; the backend
/// has an explicit `auth/id-token-expired` branch that answers
/// `TOKEN_EXPIRED — Session expired. Please log in again.`
///
/// The result was that every authenticated route started returning 401 an hour
/// after sign-in, and `onUnauthorized` then dropped the session — so the app
/// signed the customer out roughly hourly, mid-journey. That stayed invisible
/// while only rarely used routes required auth. It stopped being invisible when
/// the core booking flow was authenticated (52667b3) and the customer's booking
/// list, addresses, cancellation and payment calls all moved behind `verifyAuth`.
///
/// `FirebaseAuth.currentUser.getIdToken()` renews automatically when the token
/// is expired or close to it, and is a cheap in-memory read otherwise, so the
/// fix is to ask per request rather than to cache at sign-in. It is injected
/// rather than imported so this low-level client keeps no Firebase dependency
/// and stays constructible in tests without initialising Firebase.
class ServanaApiClient {
  static const Duration _kTimeout = Duration(seconds: 30);

  final String baseUrl;
  final http.Client _client;

  /// Called when any response returns HTTP 401 (token expired / revoked).
  /// Wire this in GetIt to update [AuthStateService] and clear the session.
  final void Function()? onUnauthorized;

  /// Resolves the bearer token for each request.
  ///
  /// Defaults to the stored session token, which preserves the previous
  /// behaviour for tests and for any caller constructing this directly. The
  /// app wires a refreshing provider in `main_injector.dart`.
  final Future<String?> Function()? tokenProvider;

  ServanaApiClient({
    required this.baseUrl,
    http.Client? client,
    this.onUnauthorized,
    this.tokenProvider,
  }) : _client = _TimeoutClient(client ?? http.Client(), _kTimeout);

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  /// In-flight refresh, so a burst of parallel requests performs ONE exchange.
  /// Google rotates refresh tokens, so without this every request but the first
  /// would present one that had just been replaced.
  static Future<String?>? _refreshInFlight;

  Future<String?> _resolveToken() async {
    // Reading the session must never be able to fail a request.
    //
    // This read was unguarded, and it is on the path of EVERY call — including
    // the ones that need no token at all, like the service catalog. Secure
    // storage can throw for reasons that have nothing to do with the request:
    // a MissingPluginException before the plugin registers, or a
    // PlatformException from EncryptedSharedPreferences / Keychain when the
    // key has been invalidated by a restore, an upgrade or a lock-screen
    // change. Any of those took down every category screen and the Explore
    // list with "Could not load services. Please check your connection" —
    // which sends the customer to check their wifi over a local storage fault.
    //
    // Degrading to an anonymous request is correct here: the catalog routes
    // are unauthenticated server-side, so they answer 200 without a token, and
    // a genuinely authenticated call still fails honestly with a 401 that
    // onUnauthorized already handles.
    UserSession? session;
    try {
      session = await SessionService.getSession();
    } catch (e) {
      debugPrint(
          '[ServanaApi] session read failed, continuing anonymously: $e');
      session = null;
    }
    final stored = session?.token;

    // 1. Firebase SDK, for SOCIAL sign-in. getIdToken() renews when near expiry.
    final provider = tokenProvider;
    if (provider != null) {
      try {
        final fresh = await provider();
        // The uid check is not paranoia. Logout never signed out of Firebase,
        // so FirebaseAuth.currentUser survives it. Customer A signs in with
        // Google, logs out, customer B signs in with email and password — the
        // Servana session is B's, but the Firebase session is still A's, and
        // preferring the Firebase token would send A's credential for B's
        // requests and return A's data. Binding the token to the session that
        // is actually active closes that regardless of what Firebase holds.
        if (fresh != null &&
            fresh.isNotEmpty &&
            _matchesSession(fresh, session)) {
          return fresh;
        }
      } catch (_) {
        // Never let a refresh failure become a request failure: fall through.
      }
    }

    if (stored == null || stored.isEmpty) return stored;

    // 2. EMAIL/PASSWORD sign-in reaches here, and this is the case the first
    //    version of this fix missed. Those sessions are established by the
    //    BACKEND calling Firebase server-side, so FirebaseAuth.currentUser is
    //    null on this device and step 1 always yields null. The stored ID token
    //    then expires after an hour and the app signs the customer out —
    //    exactly the bug the Firebase provider was added to fix, still live for
    //    everyone who did not use Google or Facebook.
    if (!_isExpiringSoon(stored)) return stored;

    final refresh = session?.refreshToken ?? '';
    if (refresh.isEmpty) return stored;

    _refreshInFlight ??= _exchangeRefreshToken(refresh, session!)
        .whenComplete(() => _refreshInFlight = null);
    // Fall back to the stale token if the exchange fails: the server answers
    // 401 and onUnauthorized decides, so one place owns sign-out.
    return (await _refreshInFlight) ?? stored;
  }

  /// True when [jwt] belongs to the customer whose session is active.
  ///
  /// Compares the token's subject to the stored customerID. A token with no
  /// readable subject is accepted — the alternative is refusing to authenticate
  /// on an unparseable-but-possibly-fine token, which breaks more than it fixes.
  static bool _matchesSession(String jwt, UserSession? session) {
    final expected = session?.customerID;
    if (expected == null || expected.isEmpty) return true;
    final claims = _claimsOf(jwt);
    final subject = (claims?['user_id'] ?? claims?['sub'])?.toString();
    if (subject == null || subject.isEmpty) return true;
    return subject == expected;
  }

  static Map<String, dynamic>? _claimsOf(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      payload += '=' * ((4 - payload.length % 4) % 4);
      final decoded = jsonDecode(utf8.decode(base64.decode(payload)));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// True when [jwt] expires within two minutes, or is already expired.
  ///
  /// A token whose `exp` cannot be read is treated as healthy — guessing it is
  /// expired would refresh on every single request.
  static bool _isExpiringSoon(String jwt) {
    final exp = _claimsOf(jwt)?['exp'];
    if (exp is! int) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return expiry.isBefore(DateTime.now().add(const Duration(minutes: 2)));
  }

  Future<String?> _exchangeRefreshToken(
    String refreshToken,
    UserSession session,
  ) async {
    try {
      // Deliberately does NOT go through _headers(): that would call back into
      // _resolveToken and recurse.
      final res = await _client.post(
        _uri('/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      final body = jsonDecode(res.body);

      if (res.statusCode != 200) {
        // 401 means the refresh token is genuinely dead — expired, revoked, or
        // the account disabled. Anything else (502, a network blip) is
        // transient and must not end a working session.
        if (res.statusCode == 401) onUnauthorized?.call();
        return null;
      }

      final data = body is Map ? body['data'] : null;
      final token = data is Map ? data['token'] : null;
      if (token is! String || token.isEmpty) return null;

      final rotated = data is Map ? data['refreshToken'] : null;
      await SessionService.saveSession(
        session.copyWith(
          token: token,
          refreshToken:
              rotated is String && rotated.isNotEmpty ? rotated : refreshToken,
        ),
      );
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _resolveToken();
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
      if (kDebugMode) {
        dev.log(
          'HTTP $status ${response.request?.method ?? ''} ${response.request?.url ?? ''}\n${response.body}',
          name: 'ServanaApi',
        );
      }
      // STITCH B1: notify caller of session expiry so the router can redirect.
      if (status == 401) onUnauthorized?.call();
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

  /// Account creation.
  ///
  /// **Not the live path, and it has already drifted.** Nothing in `lib/` or
  /// `test/` calls this. Registration goes through
  /// `RegistrationRepository.submitRegistration` → `Backend.registerCustomer`
  /// → `HttpBackend.registerCustomer`, which posts to this same endpoint but
  /// also sends `phoneNumber`.
  ///
  /// This copy never sent it. The Create Account screen collects "Mobile Number
  /// (optional)" into `RegistrationFormModel.ownerPhoneNo`, so anyone who
  /// switched the app to this method — the shorter, more obvious-looking one on
  /// the API client — would silently stop persisting every customer's phone
  /// number, with nothing failing to show for it.
  ///
  /// Kept rather than deleted because it is a legitimate description of the
  /// endpoint's shape, but marked so it cannot be adopted by accident. If it is
  /// ever made live, add `phoneNumber` first and delete
  /// `HttpBackend.registerCustomer` in the same change — two implementations of
  /// one operation is what produced this drift.
  @Deprecated(
    'Dead code that omits phoneNumber. Use Backend.registerCustomer instead.',
  )
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

  /// Verifies the emailed OTP.
  ///
  /// `email` is REQUIRED by the backend — auth.service.verifyEmailOtp rejects a
  /// body without it ("Missing required parameters"), and the OTP row is looked
  /// up by email, not by token. This client omitted it, so in-app verification
  /// could never succeed for anyone. It cannot be derived server-side either:
  /// these routes are unauthenticated by necessity, since a customer who has
  /// not verified cannot sign in to obtain a token.
  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final uri = _uri('/api/auth/verify-email-otp');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return _decodeJson(res);
  }

  /// Resends the verification OTP. `email` is required for the same reason.
  Future<Map<String, dynamic>> resendEmailOtp({required String email}) async {
    final uri = _uri('/api/auth/resend-email-otp');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'email': email}),
    );
    return _decodeJson(res);
  }

  /// Ends the session server-side.
  ///
  /// POST /api/auth/logout revokes the Firebase refresh tokens and clears the
  /// stored FCM token. Without it a logout was purely local: the refresh token
  /// stayed valid, so anyone holding it could keep minting ID tokens, and the
  /// device kept receiving that customer's push notifications.
  Future<Map<String, dynamic>> logout() async {
    final uri = _uri('/api/auth/logout');
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

  // listWorkersByRole (GET /api/workers/role/:role) removed. It was a directory
  // listing of every provider on the platform, reachable by any caller, and no
  // screen ever used it — its only remaining caller was a test that needed an
  // arbitrary authenticated GET. Provider matching is a backend concern
  // (eligibility is computed server-side and lists are filtered there), so a
  // client should never ask this. The route is marked for deletion rather than
  // replacement in servana_api/docs/WORKER_ROUTE_MIGRATION.md.

  /// `GET /api/booking/:bookingId/provider` — who is coming to this booking.
  ///
  /// Replaces `GET /api/workers/:uid`, which let any authenticated caller name
  /// any provider and pull their profile. That route was audience-projected, so
  /// a customer only ever received a name and a phone number — but the request
  /// could still be phrased about anyone, and it was the last thing keeping the
  /// legacy `/api/workers/*` family alive.
  ///
  /// Keyed on a booking the caller already owns; `assertBookingAccess` decides
  /// entitlement server-side. Returns `{assigned: false, worker: null}` before a
  /// provider is matched, which is a normal state and not an error.
  Future<Map<String, dynamic>> getBookingProvider(int bookingId) async {
    final uri = _uri('/api/booking/$bookingId/provider');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  /// `GET /api/booking/:bookingId/provider-location` — where is the provider on
  /// *this* booking.
  ///
  /// Replaces `GET /api/workers/location/:uid`, which carried no authentication
  /// and let the caller name any provider, so anyone could follow any worker's
  /// live position. Entitlement here is decided server-side by
  /// `assertBookingAccess`, and the request cannot even express "where is some
  /// other provider" — there is no worker id in it.
  ///
  /// Response distinguishes three states:
  ///   `{assigned: false, location: null}` — not matched to a provider yet
  ///   `{assigned: true,  location: null}` — matched, but no position reported
  ///   `{assigned: true,  location: {...}}` — matched and reporting
  Future<Map<String, dynamic>> getBookingProviderLocation(int bookingId) async {
    final uri = _uri('/api/booking/$bookingId/provider-location');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
  }

  // ───────────────────── Bookings & Payment ─────────────────────

  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    final uri = _uri('/api/bookings', {'userId': userId});
    final headers = {
      ...await _headers(),
      if (idempotencyKey != null) 'X-Idempotency-Key': idempotencyKey,
    };
    final res = await _client.post(
      uri,
      headers: headers,
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
  /// The BE returns 400 (`{success:false,message:...}`) for a wrong code.
  ///
  /// The code travels in the BODY. It used to be sent as `?otp=123456`, and a
  /// query string is written to the nginx access log on every request — so each
  /// verification wrote a live credential into a plaintext log that is rotated,
  /// backed up, and readable by anyone with host access. The OTP is what proves
  /// the customer is present, so that log line is a credential.
  ///
  /// The request was already a POST; the body was simply going unused. The
  /// backend now reads the body first and falls back to the query, so builds
  /// already in customers' hands keep working.
  Future<Map<String, dynamic>> confirmOtp({
    required int bookingId,
    required String otp,
  }) async {
    final uri = _uri('/api/$bookingId/confirm-otp');
    final res = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'otp': otp}),
    );
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
  /// GET /api/:id/timeline — customer-facing route (GAP-C15-002 closed).
  /// verifyAuth + assertBookingAccess: the same ownership check /api/:id and
  /// /api/:id/tracking already apply, so somebody else's booking answers 403.
  ///
  /// Envelope: { success: true, timeline: [ { code, label, at, actor,
  /// sequence } ] }.  The events are voiced for the CUSTOMER — `actor` is
  /// "YOU" for the customer, "PROVIDER" for the professional, "SERVANA" for
  /// the platform.  This is not the provider route's vocabulary, where "YOU"
  /// means the provider; the backend projects between the two deliberately.
  ///
  /// This used to delegate to [getBookingTracking] because no customer route
  /// existed.  Tracking is a different thing — live position — and remains
  /// wired separately for the callers that want it.
  Future<Map<String, dynamic>> getBookingTimeline(int bookingId) async {
    final uri = _uri('/api/$bookingId/timeline');
    final res = await _client.get(uri, headers: await _headers());
    return _decodeJson(res);
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
    final uri = _uri(
        '/api/chat/conversations/$conversationId/messages/$messageId/report');
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
