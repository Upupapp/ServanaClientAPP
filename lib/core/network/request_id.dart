/// Client-generated correlation identifiers.
///
/// Every request carries `X-Request-Id`. It is echoed back by v1 as
/// `error.requestId` on failure, and on legacy routes — which do not echo
/// anything — it is still the handle we log locally, so a customer report and
/// a client log line can be joined even when the server never saw the header.
///
/// A *correlation* id is different and lives longer: it spans the several
/// requests that make up one user intent (quote → create booking → create
/// payment intent). Support asking "what happened to this booking attempt"
/// wants the correlation id, not three unrelated request ids.
///
/// ## No uuid package
///
/// This deliberately does not add a dependency. The ids only have to be
/// unique enough not to collide within one device's logs, and they must never
/// be derived from anything about the customer — see below.
///
/// ## Privacy
///
/// Ids are random. They MUST NOT encode a uid, phone number, email, booking id
/// or device identifier: a correlation id ends up in server logs, crash
/// reports and support tickets, which is exactly the set of places a stable
/// personal identifier should not travel to.
library;

import 'dart:math';

class RequestIds {
  RequestIds._();

  static final Random _random = Random();
  static const String _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  /// Header name for the per-request id.
  static const String requestHeader = 'X-Request-Id';

  /// Header name for the per-intent id.
  static const String correlationHeader = 'X-Correlation-Id';

  /// A fresh request id, e.g. `req_m3k2j1_8fh2la9c`.
  static String newRequestId() => 'req_${_stamp()}_${_token(8)}';

  /// A fresh correlation id for a multi-call user intent.
  static String newCorrelationId() => 'cor_${_stamp()}_${_token(8)}';

  /// Base-36 millisecond stamp — orders ids in a log without revealing more
  /// than the wall clock a server already sees.
  static String _stamp() =>
      DateTime.now().millisecondsSinceEpoch.toRadixString(36);

  static String _token(int length) => List<String>.generate(
        length,
        (_) => _alphabet[_random.nextInt(_alphabet.length)],
        growable: false,
      ).join();
}

/// The correlation id in force for a user intent.
///
/// Held by whatever owns the intent — a booking store, a checkout flow — and
/// passed into each call it makes. Not a global or a zone variable: an
/// ambient value would silently attach the wrong intent to a background
/// refresh that happened to run during checkout.
class CorrelationContext {
  CorrelationContext(this.correlationId);

  /// Starts a new intent.
  CorrelationContext.start() : correlationId = RequestIds.newCorrelationId();

  final String correlationId;

  Map<String, String> get headers =>
      <String, String>{RequestIds.correlationHeader: correlationId};

  @override
  String toString() => 'CorrelationContext($correlationId)';
}
