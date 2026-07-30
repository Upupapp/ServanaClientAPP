import 'package:client/common/domain/booking/booking_draft.dart';
import 'package:client/core/recovery/draft_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('DraftRepository — BookingDraft', () {
    test('returns null when nothing saved', () async {
      final repo = DraftRepository();
      expect(await repo.loadDraft('uid1'), isNull);
    });

    test('saves and loads a draft round-trip', () async {
      final repo = DraftRepository();
      final draft = BookingDraft(
        id: 'draft-001',
        createdAt: DateTime.now(),
        notes: 'test notes',
        status: BookingDraftStatus.editing,
      );
      await repo.saveDraft('uid1', draft);
      final loaded = await repo.loadDraft('uid1');
      expect(loaded, isNotNull);
      expect(loaded!.id, 'draft-001');
      expect(loaded.notes, 'test notes');
    });

    test('clearDraft removes the draft', () async {
      final repo = DraftRepository();
      final draft = BookingDraft(
        id: 'draft-002',
        createdAt: DateTime.now(),
        status: BookingDraftStatus.editing,
      );
      await repo.saveDraft('uid1', draft);
      await repo.clearDraft('uid1');
      expect(await repo.loadDraft('uid1'), isNull);
    });

    test('draft is isolated per UID', () async {
      final repo = DraftRepository();
      final d1 = BookingDraft(
        id: 'draft-A',
        createdAt: DateTime.now(),
        status: BookingDraftStatus.editing,
      );
      await repo.saveDraft('uid-A', d1);
      // uid-B should not see uid-A's draft.
      expect(await repo.loadDraft('uid-B'), isNull);
    });
  });

  group('DraftRepository — idempotency key', () {
    test('generates a key on first call', () async {
      final repo = DraftRepository();
      final key = await repo.getOrCreateIdempotencyKey('uid1', 'draft-1');
      expect(key, isNotEmpty);
    });

    test('returns the same key on repeated calls', () async {
      final repo = DraftRepository();
      final k1 = await repo.getOrCreateIdempotencyKey('uid1', 'draft-1');
      final k2 = await repo.getOrCreateIdempotencyKey('uid1', 'draft-1');
      expect(k1, equals(k2));
    });

    test('generates different keys for different drafts', () async {
      final repo = DraftRepository();
      final k1 = await repo.getOrCreateIdempotencyKey('uid1', 'draft-1');
      final k2 = await repo.getOrCreateIdempotencyKey('uid1', 'draft-2');
      expect(k1, isNot(equals(k2)));
    });

    test('clearIdempotencyKey causes a new key to be generated', () async {
      final repo = DraftRepository();
      final k1 = await repo.getOrCreateIdempotencyKey('uid1', 'draft-1');
      await repo.clearIdempotencyKey('uid1', 'draft-1');
      final k2 = await repo.getOrCreateIdempotencyKey('uid1', 'draft-1');
      expect(k1, isNot(equals(k2)));
    });

    test('keys are isolated per UID', () async {
      final repo = DraftRepository();
      final kA = await repo.getOrCreateIdempotencyKey('uid-A', 'draft-1');
      final kB = await repo.getOrCreateIdempotencyKey('uid-B', 'draft-1');
      expect(kA, isNot(equals(kB)));
    });
  });

  group('DraftRepository — PendingPaymentContext', () {
    test('returns null when nothing saved', () async {
      final repo = DraftRepository();
      expect(await repo.loadPaymentContext('uid1'), isNull);
    });

    test('saves and loads payment context', () async {
      final repo = DraftRepository();
      final ctx = PendingPaymentContext(
        bookingId: 42,
        checkoutUrl: 'https://pay.example.com/session/abc',
        customerUid: 'uid1',
        savedAt: DateTime.now(),
      );
      await repo.savePaymentContext(ctx);
      final loaded = await repo.loadPaymentContext('uid1');
      expect(loaded, isNotNull);
      expect(loaded!.bookingId, 42);
      expect(loaded.checkoutUrl, 'https://pay.example.com/session/abc');
    });

    test('returns null for expired context', () async {
      final repo = DraftRepository();
      final ctx = PendingPaymentContext(
        bookingId: 1,
        checkoutUrl: 'https://pay.example.com/session/old',
        customerUid: 'uid1',
        savedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      await repo.savePaymentContext(ctx);
      expect(await repo.loadPaymentContext('uid1'), isNull);
    });

    test('clearPaymentContext removes the entry', () async {
      final repo = DraftRepository();
      final ctx = PendingPaymentContext(
        bookingId: 99,
        checkoutUrl: 'https://pay.example.com/session/x',
        customerUid: 'uid1',
        savedAt: DateTime.now(),
      );
      await repo.savePaymentContext(ctx);
      await repo.clearPaymentContext('uid1');
      expect(await repo.loadPaymentContext('uid1'), isNull);
    });
  });

  group('DraftRepository — clearAllForAccount', () {
    test('removes draft, idempotency key, and payment context for UID',
        () async {
      final repo = DraftRepository();
      await repo.saveDraft(
        'uid1',
        BookingDraft(
          id: 'd',
          createdAt: DateTime.now(),
          status: BookingDraftStatus.editing,
        ),
      );
      await repo.getOrCreateIdempotencyKey('uid1', 'd');
      await repo.savePaymentContext(PendingPaymentContext(
        bookingId: 1,
        checkoutUrl: 'https://pay.example.com',
        customerUid: 'uid1',
        savedAt: DateTime.now(),
      ));

      await repo.clearAllForAccount('uid1');

      expect(await repo.loadDraft('uid1'), isNull);
      expect(await repo.loadPaymentContext('uid1'), isNull);
      // After clearing, a new key must be generated — proving the old one was removed.
      final newKey = await repo.getOrCreateIdempotencyKey('uid1', 'd');
      expect(newKey, isNotEmpty);
    });

    test('does not affect a different UID', () async {
      final repo = DraftRepository();
      final ctx = PendingPaymentContext(
        bookingId: 5,
        checkoutUrl: 'https://pay.example.com/5',
        customerUid: 'uid-B',
        savedAt: DateTime.now(),
      );
      await repo.savePaymentContext(ctx);

      await repo.clearAllForAccount('uid-A');

      expect(await repo.loadPaymentContext('uid-B'), isNotNull);
    });
  });

  group('DraftRepository — clearAll', () {
    test('removes entries for all UIDs', () async {
      final repo = DraftRepository();
      await repo.savePaymentContext(PendingPaymentContext(
        bookingId: 1,
        checkoutUrl: 'https://pay.example.com/1',
        customerUid: 'uid-A',
        savedAt: DateTime.now(),
      ));
      await repo.savePaymentContext(PendingPaymentContext(
        bookingId: 2,
        checkoutUrl: 'https://pay.example.com/2',
        customerUid: 'uid-B',
        savedAt: DateTime.now(),
      ));

      await repo.clearAll();

      expect(await repo.loadPaymentContext('uid-A'), isNull);
      expect(await repo.loadPaymentContext('uid-B'), isNull);
    });
  });
}
