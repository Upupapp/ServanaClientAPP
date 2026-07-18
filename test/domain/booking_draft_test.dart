import 'package:client/common/domain/booking/booking_draft.dart';
import 'package:flutter_test/flutter_test.dart';

BookingDraft _draft({DateTime? createdAt, DateTime? updatedAt}) {
  return BookingDraft(
    id: 'test-id',
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt,
  );
}

void main() {
  group('BookingDraft.isExpired', () {
    test('fresh draft is not expired', () {
      expect(_draft().isExpired, isFalse);
    });

    test('draft created 25 hours ago is expired', () {
      final old = _draft(createdAt: DateTime.now().subtract(const Duration(hours: 25)));
      expect(old.isExpired, isTrue);
    });

    test('draft updated recently is not expired even if created long ago', () {
      final d = _draft(
        createdAt: DateTime.now().subtract(const Duration(hours: 48)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(d.isExpired, isFalse);
    });

    test('draft updated 25 hours ago is expired', () {
      final d = _draft(
        createdAt: DateTime.now().subtract(const Duration(hours: 48)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );
      expect(d.isExpired, isTrue);
    });
  });

  group('BookingDraft.hasServiceSelected', () {
    test('false when no service fields set', () {
      expect(_draft().hasServiceSelected, isFalse);
    });

    test('true when serviceId is set', () {
      final d = _draft().copyWith(serviceId: 'svc-1');
      expect(d.hasServiceSelected, isTrue);
    });

    test('true when selectedServiceJson is set', () {
      final d = _draft().copyWith(selectedServiceJson: '{}');
      expect(d.hasServiceSelected, isTrue);
    });
  });

  group('BookingDraft.isReadyForReview', () {
    test('false when no service selected', () {
      expect(_draft().isReadyForReview, isFalse);
    });

    test('false when service selected but no address or date', () {
      final d = _draft().copyWith(serviceId: 'svc-1');
      expect(d.isReadyForReview, isFalse);
    });

    test('false when service + address but no date', () {
      final d = _draft().copyWith(serviceId: 'svc-1', addressLine: '123 Main St');
      expect(d.isReadyForReview, isFalse);
    });

    test('true when service + address + date all set', () {
      final d = _draft().copyWith(
        serviceId: 'svc-1',
        addressLine: '123 Main St',
        selectedDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(d.isReadyForReview, isTrue);
    });

    test('true when service + branch + date (no address needed for branch flow)', () {
      final d = _draft().copyWith(
        serviceId: 'svc-1',
        selectedBranchId: 'branch-1',
        selectedDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(d.isReadyForReview, isTrue);
    });
  });

  group('BookingDraft.copyWith', () {
    test('preserves original id and createdAt', () {
      final original = _draft(createdAt: DateTime(2025, 1, 1));
      final copy = original.copyWith(serviceId: 'svc-1');
      expect(copy.id, equals(original.id));
      expect(copy.createdAt, equals(original.createdAt));
    });

    test('updates updatedAt to now on copyWith', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final copy = _draft().copyWith(serviceId: 'svc-1');
      expect(copy.updatedAt!.isAfter(before), isTrue);
    });

    test('preserves un-changed fields', () {
      final d = _draft().copyWith(merchantId: 'merch-1', merchantName: 'Test Shop');
      final d2 = d.copyWith(serviceId: 'svc-1');
      expect(d2.merchantId, equals('merch-1'));
      expect(d2.merchantName, equals('Test Shop'));
    });
  });
}
