/// Customer-facing copy for authentication failures, driven by CODE.
///
/// ## What this replaces
///
/// `ErrorMessageMapper` classifies a failure by substring-matching the
/// backend's prose — `contains('invalid')`, `contains('verify')`,
/// `contains('too many')`. That works until the backend rewords a message, at
/// which point a credential error silently becomes a generic one and the
/// screen stops telling the customer what to do. It also cannot distinguish
/// conditions that share vocabulary: OTP_INVALID and OTP_EXPIRED both read as
/// "invalid code", and they have different recoveries.
///
/// This maps the canonical `ApiFailure.code` instead, falling back to the
/// failure CLASS when no code is present — so a legacy response with no code
/// still lands somewhere sensible, and a canonical one lands exactly.
///
/// `ErrorMessageMapper` is deliberately left in place and untouched: it is
/// still the path for the legacy flows this tab did not rewire, and removing
/// it would be a change with no user-visible benefit.
///
/// ## The six the Master Command names
///
/// INVALID_CREDENTIALS, ACCOUNT_UNVERIFIED, OTP_INVALID, OTP_EXPIRED,
/// RATE_LIMITED and RESET_TOKEN_INVALID each get their own recovery sentence,
/// because each has a different next action: retype, verify, retype, resend,
/// wait, restart.
library;

import 'package:client/core/network/api_failure.dart';

/// What the screen should offer the customer next.
///
/// The copy says what happened; this says what the UI should DO about it, so
/// two screens showing the same failure cannot disagree about whether a
/// "Resend" button belongs on it.
enum AuthRecovery {
  /// Let them correct the input and submit again.
  retryInput,

  /// Send them to the verification screen.
  verifyAccount,

  /// Offer a fresh code.
  resendCode,

  /// Make them wait; show a countdown if one is known.
  wait,

  /// Start the flow over from the beginning.
  restartFlow,

  /// Offer a plain retry — nothing the customer did was wrong.
  retryRequest,

  /// Send them back to sign-in.
  reauthenticate,
}

class AuthFailureCopy {
  const AuthFailureCopy({
    required this.message,
    required this.recovery,
    this.retryAfter,
  });

  /// Safe to render. Never contains backend prose that failed the safety check.
  final String message;
  final AuthRecovery recovery;

  /// Present only for rate limits that told us how long to wait.
  final Duration? retryAfter;

  /// Maps a canonical failure to copy and a recovery.
  static AuthFailureCopy of(ApiFailure failure) {
    switch (failure.code) {
      case 'INVALID_CREDENTIALS':
        return const AuthFailureCopy(
          message: 'The email or password is incorrect.',
          recovery: AuthRecovery.retryInput,
        );

      case 'ACCOUNT_UNVERIFIED':
        return const AuthFailureCopy(
          message: 'Please verify your account before signing in.',
          recovery: AuthRecovery.verifyAccount,
        );

      case 'ACCOUNT_DISABLED':
        return const AuthFailureCopy(
          message: 'This account has been disabled. Please contact support.',
          recovery: AuthRecovery.restartFlow,
        );

      case 'OTP_INVALID':
      case 'BOOKING_OTP_INVALID':
        return const AuthFailureCopy(
          message: "That code isn't right. Please check it and try again.",
          recovery: AuthRecovery.retryInput,
        );

      case 'OTP_EXPIRED':
      case 'BOOKING_OTP_EXPIRED':
        return const AuthFailureCopy(
          message: 'That code has expired. Request a new one.',
          recovery: AuthRecovery.resendCode,
        );

      case 'RESET_TOKEN_INVALID':
        return const AuthFailureCopy(
          message: 'This reset link is no longer valid. Please start again.',
          recovery: AuthRecovery.restartFlow,
        );

      case 'WEAK_PASSWORD':
        return const AuthFailureCopy(
          message: 'Please choose a stronger password.',
          recovery: AuthRecovery.retryInput,
        );

      case 'RATE_LIMITED':
      case 'BOOKING_OTP_RESEND_COOLDOWN':
      case 'BOOKING_OTP_RESEND_LIMIT':
      case 'BOOKING_OTP_ATTEMPTS_EXHAUSTED':
        return AuthFailureCopy(
          message: 'Too many attempts. Please wait a moment and try again.',
          recovery: AuthRecovery.wait,
          retryAfter: failure is RateLimitFailure ? failure.retryAfter : null,
        );
    }

    // No code, or a code this screen has no specific advice for. Fall back to
    // the failure CLASS, which is always present.
    return switch (failure) {
      AuthFailure() => const AuthFailureCopy(
          message: 'Your session has expired. Please sign in again.',
          recovery: AuthRecovery.reauthenticate,
        ),
      ForbiddenFailure() => const AuthFailureCopy(
          message: "You don't have access to this.",
          recovery: AuthRecovery.restartFlow,
        ),
      NotFoundFailure() => const AuthFailureCopy(
          message: 'We could not find an account for those details.',
          recovery: AuthRecovery.retryInput,
        ),
      ValidationFailure() => const AuthFailureCopy(
          message: 'Please check the details and try again.',
          recovery: AuthRecovery.retryInput,
        ),
      StateConflictFailure() => const AuthFailureCopy(
          message: 'That has already changed. Please start again.',
          recovery: AuthRecovery.restartFlow,
        ),
      IdempotencyConflictFailure() => const AuthFailureCopy(
          message: 'That was already submitted.',
          recovery: AuthRecovery.restartFlow,
        ),
      RateLimitFailure(retryAfter: final after) => AuthFailureCopy(
          message: 'Too many attempts. Please wait a moment and try again.',
          recovery: AuthRecovery.wait,
          retryAfter: after,
        ),
      RetryableFailure(isTransport: final transport) => AuthFailureCopy(
          message: transport
              ? 'You appear to be offline. Check your connection and try again.'
              : "Something went wrong on our end. Please try again.",
          recovery: AuthRecovery.retryRequest,
        ),
      UnknownFailure() => const AuthFailureCopy(
          message: 'Something went wrong. Please try again.',
          recovery: AuthRecovery.retryRequest,
        ),
    };
  }
}
