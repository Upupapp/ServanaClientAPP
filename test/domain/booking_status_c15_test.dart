import 'package:client/common/domain/booking/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── customerLabel() ───────────────────────────────────────────────────────

  group('BookingStatusMapper.customerLabel', () {
    test('returns non-empty string for every BookingStatus value', () {
      for (final status in BookingStatus.values) {
        final label = BookingStatusMapper.customerLabel(status);
        expect(
          label,
          isNotEmpty,
          reason: 'customerLabel should not be empty for $status',
        );
      }
    });

    test('returns "Pay Now" for pendingPayment', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.pendingPayment),
        'Pay Now',
      );
    });

    test('returns "Verify Now" for pendingOtp', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.pendingOtp),
        'Verify Now',
      );
    });

    test('returns "Provider En Route" for enRoute', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.enRoute),
        'Provider En Route',
      );
    });

    test('returns "Service in Progress" for inProgress', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.inProgress),
        'Service in Progress',
      );
    });

    test('returns "Completed" for completed', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.completed),
        'Completed',
      );
    });

    test('returns "Cancelled" for cancelled', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.cancelled),
        'Cancelled',
      );
    });

    test('returns "Cancelled by Provider" for cancelledByProvider', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.cancelledByProvider),
        'Cancelled by Provider',
      );
    });

    test('returns "Cancelled by Support" for cancelledByAdmin', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.cancelledByAdmin),
        'Cancelled by Support',
      );
    });

    test('returns "Expired" for expired', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.expired),
        'Expired',
      );
    });

    test('returns "Refunded" for refunded', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.refunded),
        'Refunded',
      );
    });

    test('returns "Pending" for unknown', () {
      expect(
        BookingStatusMapper.customerLabel(BookingStatus.unknown),
        'Pending',
      );
    });
  });

  // ── heroSubtitle() ────────────────────────────────────────────────────────

  group('BookingStatusMapper.heroSubtitle', () {
    test('returns non-empty string for every BookingStatus value', () {
      for (final status in BookingStatus.values) {
        final subtitle = BookingStatusMapper.heroSubtitle(status);
        expect(
          subtitle,
          isNotEmpty,
          reason: 'heroSubtitle should not be empty for $status',
        );
      }
    });

    test('heroSubtitle for pendingOtp mentions verification code', () {
      final subtitle =
          BookingStatusMapper.heroSubtitle(BookingStatus.pendingOtp);
      expect(subtitle.toLowerCase(), contains('verification'));
    });

    test('heroSubtitle for pendingPayment mentions payment', () {
      final subtitle =
          BookingStatusMapper.heroSubtitle(BookingStatus.pendingPayment);
      expect(subtitle.toLowerCase(), contains('payment'));
    });

    test('heroSubtitle for completed conveys success', () {
      final subtitle =
          BookingStatusMapper.heroSubtitle(BookingStatus.completed);
      expect(subtitle.toLowerCase(), contains('complet'));
    });

    test('heroSubtitle for cancelled conveys cancellation', () {
      final subtitle =
          BookingStatusMapper.heroSubtitle(BookingStatus.cancelled);
      expect(subtitle.toLowerCase(), contains('cancel'));
    });

    test('heroSubtitle for refunded mentions refund', () {
      final subtitle = BookingStatusMapper.heroSubtitle(BookingStatus.refunded);
      expect(subtitle.toLowerCase(), contains('refund'));
    });
  });

  // ── isTerminal() ──────────────────────────────────────────────────────────

  group('BookingStatusMapper.isTerminal – terminal statuses', () {
    test('completed is terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.completed), isTrue);
    });

    test('reviewed is terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.reviewed), isTrue);
    });

    test('cancelled is terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.cancelled), isTrue);
    });

    test('cancelledByProvider is terminal', () {
      expect(
        BookingStatusMapper.isTerminal(BookingStatus.cancelledByProvider),
        isTrue,
      );
    });

    test('cancelledByAdmin is terminal', () {
      expect(
        BookingStatusMapper.isTerminal(BookingStatus.cancelledByAdmin),
        isTrue,
      );
    });

    test('expired is terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.expired), isTrue);
    });

    test('failed is terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.failed), isTrue);
    });

    test('refunded is terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.refunded), isTrue);
    });
  });

  group('BookingStatusMapper.isTerminal – non-terminal statuses', () {
    test('assigned is NOT terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.assigned), isFalse);
    });

    test('inProgress is NOT terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.inProgress), isFalse);
    });

    test('pendingOtp is NOT terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.pendingOtp), isFalse);
    });

    test('pendingPayment is NOT terminal', () {
      expect(
        BookingStatusMapper.isTerminal(BookingStatus.pendingPayment),
        isFalse,
      );
    });

    test('confirmed is NOT terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.confirmed), isFalse);
    });

    test('enRoute is NOT terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.enRoute), isFalse);
    });

    test('paid is NOT terminal', () {
      expect(BookingStatusMapper.isTerminal(BookingStatus.paid), isFalse);
    });

    test('awaitingAssignment is NOT terminal', () {
      expect(
        BookingStatusMapper.isTerminal(BookingStatus.awaitingAssignment),
        isFalse,
      );
    });
  });

  // ── groupCategory() ───────────────────────────────────────────────────────

  group('BookingStatusMapper.groupCategory', () {
    group('needsAttention bucket', () {
      test('pendingOtp → needsAttention', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.pendingOtp),
          'needsAttention',
        );
      });

      test('pendingPayment → needsAttention', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.pendingPayment),
          'needsAttention',
        );
      });

      test('paymentProcessing → needsAttention', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.paymentProcessing),
          'needsAttention',
        );
      });

      test('paymentPendingConfirmation → needsAttention', () {
        expect(
          BookingStatusMapper.groupCategory(
              BookingStatus.paymentPendingConfirmation),
          'needsAttention',
        );
      });

      test('failed → needsAttention', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.failed),
          'needsAttention',
        );
      });
    });

    group('active bucket', () {
      test('enRoute → active', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.enRoute),
          'active',
        );
      });

      test('arrived → active', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.arrived),
          'active',
        );
      });

      test('inProgress → active', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.inProgress),
          'active',
        );
      });
    });

    group('upcoming bucket', () {
      test('paid → upcoming', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.paid),
          'upcoming',
        );
      });

      test('awaitingAssignment → upcoming', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.awaitingAssignment),
          'upcoming',
        );
      });

      test('assigned → upcoming', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.assigned),
          'upcoming',
        );
      });

      test('confirmed → upcoming', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.confirmed),
          'upcoming',
        );
      });

      test('awaitingCompletion → upcoming', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.awaitingCompletion),
          'upcoming',
        );
      });

      test('draft → upcoming', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.draft),
          'upcoming',
        );
      });

      test('otpVerified → upcoming', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.otpVerified),
          'upcoming',
        );
      });
    });

    group('completed bucket', () {
      test('completed → completed', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.completed),
          'completed',
        );
      });

      test('reviewed → completed', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.reviewed),
          'completed',
        );
      });

      test('refunded → completed', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.refunded),
          'completed',
        );
      });
    });

    group('cancelled bucket', () {
      test('cancelled → cancelled', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.cancelled),
          'cancelled',
        );
      });

      test('cancelledByProvider → cancelled', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.cancelledByProvider),
          'cancelled',
        );
      });

      test('cancelledByAdmin → cancelled', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.cancelledByAdmin),
          'cancelled',
        );
      });

      test('expired → cancelled', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.expired),
          'cancelled',
        );
      });

      test('unknown → cancelled', () {
        expect(
          BookingStatusMapper.groupCategory(BookingStatus.unknown),
          'cancelled',
        );
      });
    });
  });
}
