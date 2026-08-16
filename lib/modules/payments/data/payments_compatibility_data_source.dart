/// Payments as the app does them today.
///
/// This is the source every shipped build uses, and it is assembled from the
/// two calls already in [ServanaApiClient] — `createPaymongoSession` and
/// `getBooking`.
///
/// ## Reading a payment costs a whole booking
///
/// There is no legacy payment endpoint. TAB 01 recorded it as R-06 and the
/// consequence is visible on the checkout screen: to learn whether one field
/// changed, the app fetches the entire booking, every five seconds, for up to
/// thirty minutes.
///
/// That is preserved here rather than fixed, because it is the only thing this
/// transport can do. What changes is that it now happens in ONE place behind a
/// named method, instead of in three — `AirconBookingStore.verifyPaymentStatus`,
/// `BwBookingStore.verifyPaymentStatus` and
/// `PaymentWebViewScreen._verifyPayment` each had their own copy of the same
/// fetch-and-parse, and each had its own envelope fallback chain.
///
/// ## `reused` is unknowable here, so it is reported false
///
/// The legacy route returns a checkout URL and nothing about whether it minted
/// a session or handed back a live one. False is the honest default: it claims
/// nothing. Callers that care must check [hasPaymentEndpoint] first.
///
/// ## Refunds do not exist on this transport
///
/// Not "are awkward" — there is no customer refund route in the legacy API at
/// all. The canonical entry *"adds the customer-initiated path, which had no
/// route at all"*. So [supportsRefunds] is false and the call throws a
/// programming error rather than a customer-facing one.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/payments/data/payments_data_source.dart';
import 'package:client/modules/payments/domain/booking_payment.dart';
import 'package:client/modules/payments/domain/payment_intent.dart';
import 'package:client/modules/payments/domain/refund.dart';

class PaymentsCompatibilityDataSource implements PaymentsDataSource {
  const PaymentsCompatibilityDataSource(this._api);

  final ServanaApiClient _api;

  @override
  bool get supportsRefunds => false;

  @override
  bool get hasPaymentEndpoint => false;

  @override
  Future<PaymentIntent> startCheckout(String bookingId) async {
    final result =
        await _api.createPaymongoSession(bookingId: int.parse(bookingId));

    // `data` or the root. Inherited from both booking stores, which each
    // carried this fallback because the route was observed returning both.
    final payload = result['data'] is Map
        ? Map<String, dynamic>.from(result['data'] as Map)
        : result;

    return PaymentIntent.fromApiMap(payload, bookingId: bookingId);
  }

  @override
  Future<BookingPayment> payment(String bookingId) async {
    final result = await _api.getBooking(int.parse(bookingId));

    final booking = result['booking'] is Map
        ? Map<String, dynamic>.from(result['booking'] as Map)
        : (result['data'] is Map
            ? Map<String, dynamic>.from(result['data'] as Map)
            : result);

    return BookingPayment.fromBookingMap(booking, bookingId: bookingId);
  }

  @override
  Future<RefundResult> requestRefund({
    required String bookingId,
    required RefundRequest request,
  }) async =>
      throw UnsupportedPaymentAction('refund request');
}
