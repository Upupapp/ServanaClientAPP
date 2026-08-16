/// The canonical `/api/v1` transport.
///
/// One place owns URL construction, authorization, correlation headers,
/// pagination, timeout, error parsing and retry classification. Data sources
/// above it deal in domain objects and [ApiFailure]; nothing above it sees an
/// HTTP status, a header or a response body.
///
/// ## Relationship to ServanaApiClient
///
/// [ServanaApiClient] is not replaced and not wrapped. It keeps serving every
/// legacy route exactly as it does today — that is the installed-base contract
/// and TAB 01 found all 76 client calls resolve against it. This class is the
/// *second* transport, used only where [CanonicalAvailability] says a
/// capability may go canonical. Two clients is the intended end state of this
/// tab, not an accident: collapsing them before v1 deploys would mean editing
/// the code path that currently serves customers.
///
/// ## It cannot be pointed at a hard-coded host
///
/// [baseUrl] is supplied by the caller and in the app is always
/// `AppConfig.baseUrl`, which reads `API_BASE_URL` from the environment. There
/// is no default, no fallback and no literal host anywhere in this file, so a
/// build cannot accidentally ship pointing at a laptop.
///
/// ## Auth
///
/// The bearer token is resolved per request through [tokenProvider], the same
/// way [ServanaApiClient] does it — the backend verifies a Firebase ID token
/// that lives one hour, so a token cached at sign-in starts 401ing mid-session.
/// A null token is not an error: public endpoints exist and are called without
/// one.
library;

import 'dart:async';
import 'dart:convert';

import 'package:client/core/network/api_envelope.dart';
import 'package:client/core/network/api_error_mapper.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/request_id.dart';
import 'package:client/core/recovery/retry_policy.dart';
import 'package:http/http.dart' as http;

/// The header name the canonical routes actually read.
///
/// `servana_api/src/api/v1/envelope.ts` declares
/// `IDEMPOTENCY_HEADER = 'idempotency-key'` and `readIdempotencyKey` consults
/// that name and no other. The legacy `POST /api/bookings` is the one route
/// that reads `X-Idempotency-Key` (`controllers/bookingController.ts`), and
/// [ServanaApiClient] keeps sending that spelling for it.
///
/// This client sent the legacy spelling too, which meant a canonical mutation
/// carrying an idempotency key was indistinguishable from one carrying none:
/// the header was simply not looked at. Nothing had noticed because TAB 10 is
/// the first tab whose canonical calls mutate anything. The failure it would
/// have produced is the exact one idempotency exists to prevent — a retried
/// cancel or OTP verify replaying as a fresh attempt instead of returning the
/// original result.
const String idempotencyHeader = 'Idempotency-Key';

/// The shape the backend accepts: `^[A-Za-z0-9_.:-]{8,128}$`.
///
/// Checked here rather than left to the server because a malformed key is
/// rejected with `IDEMPOTENCY_KEY_INVALID` — a 400 the customer cannot act on
/// and which the mapper deliberately classifies as *our* bug. Catching it at
/// the boundary turns a wasted round trip into an assertion failure in a test.
final RegExp idempotencyKeyPattern = RegExp(r'^[A-Za-z0-9_.:-]{8,128}$');

class V1ApiClient {
  V1ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.tokenProvider,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 30),
    this.mapper = const ApiErrorMapper(),
  }) : _http = httpClient ?? http.Client();

  /// Origin only, e.g. `https://api.servana.com.ph`. Never includes `/api/v1`.
  final String baseUrl;

  final http.Client _http;

  /// Resolves the bearer token per request, or null for anonymous calls.
  final Future<String?> Function()? tokenProvider;

  /// Invoked on any 401 so the session layer can expire the session. Mirrors
  /// [ServanaApiClient]'s behaviour so the two transports cannot disagree
  /// about what a 401 means.
  final void Function()? onUnauthorized;

  final Duration timeout;
  final ApiErrorMapper mapper;

  // ── Verbs ──────────────────────────────────────────────────────────────────

  Future<ApiEnvelope> get(
    String path, {
    Map<String, dynamic>? query,
    CorrelationContext? correlation,
    RetryPolicy? retry,
  }) =>
      _send(
        'GET',
        path,
        query: query,
        correlation: correlation,
        // Reads are the only thing retried by default.
        retry: retry ?? RetryPolicyRegistry.query,
      );

  Future<ApiEnvelope> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CorrelationContext? correlation,
    String? idempotencyKey,
    RetryPolicy? retry,
  }) =>
      _send(
        'POST',
        path,
        body: body,
        query: query,
        correlation: correlation,
        idempotencyKey: idempotencyKey,
        retry: retry,
      );

  Future<ApiEnvelope> patch(
    String path, {
    Object? body,
    CorrelationContext? correlation,
    String? idempotencyKey,
    RetryPolicy? retry,
  }) =>
      _send('PATCH', path,
          body: body,
          correlation: correlation,
          idempotencyKey: idempotencyKey,
          retry: retry);

  Future<ApiEnvelope> put(
    String path, {
    Object? body,
    CorrelationContext? correlation,
    String? idempotencyKey,
    RetryPolicy? retry,
  }) =>
      _send('PUT', path,
          body: body,
          correlation: correlation,
          idempotencyKey: idempotencyKey,
          retry: retry);

  Future<ApiEnvelope> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CorrelationContext? correlation,
    RetryPolicy? retry,
  }) =>
      _send('DELETE', path,
          body: body, query: query, correlation: correlation, retry: retry);

  /// Fetches one page and maps each row.
  ///
  /// Pagination is expressed once, here, rather than by every caller inventing
  /// its own `limit`/`offset` parameter names.
  Future<Page<T>> getPage<T>(
    String path, {
    required T Function(Map<String, dynamic>) mapItem,
    int limit = 20,
    int offset = 0,
    String? itemsKey,
    Map<String, dynamic>? query,
    CorrelationContext? correlation,
  }) async {
    final envelope = await get(
      path,
      query: <String, dynamic>{
        ...?query,
        'limit': limit,
        'offset': offset,
      },
      correlation: correlation,
    );
    final rows = envelope.listAt(itemsKey);
    return Page<T>(
      items: rows.map(mapItem).toList(growable: false),
      meta: envelope.meta ??
          // A backend that returns a page without meta is treated as a single
          // complete page rather than as "more may exist" — guessing hasMore
          // would make a list paginate forever against a fixed response.
          PageMeta(
            limit: limit,
            offset: offset,
            total: rows.length,
            hasMore: false,
          ),
    );
  }

  void close() => _http.close();

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<ApiEnvelope> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CorrelationContext? correlation,
    String? idempotencyKey,
    RetryPolicy? retry,
  }) async {
    // Fail loudly in debug on a key the backend would reject. Shipping it would
    // spend a round trip to be told IDEMPOTENCY_KEY_INVALID, and the caller
    // would have believed it was protected against a retry when it was not.
    assert(
      idempotencyKey == null || idempotencyKeyPattern.hasMatch(idempotencyKey),
      'Idempotency-Key must match ${idempotencyKeyPattern.pattern} — got '
      '"$idempotencyKey" on $method $path',
    );

    final policy = retry ?? const RetryPolicy(maxAttempts: 1, baseDelay: Duration.zero);
    ApiFailure? last;

    for (var attempt = 1; attempt <= policy.maxAttempts; attempt++) {
      // A fresh request id per ATTEMPT, a stable correlation id across them —
      // otherwise three retries look like one request in the logs and the
      // reason a call eventually succeeded is invisible.
      final requestId = RequestIds.newRequestId();
      try {
        return await _attempt(
          method,
          path,
          body: body,
          query: query,
          correlation: correlation,
          idempotencyKey: idempotencyKey,
          requestId: requestId,
        );
      } on ApiFailure catch (failure) {
        last = failure;

        final isLastAttempt = attempt == policy.maxAttempts;
        if (isLastAttempt || !failure.isRetryable) rethrow;

        // Never blind-retry a mutation whose result is unknown unless the
        // caller supplied an idempotency key. This is the C20 rule the legacy
        // client encodes in RetryPolicyRegistry, applied here at the transport
        // so a data source cannot forget it.
        final isMutation = method != 'GET';
        if (isMutation && idempotencyKey == null) rethrow;

        final wait = failure is RateLimitFailure && failure.retryAfter != null
            ? failure.retryAfter!
            : policy.delayFor(attempt);
        await Future<void>.delayed(wait);
      }
    }
    // Unreachable while maxAttempts >= 1; kept so the function is total.
    throw last ??
        const UnknownFailure(safeMessage: 'Something went wrong. Please try again.');
  }

  Future<ApiEnvelope> _attempt(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CorrelationContext? correlation,
    String? idempotencyKey,
    required String requestId,
  }) async {
    final uri = _uri(path, query);
    final headers = await _headers(
      requestId: requestId,
      correlation: correlation,
      idempotencyKey: idempotencyKey,
      hasBody: body != null,
    );

    http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _http.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } catch (error) {
      throw mapper.fromTransport(error, requestId: requestId);
    }

    final status = response.statusCode;
    if (status == 401) onUnauthorized?.call();

    if (status < 200 || status >= 300) {
      throw mapper.fromResponse(
        status: status,
        body: response.body,
        headers: response.headers,
        fallbackRequestId: requestId,
      );
    }

    if (response.body.isEmpty) return const ApiEnvelope(data: null);
    try {
      return ApiEnvelope.from(jsonDecode(response.body));
    } catch (_) {
      // A 2xx with an unparseable body is a server contract break, not a
      // customer error. Classified unknown so it is never silently retried.
      throw UnknownFailure(
        safeMessage: 'Something went wrong. Please try again.',
        requestId: requestId,
        debugDetail: 'Unparseable 2xx body on $method $path',
      );
    }
  }

  Uri _uri(String path, Map<String, dynamic>? query) {
    final normalisedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse('$normalisedBase$path');
    if (query == null || query.isEmpty) return uri;
    // Null-valued params are dropped rather than sent as "null", which the
    // backend would read as a literal filter value.
    final params = <String, String>{};
    query.forEach((key, value) {
      if (value == null) return;
      params[key] = '$value';
    });
    return uri.replace(queryParameters: <String, String>{
      ...uri.queryParameters,
      ...params,
    });
  }

  Future<Map<String, String>> _headers({
    required String requestId,
    CorrelationContext? correlation,
    String? idempotencyKey,
    required bool hasBody,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      RequestIds.requestHeader: requestId,
      if (hasBody) 'Content-Type': 'application/json',
      if (correlation != null) ...correlation.headers,
      if (idempotencyKey != null) idempotencyHeader: idempotencyKey,
    };

    // Reading the token must never be able to fail a request: a public
    // endpoint needs no token, and secure storage can throw for reasons that
    // have nothing to do with this call.
    try {
      final token = await tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Fall through unauthenticated; the server decides.
    }
    return headers;
  }
}
