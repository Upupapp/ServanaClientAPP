/// Whether a service can be booked at an address — asked before the customer
/// fills in a form, rather than discovered when they submit one.
///
/// ## What this replaces
///
/// `createBooking` is the only thing that runs the coverage test, and it runs
/// it last. So a customer picks a service, picks a saved address, picks a date,
/// picks a payment method, presses Confirm, and only then hears:
///
///     Service not available in your area.
///
/// Every step after the address was wasted, and the app could have known at the
/// first one. `GET /api/catalog/services/:id/serviceability?lat=&lon=` answers
/// the same verdict up front, resolving the service family with the statement
/// `createBooking` itself uses — so a pre-check cannot promise a booking the
/// server will refuse.
library;

/// Why a service cannot be booked at a point.
///
/// Closed on purpose. A free-form string here would drift into prose, and the
/// whole value of this answer is that the app can choose its own words per
/// reason instead of echoing the server's.
enum ServiceabilityReason {
  /// In range of nothing the service covers. The customer can act on this —
  /// another saved address may work.
  outsideServiceArea,

  /// The service exists and the area is covered, but nobody on the platform
  /// can perform it. The customer can do nothing about this, and telling them
  /// to try another address would send them round a loop with no exit.
  noCapableProvider,

  /// The point could not be judged — an absent coordinate, or 0,0.
  invalidLocation,

  /// The backend named a reason this build does not know.
  ///
  /// NOT an error and not a refusal on its own: `serviceable` is still the
  /// verdict. A newer server naming a new reason must not make the app treat a
  /// bookable service as unbookable.
  unknown;

  static ServiceabilityReason? parse(Object? raw) => switch (raw?.toString()) {
        null || '' => null,
        'OUTSIDE_SERVICE_AREA' => ServiceabilityReason.outsideServiceArea,
        'NO_CAPABLE_PROVIDER' => ServiceabilityReason.noCapableProvider,
        'INVALID_LOCATION' => ServiceabilityReason.invalidLocation,
        _ => ServiceabilityReason.unknown,
      };
}

class Serviceability {
  const Serviceability({
    required this.serviceable,
    this.reason,
    this.defaulted = false,
  });

  final bool serviceable;
  final ServiceabilityReason? reason;

  /// True when the service had no coverage configured and the backend's
  /// supported footprint decided the answer (§28). Carried because "we assumed"
  /// and "we checked" are different confidences, even when the verdict matches.
  final bool defaulted;

  /// What the customer is told, or null when there is nothing useful to say.
  ///
  /// Null for a serviceable address — silence is the right output when the
  /// answer is yes. A banner saying "this works" is noise on every screen it
  /// appears on.
  String? get message => switch (reason) {
        null => null,
        ServiceabilityReason.outsideServiceArea =>
          'This address is outside our service area for this service. '
              'Try another saved address.',
        ServiceabilityReason.noCapableProvider =>
          'No provider is available for this service yet. '
              'Please try another service or check back soon.',
        ServiceabilityReason.invalidLocation =>
          'We could not place this address on the map. '
              'Please choose or add another one.',
        // Deliberately vague rather than invented: this build does not know
        // what the server meant, and guessing is how a screen tells a customer
        // something that is not true.
        ServiceabilityReason.unknown =>
          'This service cannot be booked at this address.',
      };

  factory Serviceability.fromJson(Map<String, dynamic> json) {
    // The envelope is `{status, data:{serviceable, reason, defaulted}}`, and
    // some callers hand the inner object straight in.
    //
    // Read with `is Map` and re-cast, NOT `as Map<String, dynamic>?`. That cast
    // THROWS on a map whose static type is anything else — a literal written
    // `const {...}` is a `Map<dynamic, dynamic>` — rather than yielding null the
    // way it reads. Same trap as `as num?` on a String, which once crashed a
    // price parse before it reached its own fallback.
    final raw = json['data'];
    final data = raw is Map ? raw.cast<String, dynamic>() : json;
    return Serviceability(
      // Absent is NOT serviceable. A missing field must never read as a yes —
      // that is the one direction this answer must not fail in.
      serviceable: data['serviceable'] == true,
      reason: ServiceabilityReason.parse(data['reason']),
      defaulted: data['defaulted'] == true,
    );
  }
}
