/// Payments over the canonical `/api/v1/bookings/:id/*` finance routes.
///
/// ## Not reachable in any shipped build
///
/// Selected only when
/// `CanonicalAvailability.isAvailable(V1Capability.bookingPayments)`, which
/// requires `--dart-define=CANONICAL_V1_ENABLED=true` AND `bookingPayments` in
/// `CANONICAL_V1_CAPABILITIES`. No production build passes either.
///
/// ## What moving here buys
///
/// 1. **Payment state stops costing a whole booking.** The legacy path has no
///    payment endpoint, so the checkout screen polls `GET /api/:id` every five
///    seconds for up to thirty minutes to read one field. This asks the
///    question directly, and gets the price breakdown and refundable balance
///    with it.
/// 2. **The checkout call becomes booking-scoped.** The contract is explicit:
///    this entry *"adds the booking-scoped authorization and refuses a
///    provider, which the legacy route does not do."*
/// 3. **A customer can ask for a refund.** There is no legacy route for that
///    at all — the only refund path today is the admin portal's.
///
/// ## No idempotency key, on any of the three
///
/// Unusual enough to state, since TAB 10 established the opposite habit for
/// booking actions. Each has a stronger guard of its own, and none lists the
/// idempotency error codes:
///
///  - **checkout** — an advisory transaction lock on the booking, reuse of a
///    live session for the same return origin, and a processor
///    `Idempotency-Key` derived from the payment row and its attempt counter.
///    The replay protection is *inside* the processor call, where a client key
///    could not reach.
///  - **refund** — eligibility is `captured - alreadyRefunded`, so a second
///    full refund computes a ceiling of zero and is *"refused by arithmetic"*.
///    A customer repeat returns the SAME open review row.
///  - **payment read** — a GET.
library;

import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/payments/data/payments_data_source.dart';
import 'package:client/modules/payments/domain/booking_payment.dart';
import 'package:client/modules/payments/domain/payment_intent.dart';
import 'package:client/modules/payments/domain/refund.dart';

class PaymentsCanonicalDataSource implements PaymentsDataSource {
  const PaymentsCanonicalDataSource(this._api);

  final V1ApiClient _api;

  @override
  bool get supportsRefunds => true;

  @override
  bool get hasPaymentEndpoint => true;

  @override
  Future<PaymentIntent> startCheckout(String bookingId) async {
    // An EMPTY body, deliberately.
    //
    // `PaymentIntentRequest` has exactly one optional property, `returnOrigin`,
    // and it is *"matched against a SERVER-SIDE allowlist. Never used as a
    // URL."* A mobile app has no origin worth nominating, and sending one would
    // be the client expressing a preference about where a payer is returned to
    // — the precise thing the allowlist exists to take out of a caller's hands.
    final envelope = await _api.post(V1Endpoints.bookingPaymentIntents(bookingId));
    return PaymentIntent.fromApiMap(envelope.asMap, bookingId: bookingId);
  }

  @override
  Future<BookingPayment> payment(String bookingId) async {
    final envelope = await _api.get(V1Endpoints.bookingPayment(bookingId));
    return BookingPayment.fromApiMap(envelope.asMap);
  }

  @override
  Future<RefundResult> requestRefund({
    required String bookingId,
    required RefundRequest request,
  }) async {
    final envelope = await _api.post(
      V1Endpoints.bookingRefunds(bookingId),
      body: request.toJson(),
    );
    return RefundResult.fromApiMap(envelope.asMap, bookingId: bookingId);
  }
}
