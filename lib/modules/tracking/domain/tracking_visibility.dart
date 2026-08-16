/// Why the provider's position is or is not on the map.
///
/// ## The distinction this type carries
///
/// Authorization and visibility are different questions, and the backend says
/// so in as many words: *"a withheld position is a 200 with visibility.reason,
/// never a 403 — the caller is entitled to the booking and simply not to a live
/// location for it yet."*
///
/// The client had no way to express that. `TrackingRepository` reduced every
/// non-answer to `providerLocation == null`, so four different facts —
/// nobody assigned, wrong state, window closed, assigned but silent — rendered
/// as one blank map. A customer whose provider is en route and out of signal
/// and a customer whose booking was cancelled last week saw the same screen.
///
/// ## Where the rules live
///
/// Not here. [TrackingVisibility] is read from the response; nothing in this
/// file decides whether a position may be shown. The legacy pair answered in
/// EVERY state — a customer could watch their provider on a booking cancelled
/// last week — and the canonical route is what adds the state and time-window
/// rules. Reimplementing them client-side would recreate the gap the server
/// closed, one release out of date.
library;

/// Which rule withheld the position, when one did.
enum TrackingWithheldReason {
  /// No provider is assigned yet.
  noAssignment('NO_ASSIGNMENT'),

  /// The booking is not in a state where a live position is shared.
  stateNotTrackable('STATE_NOT_TRACKABLE'),

  /// Too long since the last movement report.
  windowExpired('WINDOW_EXPIRED'),

  /// A provider is assigned and simply has not reported a position.
  noPositionReported('NO_POSITION_REPORTED');

  const TrackingWithheldReason(this.wireName);

  final String wireName;

  static TrackingWithheldReason? fromWire(Object? raw) {
    final name = '${raw ?? ''}'.toUpperCase();
    for (final r in TrackingWithheldReason.values) {
      if (r.wireName == name) return r;
    }
    return null;
  }

  /// What the customer is told.
  ///
  /// Each one says something true and different. Collapsing them into "Location
  /// unavailable" is what the four codes exist to prevent — the same argument
  /// the backend makes for keeping `EMPTY` and `UNAVAILABLE` apart on Home.
  String get customerMessage {
    switch (this) {
      case TrackingWithheldReason.noAssignment:
        return "We're still matching you with a provider.";
      case TrackingWithheldReason.stateNotTrackable:
        return 'Live location is shown once your provider is on the way.';
      case TrackingWithheldReason.windowExpired:
        return "We haven't had a location update recently.";
      case TrackingWithheldReason.noPositionReported:
        return 'Your provider has not shared their location yet.';
    }
  }
}

/// The verdict on showing a position, exactly as the backend returned it.
class TrackingVisibility {
  const TrackingVisibility({
    required this.isVisible,
    this.reason,
    this.trackableStates = const <String>[],
    this.windowClosesAt,
    this.isBackendDerived = true,
  });

  final bool isVisible;

  /// Null when [isVisible] — and also null when the transport could not say.
  /// Use [isBackendDerived] to tell those apart.
  final TrackingWithheldReason? reason;

  /// The states in which a position is shared at all, from the server's own
  /// policy block. Carried so a screen can explain the rule without holding a
  /// copy of it.
  final List<String> trackableStates;

  final DateTime? windowClosesAt;

  /// False when this was inferred locally because the legacy transport
  /// answered. The legacy routes carry no verdict, so nothing here is measured
  /// — a null position becomes "not reported", which is a guess and is labelled
  /// as one.
  final bool isBackendDerived;

  /// Withheld, with the backend naming which rule did it.
  bool get isExplainedWithholding => !isVisible && reason != null;

  static TrackingVisibility fromApiMap(Map<String, dynamic> json) {
    // The envelope nests the verdict under its own `visibility` key:
    // `{ visibility: { visibility: 'VISIBLE'|'WITHHELD', reason, … } }`.
    final raw = '${json['visibility'] ?? ''}'.toUpperCase();
    final states = json['trackableStates'];

    return TrackingVisibility(
      // Deny by default: an unrecognised verdict withholds. A parser that
      // defaulted to VISIBLE would put a position on screen on the strength of
      // a value it did not understand.
      isVisible: raw == 'VISIBLE',
      reason: TrackingWithheldReason.fromWire(json['reason']),
      trackableStates: states is List
          ? states
              .map((e) => e?.toString())
              .whereType<String>()
              .toList(growable: false)
          : const <String>[],
      windowClosesAt: json['windowClosesAt'] == null
          ? null
          : DateTime.tryParse('${json['windowClosesAt']}')?.toLocal(),
    );
  }

  /// The honest verdict for the legacy transport.
  ///
  /// Two facts are all it can distinguish: there is a position, or there is
  /// not. [isBackendDerived] is false so a screen does not present the guess
  /// as the server's answer.
  const TrackingVisibility.inferred({required bool hasPosition})
      : isVisible = hasPosition,
        reason = hasPosition ? null : TrackingWithheldReason.noPositionReported,
        trackableStates = const <String>[],
        windowClosesAt = null,
        isBackendDerived = false;
}
