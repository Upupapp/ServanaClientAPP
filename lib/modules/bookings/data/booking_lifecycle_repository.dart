/// Actions on an existing booking: cancel, reschedule, and the OTP ceremony.
///
///     BookingLifecycleRepository
///       → BookingLifecycleCanonicalDataSource      when V1Capability.bookingLifecycle
///       → BookingLifecycleCompatibilityDataSource  otherwise
///
/// [canonical] and [router] are optional. Omitting either pins the repository
/// to the compatibility source, which is what every build does today because
/// `/api/v1` is not deployed.
///
/// ## Why this is not on `BookingRepository`
///
/// Reads and actions migrate on different flags — [V1Capability.bookingReads]
/// and [V1Capability.bookingLifecycle] — because the consequence of routing
/// each at the wrong transport is not comparable. A read from the wrong place
/// renders stale data; an action from the wrong place changes a customer's
/// booking. Putting them on one object would have made a single `_source`
/// getter serve both, and the first person to add an action would have reached
/// for the read flag because it was already there.
///
/// ## Idempotency keys are held here, not minted at the call site
///
/// A key is only worth sending if it survives a retry of the same intent, and
/// a key generated inside the method that sends it never does. So the
/// repository keys them by intent — booking id plus action — and clears the
/// entry once the action has resolved. A widget that taps cancel twice through
/// a flaky connection sends one key twice and gets one cancellation.
library;

import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/request_id.dart';
import 'package:client/modules/bookings/data/booking_lifecycle_data_source.dart';
import 'package:client/modules/bookings/domain/booking_otp_state.dart';
import 'package:client/modules/bookings/domain/booking_reschedule.dart';
import 'package:client/modules/bookings/domain/booking_transition_result.dart';

class BookingLifecycleRepository {
  BookingLifecycleRepository({
    required BookingLifecycleDataSource compatibility,
    BookingLifecycleDataSource? canonical,
    CanonicalRouter? router,
  })  : _compatibility = compatibility,
        _canonical = canonical,
        _router = router;

  final BookingLifecycleDataSource _compatibility;
  final BookingLifecycleDataSource? _canonical;
  final CanonicalRouter? _router;

  /// Live idempotency keys, keyed by intent.
  ///
  /// An entry is created on the first attempt and removed once the action has
  /// resolved either way — including on failure, because a refusal the customer
  /// then corrects (a different cancellation reason, a different time) is a new
  /// intent and must not replay the refused one.
  ///
  /// The exception is a retryable transport failure, where the outcome is
  /// genuinely unknown and reusing the key is the entire point. Those are
  /// re-thrown with the entry left in place.
  final Map<String, String> _intentKeys = <String, String>{};

  BookingLifecycleDataSource get _source {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<BookingLifecycleDataSource>(
      V1Capability.bookingLifecycle,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  /// True when actions are served by `/api/v1`. Diagnostics only.
  bool get isCanonical =>
      _canonical != null &&
      (_router?.isCanonical(V1Capability.bookingLifecycle) ?? false);

  /// Whether the active transport can move a booking.
  ///
  /// A UI must consult this before offering the action. False today on every
  /// build: the only reschedule route that has ever existed is admin-only, so
  /// a customer tapping it would get a 403 for a feature the app appeared to
  /// have. See `docs/convergence-v1/TAB10_CERTIFICATION.md`.
  bool get canOfferReschedule => _source.supportsReschedule;

  /// Whether "resend in 42s" and "2 attempts left" can be rendered from the
  /// backend rather than from a client-side timer.
  bool get hasBackendOtpPolicy => _source.supportsOtpStatus;

  // ── Cancellation ───────────────────────────────────────────────────────────

  /// Cancels [bookingId], naming [reason].
  ///
  /// [expectedState] should be the canonical state the caller last read. It is
  /// optional because not every call site has one, and it is worth passing
  /// wherever one exists: without it the server acts on whatever it finds, and
  /// a booking assigned to a provider in the seconds since the screen loaded is
  /// cancelled rather than flagged.
  Future<BookingTransitionResult> cancel({
    required String bookingId,
    required String reason,
    String? expectedState,
  }) {
    return _withIntentKey(
      intent: 'cancel:$bookingId',
      action: (key) => _source.cancel(
        bookingId: bookingId,
        reason: reason,
        idempotencyKey: key,
        expectedState: expectedState,
      ),
    );
  }

  // ── The OTP ceremony ───────────────────────────────────────────────────────

  /// Current code state — lifetime, attempts left, seconds until resend.
  ///
  /// Never spends an attempt. Under the compatibility transport the returned
  /// state has [BookingOtpState.isBackendDerived] false and every budget null,
  /// so a screen can tell "2 attempts left" from "we do not know".
  Future<BookingOtpState> otpStatus(
    String bookingId, {
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
  }) =>
      _source.otpStatus(bookingId: bookingId, purpose: purpose);

  /// Issues a code.
  ///
  /// No idempotency key on either transport — see the canonical source for
  /// why a key here would let a caller slip past the resend cooldown.
  Future<BookingOtpIssued> requestOtp(
    String bookingId, {
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
  }) =>
      _source.requestOtp(bookingId: bookingId, purpose: purpose);

  /// Presents a code.
  ///
  /// The intent key is scoped to the CODE as well as the booking, so correcting
  /// a mistyped digit is a new intent while retrying the same digits after a
  /// dropped connection is not. Keying on the booking alone would have made a
  /// second, different code replay the first one's rejection.
  Future<BookingTransitionResult> verifyOtp({
    required String bookingId,
    required String code,
    BookingOtpPurpose purpose = BookingOtpPurpose.bookingConfirmation,
    String? expectedState,
  }) {
    return _withIntentKey(
      intent: 'otp:$bookingId:${purpose.wireName}:$code',
      action: (key) => _source.verifyOtp(
        bookingId: bookingId,
        code: code,
        idempotencyKey: key,
        purpose: purpose,
        expectedState: expectedState,
      ),
    );
  }

  // ── Reschedule ─────────────────────────────────────────────────────────────

  /// Proposes a new start time for [bookingId].
  ///
  /// Throws [UnsupportedLifecycleAction] when [canOfferReschedule] is false.
  /// No policy is evaluated here: whether the booking may be moved, whether
  /// enough notice was given and whether the provider is free are all decided
  /// by the backend, which names the rule that refused.
  Future<BookingRescheduleResult> reschedule({
    required String bookingId,
    required BookingRescheduleRequest request,
  }) =>
      _source.reschedule(bookingId: bookingId, request: request);

  /// Every attempt to move [bookingId], accepted or refused.
  Future<List<BookingRescheduleAttempt>> rescheduleHistory(String bookingId) =>
      _source.rescheduleHistory(bookingId);

  // ── Action availability ────────────────────────────────────────────────────

  /// What the customer may do to a booking, preferring the backend's answer.
  ///
  /// [backendActions] is `state.availableActions` from a canonical response —
  /// generated from the same `TRANSITIONS` table the server enforces. When it
  /// is present it wins outright, including when it is EMPTY: an empty list
  /// from the server means the machine permits nothing, and second-guessing it
  /// with a local computation is how a button appears for a request that will
  /// be refused.
  ///
  /// [localFallback] is used only when the backend said nothing at all, which
  /// is the case on every legacy response. That fallback is the client's own
  /// resolver — an approximation, labelled as one by
  /// [BookingActionAvailability.isBackendDerived].
  BookingActionAvailability resolveActions({
    List<String>? backendActions,
    required List<String> localFallback,
    bool terminal = false,
  }) {
    final fromBackend = backendActions != null;
    return BookingActionAvailability(
      actions: fromBackend ? backendActions : localFallback,
      isBackendDerived: fromBackend,
      // Reschedule is not a state-machine transition, so it never appears in
      // availableActions and its absence there proves nothing. The only thing
      // the client can honestly say up front is whether the transport has the
      // endpoint at all; the state rule is the backend's to apply.
      canReschedule: canOfferReschedule && !terminal,
      terminal: terminal,
    );
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<T> _withIntentKey<T>({
    required String intent,
    required Future<T> Function(String key) action,
  }) async {
    final key = _intentKeys[intent] ??= RequestIds.newIdempotencyKey();
    try {
      final result = await action(key);
      _intentKeys.remove(intent);
      return result;
    } on ApiFailure catch (failure) {
      // A retryable failure is the one case where the request may or may not
      // have been applied. Keeping the key is what makes the next attempt a
      // replay instead of a second action.
      if (!failure.isRetryable) _intentKeys.remove(intent);
      rethrow;
    } catch (_) {
      _intentKeys.remove(intent);
      rethrow;
    }
  }
}
