/// A booking's payment state and price breakdown.
///
/// ## Settlement truth is not lifecycle truth
///
/// The backend says it outright: `state` is *"Settlement truth. SEPARATE from
/// the booking lifecycle state and linked to it."* A CONFIRMED booking is not
/// thereby a paid one — TAB 09 pinned that for `CustomerBooking`, and this type
/// is the other half of it.
///
/// ## Why the client had no type for this at all
///
/// It had no endpoint. TAB 01 recorded it as R-06: *"Payment status is only
/// knowable by re-reading the whole booking."* So the app learned whether a
/// payment had landed by fetching the entire booking and reading whichever of
/// `paymentStatus`, `payment_status` or `payment.status` happened to be
/// present — every five seconds, for up to thirty minutes, on the checkout
/// screen.
///
/// `GET /api/v1/bookings/:bookingId/payment` answers the question that was
/// actually being asked.
///
/// ## Three seats, one calculation
///
/// The same endpoint serves customer, provider and admin, and discloses
/// different fields to each — the provider never sees the refund position, the
/// customer never sees the provider share. *"The CALCULATION is the same object
/// for all three, so no two seats can be told different totals."*
///
/// This client is the customer's, so [earning], [payout], `provider` and
/// `servana` are deliberately **not modelled**. A field a customer app cannot
/// receive is a field it must not have a parser for: the parser would be the
/// thing that made a disclosure bug invisible.
library;

import 'package:client/common/domain/time/iso_timestamp.dart';

/// Settlement state, as the backend enumerates it.
///
/// Six values. `PaymentStatusParser` — the string-matching helper this replaces
/// — knew three, and treated everything else as neither paid nor payable. A
/// `REFUNDING` booking and a booking with no payment row at all produced the
/// same answer from it.
enum PaymentState {
  pending('PENDING'),
  paid('PAID'),
  failed('FAILED'),

  /// The payment was declined or the proof was rejected on review.
  rejected('REJECTED'),

  /// A refund has been issued and its settlement is not yet confirmed.
  refunding('REFUNDING'),

  refunded('REFUNDED'),

  /// The wire carried a value this build does not know.
  ///
  /// Deliberately distinct from [pending]. Mapping an unrecognised state onto
  /// a known one is how a client offers "Pay now" for a booking the server
  /// considers settled.
  unknown('UNKNOWN');

  const PaymentState(this.wireName);

  final String wireName;

  static PaymentState fromWire(Object? raw) {
    final name = '${raw ?? ''}'.toUpperCase().trim();
    for (final s in PaymentState.values) {
      if (s.wireName == name) return s;
    }
    // The legacy vocabulary, which prefixes the two it carries.
    if (name == 'PAYMENT_PAID') return PaymentState.paid;
    if (name == 'PAYMENT_FAILED') return PaymentState.failed;
    return PaymentState.unknown;
  }

  /// Whether offering the customer a checkout makes sense.
  ///
  /// Only two states qualify. `REJECTED` is excluded on purpose: a rejected
  /// GCash proof needs support, not another attempt at the same payment, and
  /// the backend would refuse the intent with `PAYMENT_STATE_CONFLICT`.
  bool get invitesPayment =>
      this == PaymentState.pending || this == PaymentState.failed;

  /// Money has been taken and not yet returned.
  bool get isSettled => this == PaymentState.paid;

  /// Anything a refund conversation could apply to.
  bool get hasMoneyMoved =>
      this == PaymentState.paid ||
      this == PaymentState.refunding ||
      this == PaymentState.refunded;
}

/// What the customer is being charged, and why.
///
/// *"Backend-computed. Clients display it and never recompute it."* There is no
/// arithmetic in this class for that reason — not even `basePrice +
/// additionalWork`, which would be a second opinion on a total the server
/// already sent.
class PaymentBreakdown {
  const PaymentBreakdown({
    required this.gross,
    this.grossMinor,
    this.basePrice,
    this.additionalWork,
  });

  /// Base price plus PAID additional work.
  final double gross;

  /// The same figure in centavos, which is the one to compare and to send.
  /// Peso amounts are for display; equality on a double is not a money check.
  final int? grossMinor;

  final double? basePrice;

  /// Charged through its own checkout, so it can be non-zero while the base
  /// price is already settled.
  final double? additionalWork;

  static PaymentBreakdown fromApiMap(Map<String, dynamic> json) =>
      PaymentBreakdown(
        gross: _double(json['gross']) ?? 0,
        grossMinor: _int(json['grossMinor']),
        basePrice: _double(json['basePrice']),
        additionalWork: _double(json['additionalWork']),
      );
}

/// What has been returned and what still could be. Customer and admin only.
class RefundPosition {
  const RefundPosition({
    this.refundedAmount = 0,
    this.refundedAt,
    this.refundable = 0,
    this.refundableMinor,
  });

  final double refundedAmount;
  final DateTime? refundedAt;

  /// Captured minus already refunded. Never below zero.
  ///
  /// The ceiling is the server's, and it is the reason a second full refund is
  /// *"refused by arithmetic rather than by anyone remembering to check"*. The
  /// client reads it to size a request; it does not compute it.
  final double refundable;

  final int? refundableMinor;

  bool get hasRefundableBalance => refundable > 0;

  static RefundPosition fromApiMap(Map<String, dynamic> json) => RefundPosition(
        refundedAmount: _double(json['refundedAmount']) ?? 0,
        refundedAt: parseBackendTimestamp(json['refundedAt']),
        refundable: _double(json['refundable']) ?? 0,
        refundableMinor: _int(json['refundableMinor']),
      );
}

class BookingPayment {
  const BookingPayment({
    required this.bookingId,
    required this.state,
    required this.captured,
    required this.breakdown,
    this.currency = 'PHP',
    this.method,
    this.paidAt,
    this.refund,
    this.isBackendDerived = true,
  });

  final String bookingId;
  final String currency;
  final PaymentState state;

  /// Whether the money is actually in hand.
  ///
  /// Carried separately from [state] because the backend does. A state can
  /// imply capture; this says it.
  final bool captured;

  final String? method;
  final DateTime? paidAt;
  final PaymentBreakdown breakdown;

  /// Null when the transport could not say — which on legacy is always.
  final RefundPosition? refund;

  /// False when this was assembled by reading a booking rather than by asking
  /// the payment endpoint. On that path [breakdown] and [refund] are unknown,
  /// and a screen must not present a total it did not receive.
  final bool isBackendDerived;

  bool get isPaid => state.isSettled;
  bool get invitesPayment => state.invitesPayment;

  static BookingPayment fromApiMap(Map<String, dynamic> json) {
    final refundRaw = json['refund'];
    return BookingPayment(
      bookingId: '${json['bookingId'] ?? ''}',
      currency: '${json['currency'] ?? 'PHP'}',
      state: PaymentState.fromWire(json['state']),
      captured: json['captured'] == true,
      method: json['method']?.toString(),
      paidAt: parseBackendTimestamp(json['paidAt']),
      breakdown: PaymentBreakdown.fromApiMap(
        json['breakdown'] is Map
            ? Map<String, dynamic>.from(json['breakdown'] as Map)
            : const <String, dynamic>{},
      ),
      refund: refundRaw is Map
          ? RefundPosition.fromApiMap(Map<String, dynamic>.from(refundRaw))
          : null,
    );
  }

  /// Reads a payment position out of a whole-booking payload.
  ///
  /// This is R-06 made explicit rather than fixed: the legacy transport has no
  /// payment endpoint, so the only way to learn the state is to fetch the
  /// booking and look for whichever key it happens to carry. The three-key
  /// fallback is inherited from `PaymentStatusParser` and each branch exists
  /// because a route was observed returning that shape.
  ///
  /// [captured] is inferred from the state, not read — the legacy booking
  /// payload has no such field. [breakdown] is zero and [refund] is null,
  /// because neither is knowable here. `isBackendDerived: false` says so.
  static BookingPayment fromBookingMap(
    Map<String, dynamic> booking, {
    required String bookingId,
  }) {
    final payment = booking['payment'];
    final raw = booking['paymentStatus'] ??
        booking['payment_status'] ??
        (payment is Map ? payment['status'] : null);
    final state = PaymentState.fromWire(raw);

    return BookingPayment(
      bookingId: bookingId,
      state: state,
      captured: state.isSettled,
      method: booking['paymentMethodUsed']?.toString() ??
          booking['paymentMethod']?.toString(),
      breakdown: const PaymentBreakdown(gross: 0),
      isBackendDerived: false,
    );
  }
}

double? _double(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
