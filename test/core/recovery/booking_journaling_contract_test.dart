/// Contract tests for the booking.create journaling pattern.
///
/// Before an API call is made, the store records a JournaledOperation so
/// that a process kill during the network request leaves a reconcilable
/// entry. After the backend confirms, the entry is resolved (removed).
/// These tests verify that contract at the OperationJournal layer.
library;

import 'package:client/core/recovery/operation_journal.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  const uid = 'customer-123';

  JournaledOperation makeBookingOp({
    required String opId,
    required String idempotencyKey,
    String category = 'aircon',
    String paymentMethod = 'online_banking',
  }) =>
      JournaledOperation(
        id: opId,
        type: 'booking.create',
        customerUid: uid,
        payload: {'category': category, 'paymentMethod': paymentMethod},
        startedAt: DateTime.now(),
        idempotencyKey: idempotencyKey,
      );

  group('Booking journaling contract', () {
    // ── Pre-call record ───────────────────────────────────────────────────

    test('entry is readable immediately after record() — simulates process kill', () async {
      final journal = OperationJournal();
      await journal.record(makeBookingOp(
        opId: 'op-abc',
        idempotencyKey: 'idem-abc',
      ));

      final ops = await journal.load(uid);
      expect(ops, hasLength(1));
      expect(ops.first.type, 'booking.create');
      expect(ops.first.idempotencyKey, 'idem-abc');
    });

    test('payload contains category and paymentMethod fields', () async {
      final journal = OperationJournal();
      await journal.record(makeBookingOp(
        opId: 'op-1',
        idempotencyKey: 'idem-1',
        category: 'beauty_wellness',
        paymentMethod: 'gcash',
      ));

      final op = (await journal.load(uid)).first;
      expect(op.payload['category'], 'beauty_wellness');
      expect(op.payload['paymentMethod'], 'gcash');
    });

    test('idempotencyKey is preserved for retry reconciliation', () async {
      final journal = OperationJournal();
      const idemKey = 'stable-key-for-retry';
      await journal.record(makeBookingOp(
        opId: 'op-retry',
        idempotencyKey: idemKey,
      ));

      // Simulate retry: record same op-id again with same idempotency key.
      await journal.record(makeBookingOp(
        opId: 'op-retry',
        idempotencyKey: idemKey,
      ));

      final ops = await journal.load(uid);
      expect(ops, hasLength(1), reason: 'duplicate op-id must be deduplicated');
      expect(ops.first.idempotencyKey, idemKey);
    });

    // ── Post-confirmation resolve ──────────────────────────────────────────

    test('resolve() removes the entry after backend confirmation', () async {
      final journal = OperationJournal();
      await journal.record(makeBookingOp(
        opId: 'op-confirmed',
        idempotencyKey: 'idem-confirmed',
      ));

      await journal.resolve(uid, 'op-confirmed');

      expect(await journal.load(uid), isEmpty);
    });

    test('resolve() on a non-existent id is a safe no-op', () async {
      final journal = OperationJournal();
      await journal.record(makeBookingOp(opId: 'op-A', idempotencyKey: 'k-A'));

      await journal.resolve(uid, 'op-DOES-NOT-EXIST');

      // op-A must still be present.
      expect(await journal.load(uid), hasLength(1));
    });

    // ── Logout isolation ─────────────────────────────────────────────────

    test('clearForAccount() on logout removes all pending booking ops', () async {
      final journal = OperationJournal();
      await journal.record(makeBookingOp(opId: 'op-1', idempotencyKey: 'k-1'));
      await journal.record(makeBookingOp(opId: 'op-2', idempotencyKey: 'k-2'));

      await journal.clearForAccount(uid);

      expect(await journal.load(uid), isEmpty);
    });

    test('pending ops of a different customer are unaffected by logout', () async {
      final journal = OperationJournal();
      await journal.record(makeBookingOp(opId: 'op-mine', idempotencyKey: 'k-m'));

      const otherUid = 'other-customer-456';
      await journal.record(JournaledOperation(
        id: 'op-other',
        type: 'booking.create',
        customerUid: otherUid,
        payload: {'category': 'aircon', 'paymentMethod': 'gcash'},
        startedAt: DateTime.now(),
        idempotencyKey: 'k-other',
      ));

      await journal.clearForAccount(uid);

      expect(await journal.load(uid), isEmpty);
      expect(await journal.load(otherUid), hasLength(1));
    });

    // ── Expiry ────────────────────────────────────────────────────────────

    test('stale booking ops older than 24 h are pruned on load', () async {
      final journal = OperationJournal();
      await journal.record(JournaledOperation(
        id: 'op-stale',
        type: 'booking.create',
        customerUid: uid,
        payload: {'category': 'aircon', 'paymentMethod': 'gcash'},
        startedAt: DateTime.now().subtract(const Duration(hours: 25)),
        idempotencyKey: 'k-stale',
      ));

      await journal.record(makeBookingOp(opId: 'op-fresh', idempotencyKey: 'k-fresh'));

      final ops = await journal.load(uid);
      expect(ops, hasLength(1));
      expect(ops.first.id, 'op-fresh');
    });
  });
}
