/// Booking lifecycle actions as the app performs them today.
///
/// This is the source every shipped build uses. The three calls it can make —
/// cancel, resend, confirm — are the ones already in [ServanaApiClient],
/// unchanged.
///
/// ## What this source has to do that the canonical one does not
///
/// **Turn a 200 into a failure.** `POST /api/:id/confirm-otp` answers a wrong
/// code with `{success: false, message: …}` at HTTP 200 as often as with a 400.
/// The OTP screen used to read that flag itself, which meant the failure shape
/// depended on which transport answered. Normalising it here is what lets one
/// caller handle both: a wrong code raises [ValidationFailure] on either path,
/// carrying `BOOKING_OTP_INVALID` so the two are indistinguishable above this
/// line.
///
/// **Report absent things as absent.** There is no legacy OTP status route and
/// no customer reschedule route. Neither is faked. [supportsOtpStatus] and
/// [supportsReschedule] are false, [otpStatus] returns the honest local state
/// with every budget null, and reschedule throws a programming error rather
/// than a customer-facing one.
///
/// ## Idempotency keys are accepted and dropped
///
/// The parameter is on the interface because the canonical transport needs it.
/// The legacy routes read no such header — `readIdempotencyKey` is a v1
/// function and these are not v1 routes — so passing one here would be
/// decorative. It is dropped explicitly, with this note, rather than forwarded
/// under a name nothing reads.
library;

import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/bookings/data/booking_lifecycle_data_source.dart';
import 'package:client/modules/bookings/domain/booking_otp_state.dart';
import 'package:client/modules/bookings/domain/booking_reschedule.dart';
import 'package:client/modules/bookings/domain/booking_transition_result.dart';

class BookingLifecycleCompatibilityDataSource
    implements BookingLifecycleDataSource {
  const BookingLifecycleCompatibilityDataSource(this._api);

  final ServanaApiClient _api;

  @override
  bool get supportsReschedule => false;

  @override
  bool get supportsOtpStatus => false;

  @override
  Future<BookingTransitionResult> cancel({
    required String bookingId,
    required String reason,
    required String idempotencyKey,
    String? expectedState,
  }) async {
    // `expectedState` is dropped too: the legacy route has no optimistic
    // concurrency, so sending it would imply a guard that is not there.
    final result = await _api.cancelBooking(
      bookingId: int.parse(bookingId),
      reason: reason,
    );
    _throwIfUnsuccessful(result, fallbackCode: 'BOOKING_STATE_CONFLICT');

    return BookingTransitionResult.assumed(
      bookingId: bookingId,
      action: 'cancel',
      fromState: expectedState ?? '',
      toState: 'CANCELLED',
    );
  }

  @override
  Future<BookingOtpIssued> requestOtp({
    required String bookingId,
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
  }) async {
    if (purpose != BookingOtpPurpose.bookingConfirmation) {
      // The legacy resend route has no purpose parameter and rotates the
      // customer's confirmation code. Asking it for a SERVICE_START code would
      // silently rotate the wrong credential.
      throw UnsupportedLifecycleAction('OTP purpose ${purpose.wireName}');
    }

    final result = await _api.resendOtp(bookingId: int.parse(bookingId));
    _throwIfUnsuccessful(result, fallbackCode: 'BOOKING_OTP_NOT_APPLICABLE');

    // No expiry, no budgets, no resend instant. The route returns none of them,
    // and the caller learns that from the nulls rather than from a guess.
    return BookingOtpIssued(
      bookingId: bookingId,
      purpose: BookingOtpPurpose.bookingConfirmation,
    );
  }

  @override
  Future<BookingTransitionResult> verifyOtp({
    required String bookingId,
    required String code,
    required String idempotencyKey,
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
    String? expectedState,
  }) async {
    if (purpose != BookingOtpPurpose.bookingConfirmation) {
      throw UnsupportedLifecycleAction('OTP purpose ${purpose.wireName}');
    }

    final result = await _api.confirmOtp(
      bookingId: int.parse(bookingId),
      otp: code,
    );
    _throwIfUnsuccessful(result, fallbackCode: 'BOOKING_OTP_INVALID');

    return BookingTransitionResult.assumed(
      bookingId: bookingId,
      action: 'confirmOtp',
      fromState: expectedState ?? 'PENDING_OTP',
      toState: 'AWAITING_ASSIGNMENT',
    );
  }

  @override
  Future<BookingOtpState> otpStatus({
    required String bookingId,
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
  }) async {
    // Zero, not the cooldown: this is the state on ARRIVING at the screen, and
    // the client's timer starts when the customer resends, not before. Starting
    // it here would disable a resend the server would have allowed.
    return BookingOtpState.local(
      bookingId: bookingId,
      resendAvailableInSeconds: 0,
    );
  }

  @override
  Future<BookingRescheduleResult> reschedule({
    required String bookingId,
    required BookingRescheduleRequest request,
  }) async =>
      throw UnsupportedLifecycleAction('reschedule');

  @override
  Future<List<BookingRescheduleAttempt>> rescheduleHistory(
          String bookingId) async =>
      throw UnsupportedLifecycleAction('reschedule history');

  /// Raises the same [ApiFailure] a canonical refusal would, for the legacy
  /// habit of reporting failure inside a 200.
  ///
  /// [fallbackCode] is the canonical code this route's failure corresponds to.
  /// It is supplied per call rather than guessed from the message, because the
  /// message is free text written for a human and matching on it is how a copy
  /// edit changes control flow.
  void _throwIfUnsuccessful(
    Map<String, dynamic> result, {
    required String fallbackCode,
  }) {
    if (result['success'] != false && result['status'] != 'error') return;

    final raw = result['message'] ?? result['error'];
    final message = raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

    throw ValidationFailure(
      safeMessage: message ?? 'Please check the details and try again.',
      code: fallbackCode,
      debugDetail: 'legacy 200 with success:false — ${jsonEncode(result)}',
    );
  }
}
