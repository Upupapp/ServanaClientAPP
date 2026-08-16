/// Change orders raised against a booking.
///
/// ## A change order is a child record, never a mutation
///
/// The backend is explicit: *"A change order is a priced child record, never a
/// mutation of the original service."* So the booking's own price does not
/// move when work is added — a separate request is raised, approved, and paid
/// through its own checkout. That is why `BookingPayment.breakdown` carries
/// `additionalWork` as its own line and why it can be non-zero while the base
/// price is already settled.
///
/// ## The customer may READ these and may not RAISE one
///
/// `bookings.additionalWork.create` is `auth: 'provider'` and its contract
/// lists `customerMobile: 'n/a'`. Only the assigned provider, mid-job, can
/// raise a change order. This client therefore models the record and the list
/// and has **no** create path — see `BookingExperiencesDataSource`.
///
/// ## `approvedAmount` is not `totalAmount`
///
/// The list query returns `approved_amount` as NULL unless the status is one of
/// `WAITING_FOR_PAYMENT`, `WAITING_WORKER_APPROVAL`, `ACCEPTED`, `IN_PROGRESS`,
/// `PROCEEDING`, `COMPLETED`. A change order sitting at
/// `PENDING_ADMIN_APPROVAL` has a price and no approved amount, and showing the
/// former as though it were owed would tell a customer they are being charged
/// for work nobody has agreed to yet.
library;

import 'package:client/common/domain/time/iso_timestamp.dart';

/// Where a change order is in its own approval and payment flow.
///
/// Separate from the booking lifecycle and from the booking's payment state —
/// a third state machine, belonging to the child record.
enum AdditionalWorkStatus {
  pendingAdminApproval('PENDING_ADMIN_APPROVAL'),
  waitingForPayment('WAITING_FOR_PAYMENT'),
  waitingWorkerApproval('WAITING_WORKER_APPROVAL'),
  accepted('ACCEPTED'),
  inProgress('IN_PROGRESS'),
  proceeding('PROCEEDING'),
  completed('COMPLETED'),
  rejected('REJECTED'),
  cancelled('CANCELLED'),

  /// A value this build does not know.
  ///
  /// Distinct rather than folded into a known state, for the same reason
  /// `PaymentState.unknown` is: guessing lets a screen present a status the
  /// server never claimed.
  unknown('UNKNOWN');

  const AdditionalWorkStatus(this.wireName);

  final String wireName;

  static AdditionalWorkStatus fromWire(Object? raw) {
    final name = '${raw ?? ''}'.toUpperCase().trim();
    for (final s in AdditionalWorkStatus.values) {
      if (s.wireName == name) return s;
    }
    return AdditionalWorkStatus.unknown;
  }

  /// The set the backend's own query treats as carrying an approved amount.
  ///
  /// Mirrored from the `CASE WHEN status IN (…)` in
  /// `additionalService.getByBooking`, and used only to explain a null — never
  /// to compute an amount the server declined to send.
  bool get carriesApprovedAmount =>
      this == AdditionalWorkStatus.waitingForPayment ||
      this == AdditionalWorkStatus.waitingWorkerApproval ||
      this == AdditionalWorkStatus.accepted ||
      this == AdditionalWorkStatus.inProgress ||
      this == AdditionalWorkStatus.proceeding ||
      this == AdditionalWorkStatus.completed;

  /// Waiting on somebody, and not yet money the customer owes.
  bool get isAwaitingApproval =>
      this == AdditionalWorkStatus.pendingAdminApproval ||
      this == AdditionalWorkStatus.waitingWorkerApproval;

  bool get isSettledOrDead =>
      this == AdditionalWorkStatus.completed ||
      this == AdditionalWorkStatus.rejected ||
      this == AdditionalWorkStatus.cancelled;
}

class AdditionalWorkRequest {
  const AdditionalWorkRequest({
    required this.id,
    required this.bookingId,
    required this.status,
    this.totalAmount,
    this.approvedAmount,
    this.approvedAt,
    this.paidAt,
    this.workerDecision,
    this.decidedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String bookingId;
  final AdditionalWorkStatus status;

  /// What the provider priced the change order at.
  final double? totalAmount;

  /// Null until the request reaches a status that carries one.
  ///
  /// The distinction the UI must keep: [totalAmount] is what was *asked for*,
  /// [approvedAmount] is what has been *agreed*. Rendering the first where the
  /// second belongs charges a customer for a proposal.
  final double? approvedAmount;

  final DateTime? approvedAt;
  final DateTime? paidAt;

  /// The assigned provider's own decision on the request, when they have made
  /// one. Free of any uid: the backend projects the decision, not the person.
  final String? workerDecision;

  final DateTime? decidedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPaid => paidAt != null;

  static AdditionalWorkRequest fromApiMap(Map<String, dynamic> json,
      {required String bookingId}) {
    // The service returns raw Postgres columns — snake_case, and timestamps in
    // Postgres' native rendering rather than ISO. Both spellings are read
    // because the canonical route passes the rows through unchanged and a
    // future normalisation would produce the camelCase form.
    Object? pick(String camel, String snake) => json[camel] ?? json[snake];

    return AdditionalWorkRequest(
      id: _int(json['id']) ?? 0,
      bookingId: '${pick('bookingId', 'booking_id') ?? bookingId}',
      status: AdditionalWorkStatus.fromWire(json['status']),
      totalAmount: _double(pick('totalAmount', 'total_amount')),
      approvedAmount: _double(pick('approvedAmount', 'approved_amount')),
      approvedAt: parseBackendTimestamp(pick('approvedAt', 'approved_at')),
      paidAt: parseBackendTimestamp(pick('paidAt', 'paid_at')),
      workerDecision: pick('workerDecision', 'worker_decision')?.toString(),
      decidedAt: parseBackendTimestamp(pick('decidedAt', 'decided_at')),
      createdAt: parseBackendTimestamp(pick('createdAt', 'created_at')),
      updatedAt: parseBackendTimestamp(pick('updatedAt', 'updated_at')),
    );
  }
}

double? _double(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
