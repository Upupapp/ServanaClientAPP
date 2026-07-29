import 'dart:math';

import 'package:client/common/data/backend/servana_api_client.dart';

/// Retry strategy for a specific operation class.
///
/// C20 hard rules encoded here:
/// - [paymentOnce] — one attempt only, never blind-retry.
/// - Mutations without a stable idempotency key must NOT use [bookingCreate].
class RetryPolicy {
  const RetryPolicy({
    required this.maxAttempts,
    required this.baseDelay,
    this.maxDelay = const Duration(seconds: 60),
    this.jitter = true,
  });

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final bool jitter;

  /// Returns true if [error] is a transient failure safe to retry.
  bool shouldRetry(Object error) {
    if (error is ServanaApiException) {
      return error.statusCode >= 500 ||
          error.statusCode == 408 ||
          error.statusCode == 429;
    }
    // Network-level errors (SocketException, TimeoutException, etc.)
    return true;
  }

  /// Exponential backoff with optional ±30 % jitter for attempt [n] (1-based).
  Duration delayFor(int n) {
    final exp = baseDelay * (1 << (n - 1).clamp(0, 30));
    final capped = exp < maxDelay ? exp : maxDelay;
    if (!jitter) return capped;
    final factor = 0.85 + Random().nextDouble() * 0.30;
    final ms = (capped.inMilliseconds * factor).round();
    return Duration(milliseconds: ms);
  }
}

/// Central registry of per-operation retry budgets.
///
/// SAFE TO RETRY: idempotent reads (GET) and idempotent mutations where a
/// stable [X-Idempotency-Key] header is sent.
///
/// DO NOT RETRY: payment initiation ([paymentOnce]), cancellations, and any
/// mutation where the result is unknown and no idempotency key was sent.
class RetryPolicyRegistry {
  RetryPolicyRegistry._();

  /// Read-only fetches — safe to retry freely.
  static const RetryPolicy query = RetryPolicy(
    maxAttempts: 3,
    baseDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 10),
  );

  /// Booking creation — ONLY with a stable [X-Idempotency-Key] header.
  static const RetryPolicy bookingCreate = RetryPolicy(
    maxAttempts: 2,
    baseDelay: Duration(seconds: 3),
    maxDelay: Duration(seconds: 10),
    jitter: false,
  );

  /// File / photo uploads.
  static const RetryPolicy upload = RetryPolicy(
    maxAttempts: 3,
    baseDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 30),
  );

  /// Payment session creation — one attempt only, never blind-retry.
  static const RetryPolicy paymentOnce = RetryPolicy(
    maxAttempts: 1,
    baseDelay: Duration.zero,
  );

  /// FCM token registration — low priority, generous backoff.
  static const RetryPolicy fcmRegistration = RetryPolicy(
    maxAttempts: 3,
    baseDelay: Duration(seconds: 5),
    maxDelay: Duration(seconds: 60),
  );
}
