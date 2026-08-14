/// Translates every wire failure — canonical v1, legacy, or transport — into
/// exactly one [ApiFailure].
///
/// ## One mapper, three input shapes
///
/// The backend ships three response envelopes and says so itself
/// (`servana_api/src/api/v1/envelope.ts`): `helpers/status.ts` writes
/// `{status, data}` / `{status:'error', error:<string>}`, `utils/apiResponse.ts`
/// writes `{success, message, data}`, and v1 writes `{data, meta}` /
/// `{error:{code,message,details,requestId}}`. All three are protected
/// contracts; none can be changed for the installed base. So the client
/// normalises instead, in one place, and everything above this file sees only
/// the nine cases.
///
/// ## Status first, code second, and why
///
/// The canonical status for a code is authoritative
/// (`V1_ERROR_STATUS` in the backend), so the HTTP status is the primary
/// signal. A handful of codes need an override because two conditions share a
/// status and have opposite recoveries — `IDEMPOTENCY_KEY_REUSED` and
/// `BOOKING_TERMINAL` are both 409 and mean very different things to a
/// customer. Those overrides are listed explicitly rather than inferred, so
/// adding one is a visible edit.
///
/// ## Deny by default
///
/// An unrecognised status or a body we cannot parse becomes [UnknownFailure],
/// which is NOT retryable. The alternative — assuming success or assuming
/// retryable — is how a client repeats a payment.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:client/core/network/api_failure.dart';

class ApiErrorMapper {
  const ApiErrorMapper();

  /// Codes whose classification does not follow from their HTTP status.
  ///
  /// Everything not listed here is classified by status alone.
  static const Map<String, _Kind> _codeOverrides = <String, _Kind>{
    // 409, but the opposite recovery from every other 409.
    'IDEMPOTENCY_KEY_REUSED': _Kind.idempotency,

    // 400, but not something the customer can fix by editing a field — the
    // client generated a malformed key, which is our bug, not their input.
    'IDEMPOTENCY_KEY_INVALID': _Kind.unknown,

    // 502 upstreams. Status already implies retryable; named so the intent
    // survives a future status change.
    'PAYMENT_PROCESSOR_UNAVAILABLE': _Kind.retryable,
    'REFRESH_UNAVAILABLE': _Kind.retryable,

    // 429 family — all rate limits, including the OTP cooldowns.
    'BOOKING_OTP_RESEND_COOLDOWN': _Kind.rateLimit,
    'BOOKING_OTP_RESEND_LIMIT': _Kind.rateLimit,
    'BOOKING_OTP_ATTEMPTS_EXHAUSTED': _Kind.rateLimit,
  };

  /// Customer-safe copy per case. Deliberately non-specific: the backend's own
  /// `message` is preferred when it is present, and this is the floor.
  static const Map<_Kind, String> _defaultCopy = <_Kind, String>{
    _Kind.auth: 'Your session has expired. Please sign in again.',
    _Kind.forbidden: "You don't have access to this.",
    _Kind.notFound: "We couldn't find that.",
    _Kind.validation: 'Please check the details and try again.',
    _Kind.stateConflict: 'This has already changed. Pull to refresh.',
    _Kind.idempotency: 'This was already submitted.',
    _Kind.rateLimit: 'Too many attempts. Please wait a moment.',
    _Kind.retryable: "Something went wrong on our end. Please try again.",
    _Kind.unknown: 'Something went wrong. Please try again.',
  };

  /// Maps a completed HTTP response.
  ///
  /// [body] is the raw response body; [status] the HTTP status; [headers] is
  /// consulted only for `Retry-After`. [fallbackRequestId] is the
  /// client-generated `X-Request-Id` we sent, used when the response carries
  /// no `error.requestId` of its own.
  ApiFailure fromResponse({
    required int status,
    required String body,
    Map<String, String> headers = const <String, String>{},
    String? fallbackRequestId,
  }) {
    final parsed = _parseBody(body);
    final code = parsed.code;
    final kind = _codeOverrides[code] ?? _kindForStatus(status);

    final message = parsed.message?.trim();
    final safe = (message != null && message.isNotEmpty && _isSafe(message))
        ? message
        : _defaultCopy[kind]!;

    final requestId = parsed.requestId ?? fallbackRequestId;
    // The raw body is diagnostic only and never reaches a widget.
    final debug = 'HTTP $status ${code ?? ''} ${_truncate(body)}';

    switch (kind) {
      case _Kind.auth:
        return AuthFailure(
            safeMessage: safe,
            code: code,
            requestId: requestId,
            debugDetail: debug);
      case _Kind.forbidden:
        return ForbiddenFailure(
            safeMessage: safe,
            code: code,
            requestId: requestId,
            debugDetail: debug);
      case _Kind.notFound:
        return NotFoundFailure(
            safeMessage: safe,
            code: code,
            requestId: requestId,
            debugDetail: debug);
      case _Kind.validation:
        return ValidationFailure(
          safeMessage: safe,
          fieldErrors: parsed.fieldErrors,
          code: code,
          requestId: requestId,
          debugDetail: debug,
        );
      case _Kind.stateConflict:
        return StateConflictFailure(
            safeMessage: safe,
            code: code,
            requestId: requestId,
            debugDetail: debug);
      case _Kind.idempotency:
        return IdempotencyConflictFailure(
            safeMessage: safe,
            code: code,
            requestId: requestId,
            debugDetail: debug);
      case _Kind.rateLimit:
        return RateLimitFailure(
          safeMessage: safe,
          retryAfter: _retryAfter(headers),
          code: code,
          requestId: requestId,
          debugDetail: debug,
        );
      case _Kind.retryable:
        return RetryableFailure(
            safeMessage: safe,
            code: code,
            requestId: requestId,
            debugDetail: debug);
      case _Kind.unknown:
        return UnknownFailure(
            safeMessage: safe,
            code: code,
            requestId: requestId,
            debugDetail: debug);
    }
  }

  /// Maps a thrown transport error — the request never produced a response.
  ApiFailure fromTransport(Object error, {String? requestId}) {
    if (error is ApiFailure) return error;
    final isKnownTransport =
        error is SocketException || error is TimeoutException || error is HttpException;
    return RetryableFailure(
      safeMessage: isKnownTransport
          ? 'No connection. Check your network and try again.'
          : _defaultCopy[_Kind.retryable]!,
      isTransport: true,
      requestId: requestId,
      debugDetail: error.runtimeType.toString(),
    );
  }

  _Kind _kindForStatus(int status) {
    if (status == 401) return _Kind.auth;
    if (status == 403) return _Kind.forbidden;
    if (status == 404) return _Kind.notFound;
    if (status == 400 || status == 415 || status == 422) {
      return _Kind.validation;
    }
    // 410 Gone is a state conflict: the OTP expired, the thing has moved on.
    if (status == 409 || status == 410) return _Kind.stateConflict;
    if (status == 429) return _Kind.rateLimit;
    if (status == 408 || status >= 500) return _Kind.retryable;
    return _Kind.unknown;
  }

  /// A message is renderable only if it looks like prose rather than a leaked
  /// internal. Cheap heuristics, applied because §21 forbids surfacing an
  /// exception and the legacy envelopes have historically carried raw ones.
  static bool _isSafe(String message) {
    if (message.length > 200) return false;
    const markers = <String>[
      'Exception',
      'Error:',
      'at Object.',
      'node_modules',
      'stack',
      'ECONNREFUSED',
      'SequelizeD',
      'select ',
      'SELECT ',
    ];
    for (final m in markers) {
      if (message.contains(m)) return false;
    }
    return true;
  }

  static Duration? _retryAfter(Map<String, String> headers) {
    final raw = headers['retry-after'] ?? headers['Retry-After'];
    if (raw == null) return null;
    final seconds = int.tryParse(raw.trim());
    return seconds == null ? null : Duration(seconds: seconds);
  }

  static String _truncate(String s) =>
      s.length <= 300 ? s : '${s.substring(0, 300)}…';

  /// Reads whichever of the three envelopes this body happens to be.
  static _ParsedError _parseBody(String body) {
    if (body.isEmpty) return const _ParsedError();
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return const _ParsedError();
    }
    if (decoded is! Map) return const _ParsedError();
    final map = Map<String, dynamic>.from(decoded);

    // v1: { error: { code, message, details?, requestId } }
    final err = map['error'];
    if (err is Map) {
      final e = Map<String, dynamic>.from(err);
      return _ParsedError(
        code: e['code'] as String?,
        message: e['message'] as String?,
        requestId: e['requestId'] as String?,
        fieldErrors: _fieldErrors(e['details']),
      );
    }
    // helpers/status.ts: { status: 'error', error: '<string>' }
    if (err is String) {
      return _ParsedError(message: err);
    }
    // utils/apiResponse.ts and the hand-built { success: false, message }
    final message = map['message'];
    return _ParsedError(
      message: message is String ? message : null,
      fieldErrors: _fieldErrors(map['errors'] ?? map['details']),
    );
  }

  static Map<String, String> _fieldErrors(Object? details) {
    if (details is! Map) return const <String, String>{};
    final out = <String, String>{};
    details.forEach((key, value) {
      if (key is! String) return;
      if (value is String) {
        out[key] = value;
      } else if (value is List && value.isNotEmpty && value.first is String) {
        out[key] = value.first as String;
      }
    });
    return out;
  }
}

enum _Kind {
  auth,
  forbidden,
  notFound,
  validation,
  stateConflict,
  idempotency,
  rateLimit,
  retryable,
  unknown,
}

class _ParsedError {
  const _ParsedError({
    this.code,
    this.message,
    this.requestId,
    this.fieldErrors = const <String, String>{},
  });

  final String? code;
  final String? message;
  final String? requestId;
  final Map<String, String> fieldErrors;
}
