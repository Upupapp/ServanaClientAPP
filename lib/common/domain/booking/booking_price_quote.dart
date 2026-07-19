/// Typed price quote returned by the Servana backend.
///
/// Use [BookingPriceQuote.fromJson] to parse the /api/quote response.
/// Always treat the backend as authoritative — never trust client-computed totals.
class BookingPriceQuote {
  const BookingPriceQuote({
    required this.currency,
    required this.estimatedTotal,
    this.basePrice,
    this.addonTotal,
    this.serviceFee,
    this.travelFee,
    this.tax,
    this.discount,
    this.quoteId,
    this.createdAt,
  });

  final String currency;

  /// Server-computed estimated total in major currency units (e.g. PHP 1500.00).
  final double estimatedTotal;

  final double? basePrice;
  final double? addonTotal;
  final double? serviceFee;
  final double? travelFee;
  final double? tax;
  final double? discount;
  final String? quoteId;
  final DateTime? createdAt;

  /// Expiry window: 15 minutes. If stale, revalidate before submission.
  static const _validityWindow = Duration(minutes: 15);

  bool get isExpired {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt!) > _validityWindow;
  }

  /// Format as Philippine Peso for display.
  String get displayTotal => '₱${estimatedTotal.toStringAsFixed(2)}';

  /// Whether the displayed amount is estimated (true) or final (false).
  bool get isEstimate => tax == null && serviceFee == null;

  static BookingPriceQuote fromJson(Map<String, dynamic> json) {
    final quote = json['quote'] ?? json['data'] ?? json;
    if (quote is! Map) {
      return const BookingPriceQuote(currency: 'PHP', estimatedTotal: 0);
    }
    final q = quote as Map<String, dynamic>;

    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return BookingPriceQuote(
      currency: (q['currency'] ?? 'PHP').toString(),
      estimatedTotal: toDouble(
        q['final'] ?? q['finalPrice'] ?? q['total'] ?? q['totalAmount'] ?? q['amount'],
      ),
      basePrice: q.containsKey('base') ? toDouble(q['base']) : null,
      addonTotal: q.containsKey('addonTotal') ? toDouble(q['addonTotal']) : null,
      serviceFee: q.containsKey('serviceFee') ? toDouble(q['serviceFee']) : null,
      travelFee: q.containsKey('travelFee') ? toDouble(q['travelFee']) : null,
      tax: q.containsKey('tax') ? toDouble(q['tax']) : null,
      discount: q.containsKey('discount') ? toDouble(q['discount']) : null,
      quoteId: q['quoteId']?.toString(),
      createdAt: DateTime.now(),
    );
  }

  BookingPriceQuote copyWith({double? estimatedTotal}) {
    return BookingPriceQuote(
      currency: currency,
      estimatedTotal: estimatedTotal ?? this.estimatedTotal,
      basePrice: basePrice,
      addonTotal: addonTotal,
      serviceFee: serviceFee,
      travelFee: travelFee,
      tax: tax,
      discount: discount,
      quoteId: quoteId,
      createdAt: createdAt,
    );
  }
}
