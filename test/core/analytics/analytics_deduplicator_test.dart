import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/analytics/data/analytics_deduplicator.dart';

void main() {
  group('AnalyticsDeduplicator', () {
    test('first call returns false (does not suppress)', () {
      final dedup = AnalyticsDeduplicator();
      expect(dedup.shouldSuppress('screen_view:home'), false);
    });

    test('second immediate call returns true (suppresses)', () {
      final dedup = AnalyticsDeduplicator();
      dedup.shouldSuppress('screen_view:home');
      expect(dedup.shouldSuppress('screen_view:home'), true);
    });

    test('different keys do not suppress each other', () {
      final dedup = AnalyticsDeduplicator();
      expect(dedup.shouldSuppress('screen_view:home'), false);
      expect(dedup.shouldSuppress('screen_view:bookings'), false);
    });

    test('after window expires, key is no longer suppressed', () async {
      final dedup = AnalyticsDeduplicator(window: const Duration(milliseconds: 50));
      dedup.shouldSuppress('key1');
      expect(dedup.shouldSuppress('key1'), true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(dedup.shouldSuppress('key1'), false);
    });

    test('clear() resets all suppression state', () {
      final dedup = AnalyticsDeduplicator();
      dedup.shouldSuppress('key1');
      dedup.clear();
      expect(dedup.shouldSuppress('key1'), false);
    });

    test('multiple distinct keys accumulate independently', () {
      final dedup = AnalyticsDeduplicator();
      expect(dedup.shouldSuppress('a'), false);
      expect(dedup.shouldSuppress('b'), false);
      expect(dedup.shouldSuppress('c'), false);
      expect(dedup.shouldSuppress('a'), true);
      expect(dedup.shouldSuppress('b'), true);
      expect(dedup.shouldSuppress('c'), true);
    });
  });
}
