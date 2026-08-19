/// The contract both booking-action transports satisfy.
///
///     BookingLifecycleRepository
///       → BookingLifecycleCanonicalDataSource      when V1Capability.bookingLifecycle
///       → BookingLifecycleCompatibilityDataSource  otherwise
///       → the same domain result either way
///
/// ## Actions on an existing booking, never creation
///
/// Everything here names a `:bookingId` that already exists. There is no
/// canonical `POST /api/v1/bookings` — see
/// `docs/convergence-v1/TAB08_ENDPOINT_GAP.md` — so creation stays in
/// `BookingSubmissionService` and is deliberately not part of this boundary.
///
/// ## Reschedule is the one asymmetric capability
///
/// The other four have a legacy relative. Reschedule does not: the only
/// reschedule that has ever existed is `POST /api/admin/bookings/:id/reschedule`,
/// admin-only, which a customer token cannot use. So the compatibility source
/// answers [supportsReschedule] `false` rather than pointing at a route that
/// would 403, and the UI asks before offering the action.
///
/// That is why the flag is on the interface instead of being inferred from a
/// thrown error. A capability discovered by making a request and catching the
/// refusal is a capability the customer discovers by being refused.
library;

import 'package:client/modules/bookings/domain/booking_otp_state.dart';
import 'package:client/modules/bookings/domain/booking_reschedule.dart';
import 'package:client/modules/bookings/domain/booking_transition_result.dart';

/// Thrown when a caller invokes an action the active transport does not have.
///
/// An `Error`, not an `ApiFailure`, and the distinction is the point: no
/// request was made and no server refused anything. Reaching this means the
/// caller skipped [BookingLifecycleDataSource.supportsReschedule], which is a
/// programming mistake to fix rather than a condition to render.
class UnsupportedLifecycleAction extends UnsupportedError {
  UnsupportedLifecycleAction(String action)
      : super('$action is not available on the legacy transport. '
            'Check supportsReschedule before offering it.');
}

abstract interface class BookingLifecycleDataSource {
  /// Whether this transport can move a booking at all.
  bool get supportsReschedule;

  /// Whether this transport can report the backend's own view of the code
  /// budget — attempts left, issues left, seconds until resend.
  ///
  /// False on legacy, where the numbers do not exist and the client's own
  /// 60-second timer is all there is.
  bool get supportsOtpStatus;

  /// Cancels [bookingId].
  ///
  /// [expectedState] is optimistic concurrency: the state the caller last read.
  /// Supplying it converts "act on a stale view" into a clean
  /// `BOOKING_STATE_CONFLICT`.
  ///
  /// [idempotencyKey] must be stable across retries of the SAME user intent and
  /// different between intents. With it, a retry replays the original result;
  /// without it, a second cancel finds the booking already terminal and is
  /// refused — which is safe but produces a confusing error for what the
  /// customer experiences as one tap that lost its connection.
  Future<BookingTransitionResult> cancel({
    required String bookingId,
    required String reason,
    required String idempotencyKey,
    String? expectedState,
  });

  /// Issues a code. The code is never in the response.
  Future<BookingOtpIssued> requestOtp({
    required String bookingId,
    BookingOtpPurpose purpose,
  });

  /// Presents a code. Success is a state transition performed by the executor.
  Future<BookingTransitionResult> verifyOtp({
    required String bookingId,
    required String code,
    required String idempotencyKey,
    BookingOtpPurpose purpose,
    String? expectedState,
  });

  /// Code lifetime, attempts left and resend availability, without spending an
  /// attempt.
  Future<BookingOtpState> otpStatus({
    required String bookingId,
    BookingOtpPurpose purpose,
  });

  /// Proposes a new start time.
  ///
  /// Throws [UnsupportedLifecycleAction] when [supportsReschedule] is false.
  Future<BookingRescheduleResult> reschedule({
    required String bookingId,
    required BookingRescheduleRequest request,
  });

  /// Every attempt to move this booking, accepted or refused.
  ///
  /// Throws [UnsupportedLifecycleAction] when [supportsReschedule] is false.
  Future<List<BookingRescheduleAttempt>> rescheduleHistory(String bookingId);
}
