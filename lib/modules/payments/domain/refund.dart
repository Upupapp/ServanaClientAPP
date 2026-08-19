/// Asking for money back.
///
/// ## A customer REQUESTS; only an admin ISSUES
///
/// The distinction is the whole of this file. From the backend:
///
/// > One rule, two outcomes. A customer REQUESTS (a review row, no processor
/// > call) and an admin ISSUES (money moves). Both run
/// > `evaluateRefundEligibility` first, so a request can never be accepted for
/// > a booking an issue would refuse.
///
/// So a successful customer refund call means **an admin will look at this**.
/// It does not mean money has moved, and a UI that says "Refunded" on the back
/// of an `outcome: 'requested'` is telling the customer something false about
/// their own money. [RefundResult.isMoneyMoving] exists to make that hard to
/// get wrong.
///
/// ## Which triggers a customer may cite
///
/// Narrower than an admin's, and enforced server-side: a trigger whose
/// `initiators` do not include `customer` is refused with
/// `REFUND_OUTCOME_NOT_REFUNDABLE`. The subset is mirrored here because a
/// trigger has to be pickable before a request exists — the same reasoning,
/// and the same limit, as the reschedule reasons in TAB 10. No eligibility
/// rule is mirrored: capture state, the refundable ceiling and double-refund
/// prevention all stay on the server.
library;

/// Why a refund is being asked for.
enum RefundTrigger {
  customerCancelled(
    'CUSTOMER_CANCELLED',
    'I cancelled this booking',
    customerMayCite: true,
  ),
  providerCancelled(
    'PROVIDER_CANCELLED',
    'The provider cancelled',
    customerMayCite: true,
  ),
  serviceNotDelivered(
    'SERVICE_NOT_DELIVERED',
    'The service was not performed',
    customerMayCite: true,
  ),
  duplicatePayment(
    'DUPLICATE_PAYMENT',
    'I was charged twice',
    customerMayCite: true,
  ),

  // Admin-only. Modelled so a result carrying one can be READ — an admin may
  // have issued a refund the customer is now looking at — and never offered.
  adminCancelled('ADMIN_CANCELLED', 'Cancelled by Servana',
      customerMayCite: false),
  disputeUpheld('DISPUTE_UPHELD', 'Dispute resolved in your favour',
      customerMayCite: false),
  adminDiscretion('ADMIN_DISCRETION', 'Goodwill refund',
      customerMayCite: false);

  const RefundTrigger(this.wireName, this.label,
      {required this.customerMayCite});

  final String wireName;

  /// Customer-facing copy. The wire names are operator vocabulary.
  final String label;

  /// Whether `REFUND_TRIGGERS[…].initiators` includes `customer`.
  ///
  /// Offering an admin-only trigger would produce a refusal the customer can do
  /// nothing about, on a screen about their money.
  final bool customerMayCite;

  static List<RefundTrigger> get customerChoices => RefundTrigger.values
      .where((t) => t.customerMayCite)
      .toList(growable: false);

  static RefundTrigger? fromWire(Object? raw) {
    final name = '${raw ?? ''}'.toUpperCase().trim();
    for (final t in RefundTrigger.values) {
      if (t.wireName == name) return t;
    }
    return null;
  }
}

class RefundRequest {
  const RefundRequest({
    required this.trigger,
    this.amount,
    this.reason,
  });

  final RefundTrigger trigger;

  /// Omit for the whole remaining refundable balance.
  ///
  /// Omitting is the default and the safer one: the ceiling is
  /// `captured - alreadyRefunded`, computed server-side, and a client that
  /// names a figure can only ever name a stale one.
  final double? amount;

  final String? reason;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'trigger': trigger.wireName,
        if (amount != null) 'amount': amount,
        if (reason != null && reason!.trim().isNotEmpty)
          'reason': reason!.trim(),
      };
}

class RefundResult {
  const RefundResult({
    required this.bookingId,
    required this.outcome,
    required this.amount,
    this.trigger,
    this.amountMinor,
    this.currency = 'PHP',
    this.reference,
    this.refundReviewId,
    this.reversesProviderEarning = false,
  });

  final String bookingId;

  /// `requested`, `issued` or `pending_processor`.
  final String outcome;

  final RefundTrigger? trigger;
  final double amount;
  final int? amountMinor;
  final String currency;

  /// A Servana handle support can discuss. Never the processor's refund id.
  final String? reference;

  /// The review row an admin will decide on. Present on the customer path.
  final int? refundReviewId;

  final bool reversesProviderEarning;

  /// The customer path: a review was opened and no processor was called.
  bool get isRequestOnly => outcome.toLowerCase() == 'requested';

  /// Money has actually moved or is moving.
  ///
  /// False for a customer request, and that is the point. Wording a request as
  /// a completed refund is the single most damaging thing this screen could
  /// say, because the customer then waits for money that is not coming until
  /// somebody approves it.
  bool get isMoneyMoving => !isRequestOnly;

  /// Accepted, settlement not yet confirmed.
  bool get isPendingProcessor => outcome.toLowerCase() == 'pending_processor';

  static RefundResult fromApiMap(Map<String, dynamic> json,
      {required String bookingId}) {
    return RefundResult(
      bookingId: '${json['bookingId'] ?? bookingId}',
      outcome: '${json['outcome'] ?? ''}',
      trigger: RefundTrigger.fromWire(json['trigger']),
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse('${json['amount'] ?? ''}') ?? 0,
      amountMinor: json['amountMinor'] is num
          ? (json['amountMinor'] as num).toInt()
          : null,
      currency: '${json['currency'] ?? 'PHP'}',
      reference: json['reference']?.toString(),
      refundReviewId: json['refundReviewId'] is num
          ? (json['refundReviewId'] as num).toInt()
          : null,
      reversesProviderEarning: json['reversesProviderEarning'] == true,
    );
  }
}
