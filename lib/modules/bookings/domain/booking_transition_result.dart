/// The outcome of a booking lifecycle action.
///
/// Mirrors the backend's `BookingTransitionResult`, which every canonical
/// action returns — cancel and OTP verify both answer with this shape because
/// both are the same thing underneath: one call to `transitionBooking`.
///
/// ## Why the client keeps `fromState` as well as `toState`
///
/// A caller that only reads the destination cannot tell a real transition from
/// a replay, and the two want different UI: a replay must not re-announce
/// "Booking cancelled" to somebody who already saw it. [idempotentReplay] is
/// the backend saying so outright, and it is only ever true when an
/// `Idempotency-Key` was sent — which is why this tab fixed the header name
/// before building anything on top of it.
library;

import 'package:client/common/domain/time/iso_timestamp.dart';

class BookingTransitionResult {
  const BookingTransitionResult({
    required this.bookingId,
    required this.action,
    required this.fromState,
    required this.toState,
    this.idempotentReplay = false,
    this.correlationId,
    this.timelineEventId,
    this.customerLabel,
    this.customerDetail,
    this.terminal = false,
    this.availableActions = const <String>[],
  });

  final String bookingId;

  /// The machine's own name for what happened — `cancel`, `confirmOtp`.
  final String action;

  final String fromState;
  final String toState;

  /// True when an identical request had already been applied and the backend
  /// returned the original result rather than acting twice.
  final bool idempotentReplay;

  final String? correlationId;
  final int? timelineEventId;

  /// The caller-appropriate projection, when the backend included one. These
  /// are the CUSTOMER's words for the new state, chosen by
  /// `toCustomerProjection` — deliberately about the provider's progress rather
  /// than the booking's administrative state, because "Awaiting Assignment"
  /// means nothing to somebody waiting for a cleaner.
  final String? customerLabel;
  final String? customerDetail;

  final bool terminal;

  /// What the customer may do next, **as decided by the backend's state
  /// machine**. Empty when the projection was absent, which is not the same as
  /// "nothing is possible" — see [BookingActionAvailability].
  final List<String> availableActions;

  static BookingTransitionResult fromApiMap(Map<String, dynamic> json) {
    final state = json['state'];
    final projection = state is Map
        ? Map<String, dynamic>.from(state)
        : const <String, dynamic>{};

    return BookingTransitionResult(
      bookingId: '${json['bookingId'] ?? ''}',
      action: '${json['action'] ?? ''}',
      fromState: '${json['fromState'] ?? ''}',
      toState: '${json['toState'] ?? ''}',
      idempotentReplay: json['idempotentReplay'] == true,
      correlationId: json['correlationId']?.toString(),
      timelineEventId: json['timelineEventId'] is num
          ? (json['timelineEventId'] as num).toInt()
          : int.tryParse('${json['timelineEventId'] ?? ''}'),
      customerLabel: projection['label']?.toString(),
      customerDetail: projection['detail']?.toString(),
      terminal: projection['terminal'] == true,
      availableActions: _strings(projection['availableActions']),
    );
  }

  /// Builds a result for the legacy transports, which return no transition
  /// record at all.
  ///
  /// [fromState] is what the client last read and [toState] is what it asked
  /// for — an assumption, and one this constructor makes visible by requiring
  /// both to be passed rather than defaulting them. The legacy routes really do
  /// answer `{success: true}` and nothing more, so a compatibility caller
  /// cannot know the machine agreed; it can only know it was not refused.
  const BookingTransitionResult.assumed({
    required this.bookingId,
    required this.action,
    required this.fromState,
    required this.toState,
  })  : idempotentReplay = false,
        correlationId = null,
        timelineEventId = null,
        customerLabel = null,
        customerDetail = null,
        terminal = false,
        availableActions = const <String>[];

  static List<String> _strings(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((e) => e?.toString())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
}

/// What the customer may do to a booking right now.
///
/// ## The rule this type exists to enforce
///
/// The backend generates `availableActions` from `TRANSITIONS` — the single
/// state machine every surface shares. Any client that computes the same list
/// from a status string is a second state machine, and two machines drift in
/// one direction only: toward offering a button whose request the server will
/// refuse.
///
/// So this wraps the backend's answer when there is one and falls back to the
/// client's own resolver when there is not, and [isBackendDerived] says which
/// happened. The fallback is not a rival source of truth; it is what a legacy
/// transport can honestly manage, labelled as such.
///
/// ## Reschedule is not in `availableActions`, and that is correct
///
/// Rescheduling is not a state transition — it goes through
/// `bookingRescheduleService`, governed by `RESCHEDULABLE_STATES` and a notice
/// window rather than by the machine. Asking `availableActions` about it would
/// always answer no. [canReschedule] is therefore carried separately and is
/// only ever a *hint*: the authority is the backend's refusal, which names the
/// rule that refused.
class BookingActionAvailability {
  const BookingActionAvailability({
    required this.actions,
    required this.isBackendDerived,
    this.canReschedule = false,
    this.terminal = false,
  });

  /// Backend action names — `cancel`, `confirmOtp`.
  final List<String> actions;

  /// True when [actions] came from the server's projection rather than from
  /// the client's local resolver.
  final bool isBackendDerived;

  final bool canReschedule;
  final bool terminal;

  bool get canCancel => actions.contains('cancel');
  bool get canConfirmOtp => actions.contains('confirmOtp');
}

/// One entry from `GET /api/v1/bookings/:id/reschedule`.
///
/// Every attempt is here, accepted or refused. That is what makes "no silent
/// overwrite" something a customer can see rather than only something the
/// database knows — the legacy admin reschedule was a bare `UPDATE` and two
/// admins moving one booking produced a winner nobody could name.
class BookingRescheduleAttempt {
  const BookingRescheduleAttempt({
    required this.id,
    required this.proposedSchedule,
    required this.status,
    this.previousSchedule,
    this.reasonCode,
    this.refusalCode,
    this.requestedRole,
    this.decidedAt,
    this.createdAt,
  });

  final int id;
  final DateTime? previousSchedule;
  final DateTime? proposedSchedule;
  final String status;
  final String? reasonCode;
  final String? refusalCode;

  /// The seat that proposed it. The backend does not project the uid, and this
  /// model does not invent a field for one.
  final String? requestedRole;

  final DateTime? decidedAt;
  final DateTime? createdAt;

  static BookingRescheduleAttempt fromApiMap(Map<String, dynamic> json) {
    return BookingRescheduleAttempt(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse('${json['id'] ?? ''}') ?? 0,
      previousSchedule: parseBackendTimestamp(json['previousSchedule']),
      proposedSchedule: parseBackendTimestamp(json['proposedSchedule']),
      status: '${json['status'] ?? ''}',
      reasonCode: json['reasonCode']?.toString(),
      refusalCode: json['refusalCode']?.toString(),
      requestedRole: json['requestedRole']?.toString(),
      decidedAt: parseBackendTimestamp(json['decidedAt']),
      createdAt: parseBackendTimestamp(json['createdAt']),
    );
  }
}
