abstract final class PaymentStatusParser {
  static String fromBooking(Map<String, dynamic> booking) {
    final payment = booking['payment'];
    final raw = booking['paymentStatus'] ??
        booking['payment_status'] ??
        (payment is Map ? payment['status'] : null);
    return normalize(raw?.toString());
  }

  static String normalize(String? rawStatus) {
    final status = rawStatus?.toUpperCase().trim() ?? '';
    return switch (status) {
      'PAYMENT_PAID' => 'PAID',
      'PAYMENT_FAILED' => 'FAILED',
      _ => status,
    };
  }

  static bool isPaid(Map<String, dynamic> booking) {
    final status = fromBooking(booking);
    return status == 'PAID';
  }

  static bool requiresPayment(String? rawStatus) {
    final status = normalize(rawStatus);
    return status == 'PENDING' || status == 'FAILED';
  }
}
