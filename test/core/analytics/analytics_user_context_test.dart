import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/analytics/domain/analytics_user_context.dart';

void main() {
  group('AnalyticsUserContext — ID derivation', () {
    test('empty input produces empty ID', () {
      expect(AnalyticsUserContext.deriveAnalyticsId(''), isEmpty);
    });

    test('produces 32-character hex string (16-byte fold)', () {
      final id = AnalyticsUserContext.deriveAnalyticsId('cust-uuid-12345');
      expect(id.length, 32);
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(id), true);
    });

    test('same input always produces same output (deterministic)', () {
      const raw = 'cust-abc-def-123';
      final id1 = AnalyticsUserContext.deriveAnalyticsId(raw);
      final id2 = AnalyticsUserContext.deriveAnalyticsId(raw);
      expect(id1, id2);
    });

    test('different inputs produce different IDs', () {
      final id1 = AnalyticsUserContext.deriveAnalyticsId('customer-aaa');
      final id2 = AnalyticsUserContext.deriveAnalyticsId('customer-bbb');
      expect(id1, isNot(id2));
    });

    test('UUID-format input is transformed', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final id = AnalyticsUserContext.deriveAnalyticsId(uuid);
      // Must not equal raw UUID (must be transformed)
      expect(id, isNot(contains(uuid)));
      expect(id.length, 32);
    });

    test('raw ID is NOT present in derived ID', () {
      const rawId = 'cust12345678';
      final id = AnalyticsUserContext.deriveAnalyticsId(rawId);
      expect(id.contains(rawId), false);
    });
  });

  group('AnalyticsUserContext — profile band', () {
    test('0 score → 0 band',
        () => expect(AnalyticsUserContext.profileBandFor(0), '0'));
    test('25 score → 1-25 band',
        () => expect(AnalyticsUserContext.profileBandFor(25), '1-25'));
    test('26 score → 26-50 band',
        () => expect(AnalyticsUserContext.profileBandFor(26), '26-50'));
    test('100 score → 100 band',
        () => expect(AnalyticsUserContext.profileBandFor(100), '100'));
    test('99 score → 76-99 band',
        () => expect(AnalyticsUserContext.profileBandFor(99), '76-99'));
  });

  group('AnalyticsUserContext — guest constant', () {
    test('guest has empty analytics ID',
        () => expect(AnalyticsUserContext.guest.analyticsId, isEmpty));
    test('guest accountState is guest',
        () => expect(AnalyticsUserContext.guest.accountState, 'guest'));
  });
}
