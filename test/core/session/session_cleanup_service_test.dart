import 'package:client/core/session/session_cleanup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = SessionCleanupService();

  group('isolation', () {
    test('one failing step does not skip the steps after it', () async {
      // This is the whole reason the sequence moved out of the BLoC: the old
      // code grouped fifteen clears into a single try, so a throw in the
      // second silently skipped thirteen — and every one of those clears is
      // there because something leaked across accounts on a shared device.
      final ran = <String>[];
      final report = await service.run(<CleanupStep>[
        CleanupStep('first', () async => ran.add('first')),
        CleanupStep('explodes', () async => throw StateError('boom')),
        CleanupStep('third', () async => ran.add('third')),
        CleanupStep('fourth', () async => ran.add('fourth')),
      ]);

      expect(ran, <String>['first', 'third', 'fourth']);
      expect(report.completed, <String>['first', 'third', 'fourth']);
      expect(report.failed.keys, <String>['explodes']);
      expect(report.isClean, isFalse);
    });

    test('never throws, however badly the device is behaving', () async {
      // A logout the customer asked for must complete even if everything
      // fails; the alternative is trapping them in a signed-in app.
      final report = await service.run(<CleanupStep>[
        CleanupStep('a', () async => throw StateError('a')),
        CleanupStep('b', () async => throw Exception('b')),
      ]);
      expect(report.completed, isEmpty);
      expect(report.failed.length, 2);
    });

    test('runs steps in the declared order', () async {
      final order = <String>[];
      await service.run(<CleanupStep>[
        CleanupStep('1', () async => order.add('1')),
        CleanupStep('2', () async => order.add('2')),
        CleanupStep('3', () async => order.add('3')),
      ]);
      expect(order, <String>['1', '2', '3']);
    });

    test('awaits async steps rather than firing and forgetting', () async {
      var finished = false;
      await service.run(<CleanupStep>[
        CleanupStep('slow', () async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          finished = true;
        }),
      ]);
      expect(finished, isTrue);
    });
  });

  group('auditability', () {
    test('a clean run says so', () async {
      final report = await service.run(<CleanupStep>[
        CleanupStep('a', () async {}),
      ]);
      expect(report.isClean, isTrue);
      expect(report.toString(), contains('clean'));
    });

    test('a partial run names the failed steps and not their payloads',
        () async {
      // Step names are safe to log; error payloads can carry account detail.
      final report = await service.run(<CleanupStep>[
        CleanupStep('ok', () async {}),
        CleanupStep('drafts', () async => throw StateError('uid=cust_123')),
      ]);
      expect(report.toString(), contains('drafts'));
      expect(report.toString(), isNot(contains('cust_123')));
    });

    test('an empty step list is a clean run', () async {
      final report = await service.run(const <CleanupStep>[]);
      expect(report.isClean, isTrue);
      expect(report.completed, isEmpty);
    });
  });
}
