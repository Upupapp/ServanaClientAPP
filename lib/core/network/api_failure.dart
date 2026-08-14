/// The one failure vocabulary the mobile app reasons about.
///
/// ## Why a sealed class rather than status codes
///
/// Before this, every caller of [ServanaApiClient] received a
/// `ServanaApiException(statusCode, body)` and decided for itself what a 409
/// meant. That put backend wire details — status numbers and raw response
/// bodies — inside controllers and, in a few places, inside widgets. Two
/// consequences: a backend that changes 400 to 422 for the same condition
/// silently changes app behaviour, and a raw body can reach the screen.
///
/// [ApiFailure] is the boundary. Everything below it speaks HTTP; everything
/// above it speaks these nine cases and nothing else. `switch` over a sealed
/// class is exhaustive, so adding a case here is a compile error at every
/// call site that has to care — which is the point.
///
/// ## The nine cases are a product decision, not a transport one
///
/// They are the distinct *recoveries* a customer has, not the distinct things
/// that can go wrong on a server:
///
///   auth                 → sign in again
///   forbidden            → you cannot do this; signing in again will not help
///   notFound             → the thing is gone; go back
///   validation           → fix the input and resubmit
///   stateConflict        → the world moved; refresh and look again
///   idempotencyConflict  → this already happened; do not send it twice
///   rateLimit            → wait, then try again
///   retryable            → not your fault; try again now or shortly
///   unknown              → we do not know; fail closed and report
///
/// ## Never the raw body
///
/// [safeMessage] is the only string any UI may render. It is either a message
/// the backend explicitly marked as customer-safe or one of our own. Raw
/// bodies, exception text and stack traces are kept in [debugDetail], which is
/// excluded from [toString] and is intended for logs and Crashlytics only.
library;

/// A correlation handle for one failed request.
///
/// The v1 envelope returns `error.requestId`; for legacy responses we fall
/// back to the client-generated `X-Request-Id` we sent. Either way support can
/// join a customer report to a server log line without the customer having to
/// describe what happened.
typedef RequestId = String;

sealed class ApiFailure implements Exception {
  const ApiFailure({
    required this.safeMessage,
    this.code,
    this.requestId,
    this.debugDetail,
  });

  /// The ONLY string a widget may display.
  final String safeMessage;

  /// Canonical backend code (`BOOKING_TERMINAL`, `RATE_LIMITED`, …) when the
  /// response carried one. Null for transport-level failures.
  final String? code;

  /// Correlation id for support and log joining.
  final RequestId? requestId;

  /// Diagnostic text for logs only. Never rendered.
  final String? debugDetail;

  /// Whether a caller may retry this operation *at all*.
  ///
  /// Retrying is refused by default. Only the two cases that are genuinely
  /// safe to repeat say yes — and [RateLimitFailure] says yes only after
  /// [RateLimitFailure.retryAfter].
  bool get isRetryable => false;

  /// Whether this failure means the session is no longer usable.
  bool get invalidatesSession => false;

  @override
  String toString() => '$runtimeType($code)';
}

/// 401 — the caller is not authenticated, or the token expired or was revoked.
class AuthFailure extends ApiFailure {
  const AuthFailure({
    required super.safeMessage,
    super.code,
    super.requestId,
    super.debugDetail,
  });

  @override
  bool get invalidatesSession => true;
}

/// 403 — authenticated, and still not allowed. Signing in again will not help.
class ForbiddenFailure extends ApiFailure {
  const ForbiddenFailure({
    required super.safeMessage,
    super.code,
    super.requestId,
    super.debugDetail,
  });
}

/// 404 — the resource does not exist, or is not visible to this caller.
class NotFoundFailure extends ApiFailure {
  const NotFoundFailure({
    required super.safeMessage,
    super.code,
    super.requestId,
    super.debugDetail,
  });
}

/// 400 / 415 / 422 — the request was understood and rejected.
class ValidationFailure extends ApiFailure {
  const ValidationFailure({
    required super.safeMessage,
    this.fieldErrors = const <String, String>{},
    super.code,
    super.requestId,
    super.debugDetail,
  });

  /// Field-keyed messages, when the backend supplied `error.details`. Safe to
  /// render beside the offending input.
  final Map<String, String> fieldErrors;
}

/// 409 / 410 — the operation is legal in principle and illegal right now.
///
/// The booking already moved on, the OTP expired, the address limit is
/// reached. The recovery is always "refresh and look again", never "retry".
class StateConflictFailure extends ApiFailure {
  const StateConflictFailure({
    required super.safeMessage,
    super.code,
    super.requestId,
    super.debugDetail,
  });
}

/// 409 `IDEMPOTENCY_KEY_REUSED` — this exact request already succeeded.
///
/// Split out from [StateConflictFailure] because the recovery is the opposite:
/// a state conflict means "look again, it may not have happened", and this
/// means "it definitely happened, do not send it again". Conflating them is
/// how a customer ends up with two bookings.
class IdempotencyConflictFailure extends ApiFailure {
  const IdempotencyConflictFailure({
    required super.safeMessage,
    super.code,
    super.requestId,
    super.debugDetail,
  });
}

/// 429 — too many requests, or an OTP cooldown.
class RateLimitFailure extends ApiFailure {
  const RateLimitFailure({
    required super.safeMessage,
    this.retryAfter,
    super.code,
    super.requestId,
    super.debugDetail,
  });

  /// From the `Retry-After` header when present. Null means "unknown, back off
  /// with the caller's own policy".
  final Duration? retryAfter;

  @override
  bool get isRetryable => true;
}

/// 408 / 5xx / socket / timeout — not the caller's fault.
class RetryableFailure extends ApiFailure {
  const RetryableFailure({
    required super.safeMessage,
    this.isTransport = false,
    super.code,
    super.requestId,
    super.debugDetail,
  });

  /// True when the request never reached the server (DNS, socket, timeout).
  /// A transport failure is safe to retry even for a non-idempotent mutation
  /// *only* if the caller sent an idempotency key — see [RetryPolicyRegistry].
  final bool isTransport;

  @override
  bool get isRetryable => true;
}

/// Anything we could not classify. Fails closed: not retryable.
class UnknownFailure extends ApiFailure {
  const UnknownFailure({
    required super.safeMessage,
    super.code,
    super.requestId,
    super.debugDetail,
  });
}
