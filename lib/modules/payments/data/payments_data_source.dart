/// The contract both payment transports satisfy.
///
///     PaymentsRepository
///       → PaymentsCanonicalDataSource      when V1Capability.bookingPayments
///       → PaymentsCompatibilityDataSource  otherwise
///       → the same domain objects either way
///
/// ## Three operations, and only one of them exists on legacy
///
/// | Operation | Legacy | Canonical |
/// | --- | --- | --- |
/// | start checkout | `POST /api/:id/paymongo/create` | `POST /api/v1/bookings/:id/payment-intents` |
/// | read payment state | **no endpoint** — re-read the whole booking | `GET /api/v1/bookings/:id/payment` |
/// | request a refund | **no endpoint at all** | `POST /api/v1/bookings/:id/refunds` |
///
/// The middle row is TAB 01's R-06 and the reason this boundary is worth
/// building for a read as well as for the writes. The bottom row is why
/// [supportsRefunds] is on the interface: the contract says the canonical
/// entry *"adds the customer-initiated path, which had no route at all"*.
library;

import 'package:client/modules/payments/domain/booking_payment.dart';
import 'package:client/modules/payments/domain/payment_intent.dart';
import 'package:client/modules/payments/domain/refund.dart';

/// Thrown when a caller invokes an operation the active transport does not
/// have.
///
/// An `Error`, not an `ApiFailure`: no request was made and nothing was
/// refused. Reaching it means the caller skipped
/// [PaymentsDataSource.supportsRefunds].
class UnsupportedPaymentAction extends UnsupportedError {
  UnsupportedPaymentAction(String action)
      : super('$action is not available on the legacy transport. '
            'Check supportsRefunds before offering it.');
}

abstract interface class PaymentsDataSource {
  /// Whether this transport can accept a customer refund request.
  bool get supportsRefunds;

  /// Whether payment state comes from a payment endpoint rather than from
  /// re-reading the booking.
  ///
  /// False on legacy, where the breakdown and the refundable balance are not
  /// merely absent from the response — they are unknowable, and a screen must
  /// not render a total it did not receive.
  bool get hasPaymentEndpoint;

  /// Starts or resumes the customer checkout for [bookingId].
  ///
  /// Returns the same URL rather than a second payable session when a live one
  /// exists; [PaymentIntent.reused] says which happened.
  Future<PaymentIntent> startCheckout(String bookingId);

  /// The booking's payment state, and — canonically — its price breakdown and
  /// refund position.
  Future<BookingPayment> payment(String bookingId);

  /// Asks for money back.
  ///
  /// On the customer's seat this opens a review row and calls no processor.
  /// Throws [UnsupportedPaymentAction] when [supportsRefunds] is false.
  Future<RefundResult> requestRefund({
    required String bookingId,
    required RefundRequest request,
  });
}
