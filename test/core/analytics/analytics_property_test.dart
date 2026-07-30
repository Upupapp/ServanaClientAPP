import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/analytics/domain/analytics_property.dart';

void main() {
  group('AmountBandValues.forAmount', () {
    test('0 → band0',
        () => expect(AmountBandValues.forAmount(0), AmountBandValues.band0));
    test(
        '1 → band1to500',
        () =>
            expect(AmountBandValues.forAmount(1), AmountBandValues.band1to500));
    test(
        '500 → band1to500',
        () => expect(
            AmountBandValues.forAmount(500), AmountBandValues.band1to500));
    test(
        '501 → band501to1000',
        () => expect(
            AmountBandValues.forAmount(501), AmountBandValues.band501to1000));
    test(
        '1000 → band501to1000',
        () => expect(
            AmountBandValues.forAmount(1000), AmountBandValues.band501to1000));
    test(
        '5001 → band5001plus',
        () => expect(
            AmountBandValues.forAmount(5001), AmountBandValues.band5001plus));
    test('negative → band0',
        () => expect(AmountBandValues.forAmount(-1), AmountBandValues.band0));
  });

  group('CountBucketValues.forCount', () {
    test('0 → 0', () => expect(CountBucketValues.forCount(0), '0'));
    test('1 → 1', () => expect(CountBucketValues.forCount(1), '1'));
    test('2 → 2-3', () => expect(CountBucketValues.forCount(2), '2-3'));
    test('3 → 2-3', () => expect(CountBucketValues.forCount(3), '2-3'));
    test('4 → 4-5', () => expect(CountBucketValues.forCount(4), '4-5'));
    test('5 → 4-5', () => expect(CountBucketValues.forCount(5), '4-5'));
    test('6 → 6-10', () => expect(CountBucketValues.forCount(6), '6-10'));
    test('11 → 10+', () => expect(CountBucketValues.forCount(11), '10+'));
  });

  group('LatencyBucketValues.forMillis', () {
    test('0ms → <500ms',
        () => expect(LatencyBucketValues.forMillis(0), '<500ms'));
    test('499ms → <500ms',
        () => expect(LatencyBucketValues.forMillis(499), '<500ms'));
    test('500ms → 500-999ms',
        () => expect(LatencyBucketValues.forMillis(500), '500-999ms'));
    test('1000ms → 1-2s',
        () => expect(LatencyBucketValues.forMillis(1000), '1-2s'));
    test('5000ms → 5s+',
        () => expect(LatencyBucketValues.forMillis(5000), '5s+'));
    test('10000ms → 5s+',
        () => expect(LatencyBucketValues.forMillis(10000), '5s+'));
  });

  group('Enum value stability', () {
    test('AuthMethodValues are stable strings', () {
      expect(AuthMethodValues.email, 'email');
      expect(AuthMethodValues.google, 'google');
      expect(AuthMethodValues.facebook, 'facebook');
    });

    test('FailureCodeValues are stable strings', () {
      expect(FailureCodeValues.networkError, 'network_error');
      expect(FailureCodeValues.invalidCredentials, 'invalid_credentials');
      expect(FailureCodeValues.unknown, 'unknown');
    });

    test('ResultValues are stable strings', () {
      expect(ResultValues.success, 'success');
      expect(ResultValues.failure, 'failure');
    });
  });
}
