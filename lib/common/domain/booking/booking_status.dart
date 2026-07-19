/// Canonical booking lifecycle states for the Servana client.
///
/// Maps directly to backend `status` values returned by GET /api/{bookingId}.
/// Unknown backend values are mapped to [BookingStatus.unknown] — they must
/// NEVER be silently interpreted as [BookingStatus.confirmed].
enum BookingStatus {
  // ── Pre-creation ───────────────────────────────────────────────────────────
  draft,

  // ── Created, awaiting action ───────────────────────────────────────────────
  pendingOtp,
  otpVerified,
  pendingPayment,
  paymentProcessing,
  paymentPendingConfirmation,

  // ── Operational ────────────────────────────────────────────────────────────
  paid,
  awaitingAssignment,
  assigned,
  confirmed,

  // ── Terminal ───────────────────────────────────────────────────────────────
  completed,
  cancelled,
  expired,
  failed,

  // ── Safety net — never treat as confirmed ─────────────────────────────────
  unknown,
}

/// Maps raw backend status strings to [BookingStatus].
///
/// Case-insensitive. Returns [BookingStatus.unknown] for unrecognised values
/// so callers are forced to handle the unknown case explicitly rather than
/// defaulting to success.
abstract final class BookingStatusMapper {
  static BookingStatus fromString(String? raw) {
    if (raw == null || raw.isEmpty) return BookingStatus.unknown;
    switch (raw.toUpperCase().trim()) {
      case 'PENDING_OTP':
      case 'PENDINGOTP':
      case 'FOR_OTP':
        return BookingStatus.pendingOtp;
      case 'OTP_VERIFIED':
      case 'OTPVERIFIED':
        return BookingStatus.otpVerified;
      case 'PENDING_PAYMENT':
      case 'PENDINGPAYMENT':
      case 'PAYMENT_PENDING':
        return BookingStatus.pendingPayment;
      case 'PAYMENT_PROCESSING':
        return BookingStatus.paymentProcessing;
      case 'PAYMENT_PENDING_CONFIRMATION':
        return BookingStatus.paymentPendingConfirmation;
      case 'PAID':
      case 'PAYMENT_PAID':
        return BookingStatus.paid;
      case 'AWAITING_ASSIGNMENT':
      case 'FOR_ASSIGNMENT':
      case 'FOR_REVIEW':
      case 'FORREVIEW':
        return BookingStatus.awaitingAssignment;
      case 'ASSIGNED':
      case 'ACCEPTED':
        return BookingStatus.assigned;
      case 'CONFIRMED':
        return BookingStatus.confirmed;
      case 'COMPLETED':
      case 'DONE':
        return BookingStatus.completed;
      case 'CANCELLED':
      case 'CANCELED':
        return BookingStatus.cancelled;
      case 'EXPIRED':
        return BookingStatus.expired;
      case 'FAILED':
        return BookingStatus.failed;
      default:
        return BookingStatus.unknown;
    }
  }

  /// Human-readable title shown on the confirmation screen.
  static String confirmationTitle(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingOtp:
        return 'Verify Your Booking';
      case BookingStatus.pendingPayment:
        return 'Booking Created — Payment Required';
      case BookingStatus.paymentProcessing:
      case BookingStatus.paymentPendingConfirmation:
        return 'Payment Submitted';
      case BookingStatus.paid:
      case BookingStatus.awaitingAssignment:
        return 'Booking Confirmed';
      case BookingStatus.assigned:
        return 'Service Professional Assigned';
      case BookingStatus.confirmed:
        return 'Booking Confirmed';
      case BookingStatus.completed:
        return 'Service Completed';
      case BookingStatus.cancelled:
        return 'Booking Cancelled';
      case BookingStatus.expired:
        return 'Booking Expired';
      case BookingStatus.failed:
        return 'Booking Failed';
      case BookingStatus.otpVerified:
      case BookingStatus.draft:
      case BookingStatus.unknown:
        return 'Booking Created';
    }
  }

  /// Human-readable subtitle for the confirmation screen.
  static String confirmationSubtitle(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingOtp:
        return 'Enter the verification code to continue.';
      case BookingStatus.pendingPayment:
        return 'Complete payment to continue processing this booking.';
      case BookingStatus.paymentProcessing:
      case BookingStatus.paymentPendingConfirmation:
        return "We're confirming your payment. This may take a moment.";
      case BookingStatus.paid:
      case BookingStatus.awaitingAssignment:
        return "We're finding an available service professional for you.";
      case BookingStatus.assigned:
        return 'A service professional has been assigned to your booking.';
      case BookingStatus.confirmed:
        return "We're preparing your service professional for your appointment.";
      case BookingStatus.completed:
        return 'Thank you for using Servana.';
      case BookingStatus.cancelled:
        return 'This booking has been cancelled.';
      case BookingStatus.expired:
        return 'This booking has expired. Please create a new booking.';
      case BookingStatus.failed:
        return 'This booking could not be completed. Please try again.';
      case BookingStatus.otpVerified:
      case BookingStatus.draft:
      case BookingStatus.unknown:
        return 'Your booking has been received.';
    }
  }

  /// Whether this status represents a genuinely successful terminal state
  /// that justifies a success animation or haptic.
  static bool isGenuineSuccess(BookingStatus status) {
    return status == BookingStatus.confirmed ||
        status == BookingStatus.assigned ||
        status == BookingStatus.paid;
  }

  /// Whether payment action is required from the user.
  static bool requiresPayment(BookingStatus status) {
    return status == BookingStatus.pendingPayment ||
        status == BookingStatus.otpVerified;
  }

  /// Whether OTP verification is still required.
  static bool requiresOtp(BookingStatus status) {
    return status == BookingStatus.pendingOtp;
  }

  /// Whether assignment polling should run.
  static bool shouldPollAssignment(BookingStatus status) {
    return status == BookingStatus.awaitingAssignment ||
        status == BookingStatus.paid ||
        status == BookingStatus.confirmed;
  }
}
