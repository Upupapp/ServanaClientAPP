/// A started or resumed customer checkout.
///
/// ## `reused` is the field that matters
///
/// *"true when an existing live session was returned instead of a new one. A
/// replay produces the same URL rather than a second payable session."*
///
/// The client had no way to know. Both booking stores persist the checkout URL
/// to `DraftRepository` so a customer can resume payment after a crash, and
/// both call `createPaymongoSession` again on retry — so the app was already
/// relying on the server's replay behaviour without being able to observe it.
/// If that behaviour ever regressed, the symptom would be a customer holding
/// two payable sessions for one booking, and nothing in the client would have
/// noticed.
///
/// ## The return origin is not the client's to choose
///
/// `PaymentIntentRequest.returnOrigin` is *"an optional hint, matched against a
/// SERVER-SIDE allowlist. Never used as a URL — a caller-supplied return target
/// would let a payer be returned to another application."*
///
/// This client sends nothing. A mobile app has no origin to nominate, the
/// server picks from its allowlist, and an empty request is the shape that
/// cannot be wrong. The field is documented here rather than modelled so the
/// next person to reach for it reads the reason first.
library;

class PaymentIntent {
  const PaymentIntent({
    required this.bookingId,
    required this.checkoutUrl,
    this.reused = false,
  });

  final String bookingId;

  /// Always a `checkout.paymongo.com` URL.
  ///
  /// Not trusted on that basis: `PaymentWebViewScreen` re-checks the scheme and
  /// the host against its own allowlist before loading anything, because a
  /// contract note is not an input validator.
  final String checkoutUrl;

  /// True when the server returned an existing live session rather than
  /// minting a second.
  final bool reused;

  bool get isUsable => checkoutUrl.trim().isNotEmpty;

  static PaymentIntent fromApiMap(Map<String, dynamic> json,
      {required String bookingId}) {
    // `checkout_url` is the legacy spelling and stays in the chain: the
    // compatibility source parses the same shape and a released binary may be
    // pointed at either. Reading `checkoutUrl` first is what lets the alias be
    // dropped eventually.
    final url = json['checkoutUrl']?.toString() ??
        json['checkout_url']?.toString() ??
        '';
    return PaymentIntent(
      bookingId: '${json['bookingId'] ?? bookingId}',
      checkoutUrl: url,
      reused: json['reused'] == true,
    );
  }
}
