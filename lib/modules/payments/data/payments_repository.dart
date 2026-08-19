/// The one payment ceremony.
///
///     PaymentsRepository
///       → PaymentsCanonicalDataSource      when V1Capability.bookingPayments
///       → PaymentsCompatibilityDataSource  otherwise
///
/// [canonical] and [router] are optional. Omitting either pins the repository
/// to the compatibility source, which is what every build does today because
/// `/api/v1` is not deployed.
///
/// ## What this replaces
///
/// TAB 08 found every booking category running its own create ceremony and
/// collapsed them into one `BookingSubmissionService`. Payments were left out
/// of that, and had grown the same shape:
///
/// | Operation | Copies before this tab |
/// | --- | --- |
/// | start a checkout | **4** — `AirconBookingStore`, `BwBookingStore`, an inline block in `BookingDetailScreen`, plus the raw API method |
/// | is it paid | **3** — both stores, and `PaymentWebViewScreen._verifyPayment` |
///
/// Each copy had its own envelope fallback chain and its own error handling,
/// and they did not agree: two read `data ?? root` for the checkout URL, one
/// read the root only. That is not four features, it is one feature written
/// four times, and the next payment-shaped change would have had to find all
/// four.
///
/// ## Why there is no idempotency-key bookkeeping here
///
/// TAB 10's `BookingLifecycleRepository` holds keys per intent because cancel
/// and OTP verify need them. None of the three payment operations takes one —
/// each has a stronger server-side guard, and the checkout replay protection
/// lives inside the processor call where a client key could not reach. Adding
/// key plumbing here would imply a protection that is not the one actually
/// operating.
library;

import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/payments/data/payments_data_source.dart';
import 'package:client/modules/payments/domain/booking_payment.dart';
import 'package:client/modules/payments/domain/payment_intent.dart';
import 'package:client/modules/payments/domain/refund.dart';

class PaymentsRepository {
  const PaymentsRepository({
    required PaymentsDataSource compatibility,
    PaymentsDataSource? canonical,
    CanonicalRouter? router,
  })  : _compatibility = compatibility,
        _canonical = canonical,
        _router = router;

  final PaymentsDataSource _compatibility;
  final PaymentsDataSource? _canonical;
  final CanonicalRouter? _router;

  PaymentsDataSource get _source {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<PaymentsDataSource>(
      V1Capability.bookingPayments,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  /// True when payments are served by `/api/v1`. Diagnostics only.
  bool get isCanonical =>
      _canonical != null &&
      (_router?.isCanonical(V1Capability.bookingPayments) ?? false);

  /// Whether a customer can ask for a refund at all on this transport.
  ///
  /// A UI must consult this before offering the action. False today on every
  /// build: the legacy API has no customer refund route, and the admin one
  /// answers a customer token with 403.
  bool get canOfferRefund => _source.supportsRefunds;

  /// Whether payment state is read from a payment endpoint.
  ///
  /// False today. When false, [BookingPayment.breakdown] is zeroed and
  /// [BookingPayment.refund] is null — not because the payment has no price,
  /// but because this transport cannot report one. A screen showing a total
  /// must check this rather than render a zero.
  bool get hasPaymentDetail => _source.hasPaymentEndpoint;

  /// Starts or resumes checkout for [bookingId].
  ///
  /// The server returns an existing live session rather than minting a second,
  /// so calling this on a retry is safe and is what the resume-after-crash path
  /// depends on. [PaymentIntent.reused] reports which happened — canonically.
  Future<PaymentIntent> startCheckout(String bookingId) =>
      _source.startCheckout(bookingId);

  /// The booking's payment position.
  Future<BookingPayment> payment(String bookingId) =>
      _source.payment(bookingId);

  /// Whether the booking is settled.
  ///
  /// The narrow question the checkout screen actually polls, kept as its own
  /// method so a caller polling it is not tempted to hold the whole
  /// [BookingPayment] and re-derive the answer differently from everyone else.
  Future<bool> isPaid(String bookingId) async {
    final position = await _source.payment(bookingId);
    return position.isPaid;
  }

  /// Asks for money back.
  ///
  /// On the customer's seat a success means a review row was opened and **no
  /// money has moved** — see [RefundResult.isMoneyMoving]. Throws
  /// [UnsupportedPaymentAction] when [canOfferRefund] is false.
  ///
  /// No eligibility is evaluated here. Whether the payment was captured,
  /// whether a refund is already in progress and how much remains refundable
  /// are all decided by the backend, which names the rule that refused.
  Future<RefundResult> requestRefund({
    required String bookingId,
    required RefundRequest request,
  }) =>
      _source.requestRefund(bookingId: bookingId, request: request);
}
