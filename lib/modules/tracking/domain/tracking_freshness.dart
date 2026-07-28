/// Describes how recent the last-known provider location is.
///
/// The UI must communicate freshness honestly — never label a stale position
/// as "live" or animate a marker to a position that was not observed.
enum TrackingFreshness {
  /// Location was updated within the staleness threshold (default: 3 min).
  live,

  /// Location is available but older than the staleness threshold.
  /// The UI must display the age ("last seen X min ago") rather than implying
  /// the marker reflects the provider's current position.
  stale,

  /// No location snapshot has been received yet.
  /// Could mean the provider's app hasn't pushed a location, or the fetch
  /// hasn't completed. The UI must show a placeholder, not a random pin.
  unknown,
}

extension TrackingFreshnessLabel on TrackingFreshness {
  String get chipLabel {
    switch (this) {
      case TrackingFreshness.live:
        return 'Live';
      case TrackingFreshness.stale:
        return 'Last Known';
      case TrackingFreshness.unknown:
        return 'Locating…';
    }
  }
}
