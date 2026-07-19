/// Canonical booking lifecycle states for the Servana client.
///
/// Maps directly to backend `status` values returned by GET /api/{bookingId}.
/// Unknown backend values are mapped to [BookingStatus.unknown] — they must
/// NEVER be silently interpreted as [BookingStatus.confirmed].
enum BookingStatus {
  // ── Pre-creation ───────────────────────────────────────────────────────────
  draft,

  // ── Action required — user must act before service can proceed ─────────────
  pendingOtp,
  otpVerified,
  pendingPayment,
  paymentProcessing,
  paymentPendingConfirmation,

  // ── Upcoming — booking confirmed, service not yet started ─────────────────
  paid,
  awaitingAssignment,
  assigned,
  confirmed,

  // ── Active — service is underway ───────────────────────────────────────────
  enRoute,
  arrived,
  inProgress,
  awaitingCompletion,

  // ── Completed — service finished successfully ─────────────────────────────
  completed,
  reviewed,

  // ── Cancelled — terminal failure states ────────────────────────────────────
  cancelled,
  cancelledByProvider,
  cancelledByAdmin,
  expired,
  failed,
  refunded,

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
      case 'EN_ROUTE':
      case 'ENROUTE':
      case 'IN_TRANSIT':
      case 'INTRANSIT':
      case 'WORKER_ASSIGNED':
        return BookingStatus.enRoute;
      case 'ARRIVED':
      case 'AT_LOCATION':
        return BookingStatus.arrived;
      case 'IN_PROGRESS':
      case 'INPROGRESS':
      case 'STARTED':
        return BookingStatus.inProgress;
      case 'AWAITING_COMPLETION':
      case 'FOR_COMPLETION':
      case 'AWAITING_REVIEW':
        return BookingStatus.awaitingCompletion;
      case 'COMPLETED':
      case 'DONE':
        return BookingStatus.completed;
      case 'REVIEWED':
      case 'RATING_SUBMITTED':
        return BookingStatus.reviewed;
      case 'CANCELLED':
      case 'CANCELED':
        return BookingStatus.cancelled;
      case 'CANCELLED_BY_PROVIDER':
      case 'PROVIDER_CANCELLED':
        return BookingStatus.cancelledByProvider;
      case 'CANCELLED_BY_ADMIN':
      case 'ADMIN_CANCELLED':
        return BookingStatus.cancelledByAdmin;
      case 'EXPIRED':
        return BookingStatus.expired;
      case 'FAILED':
        return BookingStatus.failed;
      case 'REFUNDED':
        return BookingStatus.refunded;
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
      case BookingStatus.enRoute:
        return 'Provider En Route';
      case BookingStatus.arrived:
        return 'Provider Arrived';
      case BookingStatus.inProgress:
        return 'Service In Progress';
      case BookingStatus.awaitingCompletion:
        return 'Awaiting Completion';
      case BookingStatus.completed:
        return 'Service Completed';
      case BookingStatus.reviewed:
        return 'Service Reviewed';
      case BookingStatus.cancelled:
        return 'Booking Cancelled';
      case BookingStatus.cancelledByProvider:
        return 'Cancelled by Provider';
      case BookingStatus.cancelledByAdmin:
        return 'Cancelled by Admin';
      case BookingStatus.expired:
        return 'Booking Expired';
      case BookingStatus.failed:
        return 'Booking Failed';
      case BookingStatus.refunded:
        return 'Booking Refunded';
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
      case BookingStatus.enRoute:
        return 'Your service professional is on the way.';
      case BookingStatus.arrived:
        return 'Your service professional has arrived.';
      case BookingStatus.inProgress:
        return 'Your service is currently being performed.';
      case BookingStatus.awaitingCompletion:
        return 'Your service is nearly done.';
      case BookingStatus.completed:
        return 'Thank you for using Servana.';
      case BookingStatus.reviewed:
        return 'Your review has been submitted.';
      case BookingStatus.cancelled:
        return 'This booking has been cancelled.';
      case BookingStatus.cancelledByProvider:
        return 'The service provider cancelled this booking.';
      case BookingStatus.cancelledByAdmin:
        return 'This booking was cancelled by support.';
      case BookingStatus.expired:
        return 'This booking has expired. Please create a new booking.';
      case BookingStatus.failed:
        return 'This booking could not be completed. Please try again.';
      case BookingStatus.refunded:
        return 'Your payment has been refunded.';
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
