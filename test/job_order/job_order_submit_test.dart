/// A rejected job order must not be reported as submitted.
///
/// The bug: `onJoRequested` called `repo.insertJobOrder(...)` without `await`
/// and never read its boolean. In a release build the Backend implementation
/// is HttpBackend, whose `insertJobOrder` returns false unconditionally — so
/// the submission always failed, and the customer was always shown
/// "Job order submitted.", the screen popped, and a placeholder booking
/// appeared that the server had never received.
///
/// These assert the contract that makes that impossible: the result is
/// awaited, a false result produces a failure state, and no local booking is
/// written unless the server accepted the order.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:client/modules/job_order/presentation/blocs/job_order_states.dart';

void main() {
  group('FailedJOState', () {
    test('exists and carries a message the UI can show', () {
      const s = FailedJOState('nope');
      expect(s, isA<JOState>());
      expect(s.message, 'nope');
    });

    test('is distinct from DoneJOState', () {
      // The whole defect was a failure arriving as DoneJOState. If these ever
      // compare equal, the screen's `state is DoneJOState` branch would fire
      // on a failure again.
      const failed = FailedJOState('x');
      const done = DoneJOState('x');
      expect(failed.props, isNot(equals(done.props)));
    });

    test('two failures with different messages are different states', () {
      // Bloc drops a state equal to the current one. Without the message in
      // props, a second distinct failure would not re-notify the listener and
      // the customer would see no dialog on retry.
      expect(
        const FailedJOState('a').props,
        isNot(equals(const FailedJOState('b').props)),
      );
    });
  });

  group('the submit path is written so a rejection cannot read as success', () {
    // Source-level: the defect was the ABSENCE of an await and a check, which
    // no runtime assertion can observe without a full DI harness — the handler
    // reaches for HomeStore through GetIt partway through.
    final bloc = File(
      'lib/modules/job_order/presentation/blocs/job_order_bloc.dart',
    ).readAsStringSync();

    final handler = bloc.substring(bloc.indexOf('onJoRequested'));

    test('insertJobOrder is awaited', () {
      expect(handler, contains('await repo.insertJobOrder('));
    });

    test('a rejection is handled before the optimistic placeholder is written',
        () {
      final failIdx = handler.indexOf('FailedJOState');
      final addIdx = handler.indexOf('store.addBooking(');
      expect(failIdx, greaterThan(-1), reason: 'no failure state emitted');
      expect(addIdx, greaterThan(-1), reason: 'placeholder write not found');
      expect(failIdx, lessThan(addIdx),
          reason: 'the ghost booking still lands before the failure is seen');
    });

    test('the handler returns early rather than falling through', () {
      final between = handler.substring(
        handler.indexOf('FailedJOState'),
        handler.indexOf('store.addBooking('),
      );
      expect(between, contains('return;'));
    });
  });
}
