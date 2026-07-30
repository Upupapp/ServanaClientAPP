import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/recovery/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RetryPolicy.shouldRetry', () {
    const policy = RetryPolicyRegistry.query;

    test('retries on 500 server error', () {
      expect(
          policy.shouldRetry(
              const ServanaApiException(statusCode: 500, body: '')),
          isTrue);
    });

    test('retries on 503', () {
      expect(
          policy.shouldRetry(
              const ServanaApiException(statusCode: 503, body: '')),
          isTrue);
    });

    test('retries on 408 timeout', () {
      expect(
          policy.shouldRetry(
              const ServanaApiException(statusCode: 408, body: '')),
          isTrue);
    });

    test('retries on 429 rate-limit', () {
      expect(
          policy.shouldRetry(
              const ServanaApiException(statusCode: 429, body: '')),
          isTrue);
    });

    test('does NOT retry on 400 bad request', () {
      expect(
          policy.shouldRetry(
              const ServanaApiException(statusCode: 400, body: '')),
          isFalse);
    });

    test('does NOT retry on 401 unauthorized', () {
      expect(
          policy.shouldRetry(
              const ServanaApiException(statusCode: 401, body: '')),
          isFalse);
    });

    test('does NOT retry on 404', () {
      expect(
          policy.shouldRetry(
              const ServanaApiException(statusCode: 404, body: '')),
          isFalse);
    });

    test('retries on generic Exception (network error)', () {
      expect(policy.shouldRetry(Exception('connection reset')), isTrue);
    });
  });

  group('RetryPolicy.delayFor', () {
    test('delay grows with attempt number', () {
      const policy = RetryPolicy(
        maxAttempts: 4,
        baseDelay: Duration(seconds: 1),
        jitter: false,
      );
      final d1 = policy.delayFor(1);
      final d2 = policy.delayFor(2);
      final d3 = policy.delayFor(3);
      expect(d2, greaterThan(d1));
      expect(d3, greaterThan(d2));
    });

    test('delay is capped at maxDelay', () {
      const policy = RetryPolicy(
        maxAttempts: 10,
        baseDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 5),
        jitter: false,
      );
      final d10 = policy.delayFor(10);
      expect(d10, lessThanOrEqualTo(const Duration(seconds: 5)));
    });

    test('paymentOnce has maxAttempts of 1', () {
      expect(RetryPolicyRegistry.paymentOnce.maxAttempts, 1);
    });

    test('query has maxAttempts of 3', () {
      expect(RetryPolicyRegistry.query.maxAttempts, 3);
    });

    test('bookingCreate has maxAttempts of 2', () {
      expect(RetryPolicyRegistry.bookingCreate.maxAttempts, 2);
    });
  });
}
