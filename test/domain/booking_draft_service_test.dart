import 'package:client/common/domain/booking/booking_draft.dart';
import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:flutter_test/flutter_test.dart';

BookingDraft _freshDraft() => BookingDraft(
      id: 'draft-1',
      createdAt: DateTime.now(),
      serviceId: 'svc-1',
    );

BookingDraft _expiredDraft() => BookingDraft(
      id: 'draft-old',
      createdAt: DateTime.now().subtract(const Duration(hours: 25)),
    );

void main() {
  late BookingDraftService service;

  setUp(() => service = BookingDraftService());

  group('initial state', () {
    test('hasDraft is false on creation', () {
      expect(service.hasDraft, isFalse);
    });

    test('current returns null on creation', () {
      expect(service.current, isNull);
    });
  });

  group('save', () {
    test('save sets hasDraft to true', () {
      service.save(_freshDraft());
      expect(service.hasDraft, isTrue);
    });

    test('save marks draft as authenticationRequired', () {
      service.save(_freshDraft());
      expect(
        service.current!.status,
        equals(BookingDraftStatus.authenticationRequired),
      );
    });

    test('save replaces a previous draft', () {
      final d1 = BookingDraft(id: 'first', createdAt: DateTime.now());
      final d2 = BookingDraft(id: 'second', createdAt: DateTime.now());
      service.save(d1);
      service.save(d2);
      expect(service.current!.id, equals('second'));
    });
  });

  group('restore', () {
    test('restore returns draft and marks it restored', () {
      service.save(_freshDraft());
      final restored = service.restore();
      expect(restored, isNotNull);
      expect(restored!.status, equals(BookingDraftStatus.restored));
    });

    test('restore returns null when no draft saved', () {
      expect(service.restore(), isNull);
    });

    test('restore returns null for an expired draft and clears it', () {
      // save() always calls copyWith() which resets updatedAt to now, so
      // inject directly to test expiry detection at the service level.
      service.injectDraftForTesting(_expiredDraft());
      final result = service.restore();
      expect(result, isNull);
      expect(service.hasDraft, isFalse);
    });

    test('restore can be called multiple times (draft is retained)', () {
      service.save(_freshDraft());
      service.restore();
      final second = service.restore();
      expect(second, isNotNull);
    });
  });

  group('current', () {
    test('current returns null for expired draft', () {
      // save() always calls copyWith() which resets updatedAt to now, so
      // inject directly to test expiry detection at the service level.
      service.injectDraftForTesting(_expiredDraft());
      expect(service.current, isNull);
    });

    test('current returns non-null for fresh draft', () {
      service.save(_freshDraft());
      expect(service.current, isNotNull);
    });
  });

  group('clear', () {
    test('clear removes draft', () {
      service.save(_freshDraft());
      service.clear();
      expect(service.hasDraft, isFalse);
      expect(service.current, isNull);
    });

    test('clear on empty service is a no-op', () {
      expect(() => service.clear(), returnsNormally);
    });
  });

  group('returnRouteName round-trip', () {
    test('returnRouteName is preserved through save → restore', () {
      final draft = BookingDraft(
        id: 'rt-1',
        createdAt: DateTime.now(),
        returnRouteName: 'AirconOptionsScreen',
      );
      service.save(draft);
      final restored = service.restore();
      expect(restored?.returnRouteName, equals('AirconOptionsScreen'));
    });

    test('restore returns null after clear, discarding returnRouteName', () {
      final draft = BookingDraft(
        id: 'rt-2',
        createdAt: DateTime.now(),
        returnRouteName: 'BwAddOnsScreen',
      );
      service.save(draft);
      service.restore();
      service.clear();
      expect(service.restore(), isNull);
    });

    test('restore after clear does not yield stale returnRouteName', () {
      final draft = BookingDraft(
        id: 'rt-3',
        createdAt: DateTime.now(),
        returnRouteName: 'AirconOptionsScreen',
      );
      service.save(draft);
      service.restore();
      service.clear();
      // A second login must not re-navigate with the stale route
      expect(service.restore(), isNull);
      expect(service.hasDraft, isFalse);
    });
  });
}
