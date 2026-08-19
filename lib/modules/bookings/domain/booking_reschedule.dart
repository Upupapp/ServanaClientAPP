/// Moving a booking.
///
/// ## What the client owns and what it must not
///
/// The client owns the **vocabulary** — a reschedule reason has to be picked
/// before any request exists, so the closed list has to be here. It is closed
/// and append-only on the backend (`RESCHEDULE_REASONS`), which is what makes
/// mirroring it safe: a value can be added but never redefined, and an
/// unrecognised one is refused with `BOOKING_RESCHEDULE_REASON_INVALID` rather
/// than silently accepted.
///
/// The client must NOT own the **policy**. The 24-hour customer notice window,
/// the 90-day lead bound, the reschedulable states and the provider-calendar
/// check all live on the server, and every one of them is a rule this app would
/// get wrong within one operator decision. So nothing here decides whether a
/// move is allowed; the request is made and the refusal is rendered, naming
/// the rule the backend named.
///
/// That is a deliberate reversal of how cancellation was built. `_isCancellable`
/// on the detail screen and `_cancellable` in `BookingActionResolver` are two
/// client-side copies of a server rule, and they already disagree with each
/// other about `paymentProcessing`. Reschedule does not get a third.
library;

import 'package:client/common/domain/time/iso_timestamp.dart';

/// The standardized reasons, mirroring the backend's `RESCHEDULE_REASONS`.
enum RescheduleReason {
  customerUnavailable('CUSTOMER_UNAVAILABLE', "I'm not available then"),
  propertyNotReady('PROPERTY_NOT_READY', 'The property is not ready'),
  weather('WEATHER', 'Weather'),
  providerSupply('PROVIDER_SUPPLY', 'Provider availability'),
  operational('OPERATIONAL', 'Operational'),
  other('OTHER', 'Another reason');

  const RescheduleReason(this.wireName, this.label);

  /// The value sent as `reasonCode`.
  final String wireName;

  /// Customer-facing copy. Not sent, and not derived from [wireName] — the
  /// wire names are operator vocabulary and read as such.
  final String label;

  /// The subset a CUSTOMER is offered.
  ///
  /// `PROVIDER_SUPPLY` and `OPERATIONAL` are accepted by the endpoint because
  /// an admin moving a booking uses them. Offering them to a customer would
  /// invite them to attribute the move to the provider, which is a claim the
  /// app has no basis for and which lands in an audit record.
  static const List<RescheduleReason> customerChoices = <RescheduleReason>[
    RescheduleReason.customerUnavailable,
    RescheduleReason.propertyNotReady,
    RescheduleReason.weather,
    RescheduleReason.other,
  ];

  static RescheduleReason? fromWire(Object? raw) {
    final name = '${raw ?? ''}'.toUpperCase();
    for (final r in RescheduleReason.values) {
      if (r.wireName == name) return r;
    }
    return null;
  }
}

/// A proposal to move a booking.
class BookingRescheduleRequest {
  const BookingRescheduleRequest({
    required this.scheduledAt,
    this.reasonCode,
    this.reason,
    this.expectedSchedule,
  });

  /// The proposed new start.
  final DateTime scheduledAt;

  final RescheduleReason? reasonCode;

  /// Free text, for the audit record.
  final String? reason;

  /// The schedule the caller last read.
  ///
  /// Sending it is what turns a lost update into a clean refusal: when it no
  /// longer matches, the write is refused with `BOOKING_SCHEDULE_CHANGED`
  /// instead of overwriting a move somebody else already made. Optional on the
  /// wire and always supplied here, because a client that has read a booking in
  /// order to offer a reschedule button has no excuse for omitting it.
  final DateTime? expectedSchedule;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        if (reasonCode != null) 'reasonCode': reasonCode!.wireName,
        if (reason != null && reason!.trim().isNotEmpty)
          'reason': reason!.trim(),
        if (expectedSchedule != null)
          'expectedSchedule': expectedSchedule!.toUtc().toIso8601String(),
      };
}

/// The verdict on a proposal.
class BookingRescheduleResult {
  const BookingRescheduleResult({
    required this.bookingId,
    required this.status,
    required this.scheduledAt,
    this.requestId,
    this.previousSchedule,
    this.reasonCode,
    this.appliedImmediately = false,
    this.noticeHours,
    this.noticeCutoff,
  });

  final String bookingId;

  /// `ACCEPTED`, `REFUSED` or `PENDING_PROVIDER`.
  ///
  /// The third is reachable: the backend has the acceptance workflow behind
  /// `RESCHEDULE_REQUIRES_PROVIDER_ACCEPTANCE`, false today. Modelled rather
  /// than collapsed into accepted, so flipping that flag does not silently
  /// tell a customer their booking has moved when it has only been proposed.
  final String status;

  final DateTime? scheduledAt;

  /// The proposal row, written for accepted AND refused attempts.
  final int? requestId;

  final DateTime? previousSchedule;
  final RescheduleReason? reasonCode;
  final bool appliedImmediately;

  /// The notice window that applied to THIS actor, from the server's verdict.
  /// Read, never computed — an admin's window is zero and a customer's is not.
  final int? noticeHours;
  final DateTime? noticeCutoff;

  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isPendingProvider => status.toUpperCase() == 'PENDING_PROVIDER';

  static BookingRescheduleResult fromApiMap(Map<String, dynamic> json) {
    final verdictRaw = json['verdict'];
    final verdict = verdictRaw is Map
        ? Map<String, dynamic>.from(verdictRaw)
        : const <String, dynamic>{};

    return BookingRescheduleResult(
      bookingId: '${json['bookingId'] ?? ''}',
      status: '${json['status'] ?? ''}',
      scheduledAt: parseBackendTimestamp(json['scheduledAt']),
      requestId: json['requestId'] is num
          ? (json['requestId'] as num).toInt()
          : int.tryParse('${json['requestId'] ?? ''}'),
      previousSchedule: parseBackendTimestamp(json['previousSchedule']),
      reasonCode: RescheduleReason.fromWire(json['reasonCode']),
      appliedImmediately: json['appliedImmediately'] == true,
      noticeHours: verdict['noticeHours'] is num
          ? (verdict['noticeHours'] as num).toInt()
          : null,
      noticeCutoff: parseBackendTimestamp(verdict['noticeCutoff']),
    );
  }
}
