import 'package:client/core/recovery/operation_journal.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  JournaledOperation makeOp(String id,
      {String uid = 'uid1', bool old = false}) {
    return JournaledOperation(
      id: id,
      type: 'booking.create',
      customerUid: uid,
      payload: {'serviceId': '1'},
      startedAt: old
          ? DateTime.now().subtract(const Duration(hours: 25))
          : DateTime.now(),
      idempotencyKey: 'idem-$id',
    );
  }

  group('OperationJournal', () {
    test('load returns empty list when nothing saved', () async {
      final journal = OperationJournal();
      expect(await journal.load('uid1'), isEmpty);
    });

    test('record and load round-trip', () async {
      final journal = OperationJournal();
      await journal.record(makeOp('op-1'));
      final ops = await journal.load('uid1');
      expect(ops, hasLength(1));
      expect(ops.first.id, 'op-1');
      expect(ops.first.idempotencyKey, 'idem-op-1');
    });

    test('record replaces existing operation with same id', () async {
      final journal = OperationJournal();
      await journal.record(makeOp('op-1'));
      final updated = JournaledOperation(
        id: 'op-1',
        type: 'booking.create',
        customerUid: 'uid1',
        payload: {'serviceId': '2'},
        startedAt: DateTime.now(),
      );
      await journal.record(updated);
      final ops = await journal.load('uid1');
      expect(ops, hasLength(1));
      expect(ops.first.payload['serviceId'], '2');
    });

    test('resolve removes specific operation', () async {
      final journal = OperationJournal();
      await journal.record(makeOp('op-1'));
      await journal.record(makeOp('op-2'));
      await journal.resolve('uid1', 'op-1');
      final ops = await journal.load('uid1');
      expect(ops, hasLength(1));
      expect(ops.first.id, 'op-2');
    });

    test('expired operations are pruned on load', () async {
      final journal = OperationJournal();
      await journal.record(makeOp('op-old', old: true));
      await journal.record(makeOp('op-new'));
      final ops = await journal.load('uid1');
      expect(ops, hasLength(1));
      expect(ops.first.id, 'op-new');
    });

    test('clearForAccount removes all ops for UID', () async {
      final journal = OperationJournal();
      await journal.record(makeOp('op-1'));
      await journal.record(makeOp('op-2'));
      await journal.clearForAccount('uid1');
      expect(await journal.load('uid1'), isEmpty);
    });

    test('clearForAccount does not affect other UIDs', () async {
      final journal = OperationJournal();
      await journal.record(makeOp('op-A', uid: 'uid-A'));
      await journal.record(makeOp('op-B', uid: 'uid-B'));
      await journal.clearForAccount('uid-A');
      expect(await journal.load('uid-B'), hasLength(1));
    });

    test('operations are isolated per UID', () async {
      final journal = OperationJournal();
      await journal.record(makeOp('op-1', uid: 'uid-X'));
      expect(await journal.load('uid-Y'), isEmpty);
    });
  });
}
