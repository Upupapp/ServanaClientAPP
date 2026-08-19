/// Booking lifecycle actions over the canonical `/api/v1/bookings/:id/*`
/// namespace.
///
/// ## Not reachable in any shipped build
///
/// Selected only when
/// `CanonicalAvailability.isAvailable(V1Capability.bookingLifecycle)`, which
/// requires `--dart-define=CANONICAL_V1_ENABLED=true` AND `bookingLifecycle` in
/// `CANONICAL_V1_CAPABILITIES`. No production build passes either.
///
/// ## What moving here actually buys
///
/// Not a nicer URL. Three things the legacy routes cannot do:
///
///  1. **A retry stops being a second action.** Every mutation carries
///     `Idempotency-Key`, so a request whose response was lost replays the
///     original result instead of cancelling twice or spending a second OTP
///     attempt. The legacy cancel has no such notion; a lost response there is
///     genuinely ambiguous.
///  2. **A stale view is refused rather than acted on.** `expectedState` turns
///     "cancel the booking I read three minutes ago" into
///     `BOOKING_STATE_CONFLICT` when it has since been assigned.
///  3. **The refusal names the rule.** One code per distinguishable refusal —
///     `BOOKING_TERMINAL` and `BOOKING_NOT_CANCELLABLE_AT_THIS_STAGE` are both
///     409 and want different words. Under the legacy transport the cancel
///     sheet rendered every failure as the same "contact support" sentence.
///
/// ## `Idempotency-Key`, not `X-Idempotency-Key`
///
/// The canonical routes read the former (`envelope.ts`); only the legacy create
/// reads the latter. [V1ApiClient] sent the legacy spelling until this tab, so
/// none of the above would have worked. That fix is upstream of everything
/// here, which is why it happened first.
library;

import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/bookings/data/booking_lifecycle_data_source.dart';
import 'package:client/modules/bookings/domain/booking_otp_state.dart';
import 'package:client/modules/bookings/domain/booking_reschedule.dart';
import 'package:client/modules/bookings/domain/booking_transition_result.dart';

class BookingLifecycleCanonicalDataSource
    implements BookingLifecycleDataSource {
  const BookingLifecycleCanonicalDataSource(this._api);

  final V1ApiClient _api;

  @override
  bool get supportsReschedule => true;

  @override
  bool get supportsOtpStatus => true;

  @override
  Future<BookingTransitionResult> cancel({
    required String bookingId,
    required String reason,
    required String idempotencyKey,
    String? expectedState,
  }) async {
    final envelope = await _api.post(
      V1Endpoints.bookingCancel(bookingId),
      idempotencyKey: idempotencyKey,
      body: <String, dynamic>{
        'reason': reason,
        if (expectedState != null) 'expectedState': expectedState,
      },
    );
    return BookingTransitionResult.fromApiMap(envelope.asMap);
  }

  @override
  Future<BookingOtpIssued> requestOtp({
    required String bookingId,
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
  }) async {
    // No idempotency key, deliberately. This endpoint is not idempotent and
    // does not claim to be: its replay guard is the resend cooldown and the
    // issue ceiling, and a key would let a caller slip a second issue past
    // both by replaying a stored result. The contract lists neither
    // IDEMPOTENCY_KEY_INVALID nor IDEMPOTENCY_KEY_REUSED among its errors,
    // which is the backend saying the same thing.
    final envelope = await _api.post(
      V1Endpoints.bookingOtpRequest(bookingId),
      body: <String, dynamic>{'purpose': purpose.wireName},
    );
    return BookingOtpIssued.fromApiMap(envelope.asMap);
  }

  @override
  Future<BookingTransitionResult> verifyOtp({
    required String bookingId,
    required String code,
    required String idempotencyKey,
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
    String? expectedState,
  }) async {
    final envelope = await _api.post(
      V1Endpoints.bookingOtpVerify(bookingId),
      idempotencyKey: idempotencyKey,
      // `code` is the documented field. `otp` and `workerCode` are accepted
      // aliases kept for shipped builds, and sending one of those instead
      // would be writing new code against a deprecation.
      body: <String, dynamic>{
        'code': code,
        'purpose': purpose.wireName,
        if (expectedState != null) 'expectedState': expectedState,
      },
    );
    return BookingTransitionResult.fromApiMap(envelope.asMap);
  }

  @override
  Future<BookingOtpState> otpStatus({
    required String bookingId,
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
  }) async {
    final envelope = await _api.get(
      V1Endpoints.bookingOtpStatus(bookingId),
      query: <String, dynamic>{'purpose': purpose.wireName},
    );
    return BookingOtpState.fromApiMap(envelope.asMap);
  }

  @override
  Future<BookingRescheduleResult> reschedule({
    required String bookingId,
    required BookingRescheduleRequest request,
  }) async {
    // Also no idempotency key, and for a stronger reason than above: the write
    // carries `schedule IS NOT DISTINCT FROM <expected>`, so a repeat of an
    // applied move is refused with BOOKING_SCHEDULE_CHANGED. The concurrency
    // guard IS the replay guard, and `expectedSchedule` is what arms it —
    // which is why BookingRescheduleRequest always sends it.
    final envelope = await _api.post(
      V1Endpoints.bookingReschedule(bookingId),
      body: request.toJson(),
    );
    return BookingRescheduleResult.fromApiMap(envelope.asMap);
  }

  @override
  Future<List<BookingRescheduleAttempt>> rescheduleHistory(
      String bookingId) async {
    // Same path as the POST; the method distinguishes them.
    final envelope = await _api.get(V1Endpoints.bookingReschedule(bookingId));
    return envelope
        .listAt('requests')
        .map(BookingRescheduleAttempt.fromApiMap)
        .toList(growable: false);
  }
}
