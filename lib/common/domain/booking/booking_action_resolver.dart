import 'package:client/common/domain/booking/booking_action.dart';
import 'package:client/common/domain/booking/booking_status.dart';

/// Determines which [BookingAction]s are available for a booking given its
/// current state.
///
/// All logic is pure (no I/O, no service calls).  Results are re-computed on
/// every call — callers should cache the result for the lifetime of a single
/// render cycle and invalidate on any status change.
abstract final class BookingActionResolver {
  // ── Status sets used in resolve() ──────────────────────────────────────────

  /// Statuses where cancellation is still permitted (pre-service only).
  static const Set<BookingStatus> _cancellable = {
    BookingStatus.pendingOtp,
    BookingStatus.otpVerified,
    BookingStatus.pendingPayment,
    BookingStatus.paymentProcessing,
    BookingStatus.paymentPendingConfirmation,
    BookingStatus.paid,
    BookingStatus.awaitingAssignment,
    BookingStatus.confirmed,
    BookingStatus.assigned,
  };

  /// Statuses where re-booking makes sense (service is definitively over).
  static const Set<BookingStatus> _rebookable = {
    BookingStatus.completed,
    BookingStatus.reviewed,
    BookingStatus.cancelled,
    BookingStatus.cancelledByProvider,
    BookingStatus.cancelledByAdmin,
    BookingStatus.refunded,
  };

  /// Statuses where live tracking should be offered.
  static const Set<BookingStatus> _trackable = {
    BookingStatus.enRoute,
    BookingStatus.arrived,
    BookingStatus.inProgress,
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns every [BookingAction] the customer can perform right now, ordered
  /// by descending priority (primary actions first, destructive actions last).
  ///
  /// Parameters:
  /// - [status]        – canonical booking status
  /// - [paymentStatus] – raw payment status string from backend ('PAID' | 'PENDING' | …)
  /// - [paymentMethod] – 'CASH' | 'GCASH' | 'CARD' | null
  /// - [workerUid]     – Firebase UID of the assigned provider (null if unassigned)
  /// - [hasReview]     – whether the customer has already submitted a review
  static List<BookingAction> resolve({
    required BookingStatus status,
    required String paymentStatus,
    String? paymentMethod,
    String? workerUid,
    bool hasReview = false,
  }) {
    final terminal = BookingStatusMapper.isTerminal(status);
    final isPaid = paymentStatus.toUpperCase() == 'PAID';
    final isCash = paymentMethod?.toUpperCase() == 'CASH';

    final actions = <BookingAction>[];

    // ── Highest priority: user must act before anything else proceeds ─────────

    if (BookingStatusMapper.requiresOtp(status)) {
      actions.add(BookingAction.confirmOtp);
    }

    if (!isCash) {
      if (status == BookingStatus.paymentProcessing ||
          status == BookingStatus.paymentPendingConfirmation) {
        actions.add(BookingAction.retryPayment);
      } else if (BookingStatusMapper.requiresPayment(status)) {
        actions.add(BookingAction.pay);
      }
    }

    // ── Active service actions ────────────────────────────────────────────────

    if (_trackable.contains(status)) {
      actions.add(BookingAction.track);
    }

    if (workerUid != null && workerUid.isNotEmpty && !terminal) {
      actions.add(BookingAction.message);
    }

    // ── Post-service / terminal actions ───────────────────────────────────────

    if (isPaid) {
      actions.add(BookingAction.viewReceipt);
    }

    if (status == BookingStatus.completed && !hasReview) {
      actions.add(BookingAction.reviewService);
    }

    if (_rebookable.contains(status)) {
      actions.add(BookingAction.bookAgain);
    }

    // ── Mutation actions (shown below the fold, lower priority) ───────────────

    if (_cancellable.contains(status)) {
      actions.add(BookingAction.cancel);
    }

    // ── Always-available ──────────────────────────────────────────────────────

    actions.add(BookingAction.contactSupport);

    return actions;
  }

  /// Convenience: returns the single most important action to surface as a
  /// full-width CTA, or null if the booking has no actionable state (e.g. it
  /// is merely upcoming and nothing is required of the user yet).
  ///
  /// A primary action is one that is both [BookingActionProps.isPrimary] and
  /// appears first in the [resolve] result.  If no primary action exists, null
  /// is returned — the caller should fall back to showing secondary chips.
  static BookingAction? primaryAction({
    required BookingStatus status,
    required String paymentStatus,
    String? paymentMethod,
    String? workerUid,
    bool hasReview = false,
  }) {
    final all = resolve(
      status: status,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      workerUid: workerUid,
      hasReview: hasReview,
    );
    for (final action in all) {
      if (action.isPrimary) return action;
    }
    return null;
  }
}
