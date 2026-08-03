/// An ETA computed once at worker-assignment time.
///
/// TRACK-GAP-003: The backend calculates ETA via haversine at 30 km/h and
/// stores it as a static integer (`bookings.eta_minutes`). It is not
/// recalculated as the provider moves. [etaAt] is the absolute deadline
/// derived at assignment: `NOW() + eta_minutes * interval '1 minute'`.
///
/// Display guidance:
///   - If [isExpired], show "Provider should have arrived" rather than a
///     negative countdown.
///   - Always pair the displayed value with [computedAt] so the customer
///     knows this is an estimate, not a live countdown.
class TrackingEta {
  const TrackingEta({
    required this.etaMinutes,
    required this.etaAt,
    required this.computedAt,
  });

  /// Original estimated travel time in minutes (computed once at assignment).
  final int etaMinutes;

  /// Absolute ETA timestamp: assignment time + [etaMinutes].
  final DateTime etaAt;

  /// Timestamp when this ETA was computed (i.e., when the worker was assigned).
  final DateTime computedAt;

  /// Returns true when [etaAt] is in the past relative to [now].
  bool isExpired(DateTime now) => now.isAfter(etaAt);

  /// Remaining minutes until [etaAt], clamped to zero when expired.
  int remainingMinutes(DateTime now) {
    final diff = etaAt.difference(now).inMinutes;
    return diff > 0 ? diff : 0;
  }

  /// Parse from booking detail response fields.
  ///
  /// `etaMinutes` / `eta_minutes`: integer travel estimate.
  /// `etaAt` / `eta_at`: ISO-8601 string for the absolute deadline.
  /// `assignedAt` / `assigned_at`: when the worker was assigned (= computedAt).
  static TrackingEta? fromBookingMap(Map<String, dynamic> b) {
    final etaMinutesRaw = b['etaMinutes'] ?? b['eta_minutes'];
    final etaAtRaw = b['etaAt']?.toString() ?? b['eta_at']?.toString();
    if (etaMinutesRaw == null || etaAtRaw == null) return null;

    final etaMinutes = (etaMinutesRaw as num?)?.toInt();
    final etaAt = DateTime.tryParse(etaAtRaw)?.toLocal();
    if (etaMinutes == null || etaAt == null) return null;

    final assignedAtRaw =
        b['assignedAt']?.toString() ?? b['assigned_at']?.toString();
    final computedAt = assignedAtRaw != null
        ? (DateTime.tryParse(assignedAtRaw)?.toLocal() ??
            etaAt.subtract(Duration(minutes: etaMinutes)))
        : etaAt.subtract(Duration(minutes: etaMinutes));

    return TrackingEta(
      etaMinutes: etaMinutes,
      etaAt: etaAt,
      computedAt: computedAt,
    );
  }
}
