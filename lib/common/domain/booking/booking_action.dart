import 'package:flutter/material.dart';

/// All possible actions a customer can take on a booking.
///
/// Variants are ordered by expected visual priority (high → low) so that
/// callers can `actions.first` to obtain the most important action without
/// needing to know the resolver logic.
enum BookingAction {
  /// Enter the OTP sent via SMS to verify the booking.
  confirmOtp,

  /// Complete an outstanding payment.
  pay,

  /// Retry a failed payment.
  retryPayment,

  /// Open the in-app chat with the assigned provider.
  message,

  /// View live tracking map / ETA.
  track,

  /// Cancel the booking (pre-service only).
  cancel,

  /// Reschedule to a different date/time.
  reschedule,

  /// View the payment receipt.
  viewReceipt,

  /// Leave a rating and review for the completed service.
  reviewService,

  /// Create a new booking for the same service.
  bookAgain,

  /// Open a support ticket or chat.
  contactSupport,
}

extension BookingActionProps on BookingAction {
  // ── Display ─────────────────────────────────────────────────────────────────

  /// Short, customer-facing label for the action button or menu item.
  String get label {
    switch (this) {
      case BookingAction.confirmOtp:
        return 'Confirm Booking';
      case BookingAction.pay:
        return 'Pay Now';
      case BookingAction.retryPayment:
        return 'Retry Payment';
      case BookingAction.message:
        return 'Message Provider';
      case BookingAction.track:
        return 'Track Provider';
      case BookingAction.cancel:
        return 'Cancel Booking';
      case BookingAction.reschedule:
        return 'Reschedule';
      case BookingAction.viewReceipt:
        return 'View Receipt';
      case BookingAction.reviewService:
        return 'Leave a Review';
      case BookingAction.bookAgain:
        return 'Book Again';
      case BookingAction.contactSupport:
        return 'Contact Support';
    }
  }

  /// Material icon representing this action.
  IconData get icon {
    switch (this) {
      case BookingAction.confirmOtp:
        return Icons.verified_outlined;
      case BookingAction.pay:
        return Icons.payment_outlined;
      case BookingAction.retryPayment:
        return Icons.refresh_outlined;
      case BookingAction.message:
        return Icons.chat_bubble_outline;
      case BookingAction.track:
        return Icons.location_on_outlined;
      case BookingAction.cancel:
        return Icons.cancel_outlined;
      case BookingAction.reschedule:
        return Icons.edit_calendar_outlined;
      case BookingAction.viewReceipt:
        return Icons.receipt_long_outlined;
      case BookingAction.reviewService:
        return Icons.star_outline;
      case BookingAction.bookAgain:
        return Icons.add_circle_outline;
      case BookingAction.contactSupport:
        return Icons.support_agent_outlined;
    }
  }

  // ── Semantics ────────────────────────────────────────────────────────────────

  /// Whether this action is destructive and should be rendered with a warning
  /// colour (e.g. red) rather than the primary accent.
  bool get isDestructive {
    return this == BookingAction.cancel;
  }

  /// Whether this is the highest-priority action and should be rendered as a
  /// full-width prominent button rather than a secondary chip or menu item.
  bool get isPrimary {
    switch (this) {
      case BookingAction.confirmOtp:
      case BookingAction.pay:
      case BookingAction.retryPayment:
        return true;
      default:
        return false;
    }
  }

  /// Whether this action requires a provider to already be assigned.
  bool get requiresWorker {
    return this == BookingAction.message || this == BookingAction.track;
  }
}
