import 'package:client/common/services/assignment_polling_service.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssignmentPollResult', () {
    test('isAssigned requires non-empty workerUid AND assigned/confirmed status',
        () {
      expect(
        const AssignmentPollResult(
          status: BookingStatus.assigned,
          workerUid: 'uid-123',
        ).isAssigned,
        isTrue,
      );
      expect(
        const AssignmentPollResult(
          status: BookingStatus.confirmed,
          workerUid: 'uid-123',
        ).isAssigned,
        isTrue,
      );
    });

    test('isAssigned is false when workerUid is null', () {
      expect(
        const AssignmentPollResult(status: BookingStatus.assigned).isAssigned,
        isFalse,
      );
    });

    test('isAssigned is false when workerUid is empty string', () {
      expect(
        const AssignmentPollResult(
          status: BookingStatus.assigned,
          workerUid: '',
        ).isAssigned,
        isFalse,
      );
    });

    test('isAssigned is false for non-assignment statuses even with workerUid',
        () {
      for (final status in BookingStatus.values) {
        if (status == BookingStatus.assigned ||
            status == BookingStatus.confirmed) {
          continue;
        }
        expect(
          AssignmentPollResult(status: status, workerUid: 'uid').isAssigned,
          isFalse,
          reason: 'Expected isAssigned=false for $status',
        );
      }
    });
  });

  group('AssignmentPollingService lifecycle', () {
    test('isPolling is false before start', () {
      final svc = AssignmentPollingService();
      expect(svc.isPolling, isFalse);
      svc.dispose();
    });

    test('stop() is safe to call before start', () {
      final svc = AssignmentPollingService();
      expect(() => svc.stop(), returnsNormally);
      svc.dispose();
    });

    test('dispose() is safe to call multiple times', () {
      final svc = AssignmentPollingService();
      expect(() {
        svc.dispose();
        svc.dispose();
      }, returnsNormally);
    });

    test('start() is a no-op after dispose', () {
      final svc = AssignmentPollingService();
      svc.dispose();
      var callCount = 0;
      // Should not throw; onUpdate must never fire because _disposed=true
      // causes the immediate _poll() call to short-circuit.
      svc.start(
        bookingId: 999,
        onUpdate: (_) => callCount++,
      );
      expect(svc.isPolling, isFalse);
      expect(callCount, 0);
    });

    test('double start() while disposed does not throw', () {
      final svc = AssignmentPollingService();
      svc.dispose();
      expect(() => svc.start(bookingId: 1, onUpdate: (_) {}), returnsNormally);
    });
  });
}
