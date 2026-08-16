/// The booking verification code, as the backend describes it.
///
/// ## Why this type exists rather than a bare bool
///
/// The OTP screen has always owned a 60-second resend cooldown as a private
/// constant, counted down by a local `Timer`. That number is a copy of an
/// operator policy the backend also holds, and the two were never checked
/// against each other. Three things follow from a client-side copy:
///
///  - it is wrong the moment the policy changes, and nothing fails loudly;
///  - it resets when the screen is disposed, so leaving and returning grants a
///    fresh resend the server will refuse with `BOOKING_OTP_RESEND_COOLDOWN`;
///  - it cannot express the two limits the client never modelled at all — the
///    per-booking issue ceiling and the verify-attempt budget — so a customer
///    is told "Resend code" right up to the request that fails.
///
/// `GET /api/v1/bookings/:id/otp/status` exists precisely so a client renders
/// "resend in 42s" and "2 attempts left" from the backend. The contract says
/// so: *"the same argument availableActions makes for buttons."*
///
/// ## What is deliberately absent
///
/// The code. It is never in any response, in any field, for any actor —
/// [present] says whether one exists, and that is the most this type will ever
/// know.
library;

import 'package:client/common/domain/time/iso_timestamp.dart';

/// Which code, and therefore which column and which permitted actor.
///
/// A code is scoped to a booking AND a purpose: `BOOKING_CONFIRMATION` is
/// presented by the customer against `otp_code`, `SERVICE_START` is presented
/// by the assigned provider against `worker_code`. One cannot satisfy the
/// other. The customer app only ever requests the first, and the second is
/// modelled so a `BOOKING_OTP_PURPOSE_INVALID` is impossible to produce by
/// typo rather than merely unlikely.
enum BookingOtpPurpose {
  bookingConfirmation('BOOKING_CONFIRMATION'),
  serviceStart('SERVICE_START');

  const BookingOtpPurpose(this.wireName);

  final String wireName;

  static BookingOtpPurpose fromWire(Object? raw) {
    final name = '${raw ?? ''}'.toUpperCase();
    for (final p in BookingOtpPurpose.values) {
      if (p.wireName == name) return p;
    }
    return BookingOtpPurpose.bookingConfirmation;
  }
}

/// Everything a screen needs to render the resend affordance truthfully.
class BookingOtpState {
  const BookingOtpState({
    required this.bookingId,
    required this.purpose,
    required this.resendAvailableInSeconds,
    this.issuedAt,
    this.expiresAt,
    this.expired = false,
    this.present = false,
    this.attemptsRemaining,
    this.issuesRemaining,
    this.expiryMinutes,
    this.resendCooldownSeconds,
    this.maxVerifyAttempts,
    this.maxIssues,
    this.canRequest = true,
    this.canVerify = true,
    this.isBackendDerived = true,
  });

  final String bookingId;
  final BookingOtpPurpose purpose;

  /// Seconds until a resend is permitted. Zero means now.
  final int resendAvailableInSeconds;

  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final bool expired;

  /// Whether a code is currently on the booking. Never the code.
  final bool present;

  /// Null when unknown — which under the compatibility transport it always is.
  /// Null and zero are different facts and a screen must not render them the
  /// same way: zero means "no attempts left", null means "we cannot say".
  final int? attemptsRemaining;
  final int? issuesRemaining;

  final int? expiryMinutes;
  final int? resendCooldownSeconds;
  final int? maxVerifyAttempts;
  final int? maxIssues;

  /// The backend's own verdict on whether this actor may act at all, which is
  /// not the same question as whether a cooldown has elapsed.
  final bool canRequest;
  final bool canVerify;

  /// False when this was assembled locally because no canonical status call
  /// was available. A screen may use it to avoid claiming precision it does
  /// not have — "Resend code" rather than "2 attempts left".
  final bool isBackendDerived;

  bool get canResendNow => canRequest && resendAvailableInSeconds <= 0;

  /// True only when the backend said so. An unknown budget is not an exhausted
  /// one, and treating it as exhausted would disable a button that works.
  bool get attemptsExhausted =>
      attemptsRemaining != null && attemptsRemaining! <= 0;

  static BookingOtpState fromApiMap(Map<String, dynamic> json) {
    final policyRaw = json['policy'];
    final policy = policyRaw is Map
        ? Map<String, dynamic>.from(policyRaw)
        : const <String, dynamic>{};

    return BookingOtpState(
      bookingId: '${json['bookingId'] ?? ''}',
      purpose: BookingOtpPurpose.fromWire(json['purpose']),
      resendAvailableInSeconds: _int(json['resendAvailableInSeconds']) ?? 0,
      issuedAt: parseBackendTimestamp(json['issuedAt']),
      expiresAt: parseBackendTimestamp(json['expiresAt']),
      expired: json['expired'] == true,
      present: json['present'] == true,
      attemptsRemaining: _int(json['attemptsRemaining']),
      issuesRemaining: _int(json['issuesRemaining']),
      expiryMinutes: _int(policy['expiryMinutes']),
      resendCooldownSeconds: _int(policy['resendCooldownSeconds']),
      maxVerifyAttempts: _int(policy['maxVerifyAttempts']),
      maxIssues: _int(policy['maxIssues']),
      // Absent means permitted: the backend omits these only on a payload that
      // predates them, and denying on absence would break the screen against a
      // server that is working.
      canRequest: policy['canRequest'] != false,
      canVerify: policy['canVerify'] != false,
    );
  }

  /// The honest local state for the compatibility transport.
  ///
  /// There is no legacy status route, so nothing here is measured. The cooldown
  /// is the client's own timer — the same 60 seconds the screen has always
  /// used, now named as a client assumption instead of passing for policy —
  /// and every budget is null, because "unknown" is what the legacy transport
  /// can truthfully report.
  const BookingOtpState.local({
    required this.bookingId,
    required this.resendAvailableInSeconds,
  })  : purpose = BookingOtpPurpose.bookingConfirmation,
        issuedAt = null,
        expiresAt = null,
        expired = false,
        present = true,
        attemptsRemaining = null,
        issuesRemaining = null,
        expiryMinutes = null,
        resendCooldownSeconds = legacyResendCooldownSeconds,
        maxVerifyAttempts = null,
        maxIssues = null,
        canRequest = true,
        canVerify = true,
        isBackendDerived = false;

  /// The cooldown the client has always applied to itself, retained ONLY for
  /// the legacy path. Under the canonical transport the server's
  /// `resendAvailableInSeconds` is used and this constant is not consulted.
  static const int legacyResendCooldownSeconds = 60;

  BookingOtpState copyWith({int? resendAvailableInSeconds}) => BookingOtpState(
        bookingId: bookingId,
        purpose: purpose,
        resendAvailableInSeconds:
            resendAvailableInSeconds ?? this.resendAvailableInSeconds,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        expired: expired,
        present: present,
        attemptsRemaining: attemptsRemaining,
        issuesRemaining: issuesRemaining,
        expiryMinutes: expiryMinutes,
        resendCooldownSeconds: resendCooldownSeconds,
        maxVerifyAttempts: maxVerifyAttempts,
        maxIssues: maxIssues,
        canRequest: canRequest,
        canVerify: canVerify,
        isBackendDerived: isBackendDerived,
      );

  static int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
}

/// The receipt from requesting a code.
///
/// Carries the next resend window so a screen that has just resent does not
/// have to issue a second call to learn when it may offer the button again.
class BookingOtpIssued {
  const BookingOtpIssued({
    required this.bookingId,
    required this.purpose,
    this.delivery,
    this.recipient,
    this.expiresAt,
    this.resendAvailableAt,
    this.issuesRemaining,
    this.attemptsRemaining,
  });

  final String bookingId;
  final BookingOtpPurpose purpose;

  /// `email` or `booking_detail` — how the recipient gets it.
  final String? delivery;
  final String? recipient;

  final DateTime? expiresAt;
  final DateTime? resendAvailableAt;
  final int? issuesRemaining;
  final int? attemptsRemaining;

  static BookingOtpIssued fromApiMap(Map<String, dynamic> json) {
    return BookingOtpIssued(
      bookingId: '${json['bookingId'] ?? ''}',
      purpose: BookingOtpPurpose.fromWire(json['purpose']),
      delivery: json['delivery']?.toString(),
      recipient: json['recipient']?.toString(),
      expiresAt: parseBackendTimestamp(json['expiresAt']),
      resendAvailableAt: parseBackendTimestamp(json['resendAvailableAt']),
      issuesRemaining: BookingOtpState._int(json['issuesRemaining']),
      attemptsRemaining: BookingOtpState._int(json['attemptsRemaining']),
    );
  }

  /// Seconds from [now] until a resend is permitted, floored at zero.
  ///
  /// Computed against a caller-supplied instant rather than `DateTime.now()`
  /// so a test can pin it, and clamped because a clock skewed forward would
  /// otherwise produce a negative countdown that renders as text.
  int resendInSeconds(DateTime now) {
    final at = resendAvailableAt;
    if (at == null) return 0;
    final seconds = at.difference(now).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }
}
