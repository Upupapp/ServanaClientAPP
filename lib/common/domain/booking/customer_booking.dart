import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/domain/booking/booking_status.dart';

/// Domain model representing a booking from the customer's perspective.
///
/// Constructed from either a [JobOrder] (list/cache source) or a raw API
/// response map (detail/refresh source).  No freezed dependency — plain Dart.
class CustomerBooking {
  const CustomerBooking({
    required this.bookingId,
    required this.bookingNumber,
    required this.customerId,
    required this.status,
    required this.rawStatus,
    required this.serviceName,
    required this.serviceCategory,
    this.servicePhotoUrl,
    required this.scheduledAt,
    required this.addressLine,
    this.fullAddress,
    required this.totalAmount,
    this.currency = 'PHP',
    required this.paymentStatus,
    this.paymentMethod,
    this.workerUid,
    this.workerName,
    this.workerPhone,
    this.workerCode,
    this.etaMinutes,
    this.assignedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Identity ────────────────────────────────────────────────────────────────
  /// Numeric booking PK as a string (matches jobOrderID / "id" / "bookingId").
  final String bookingId;

  /// Human-readable booking reference, e.g. "SVN-000042".
  final String bookingNumber;

  /// Firebase UID of the customer who created this booking.
  final String customerId;

  // ── Status ──────────────────────────────────────────────────────────────────
  /// Canonical lifecycle state.
  final BookingStatus status;

  /// Raw status string returned by the backend (for logging / fallback UI).
  final String rawStatus;

  // ── Service ─────────────────────────────────────────────────────────────────
  final String serviceName;
  final String serviceCategory;
  final String? servicePhotoUrl;

  // ── Schedule & Location ─────────────────────────────────────────────────────
  final DateTime scheduledAt;

  /// Short display address (always present).
  final String addressLine;

  /// Full formatted address when available.
  final String? fullAddress;

  // ── Payment ─────────────────────────────────────────────────────────────────
  final double totalAmount;
  final String currency;

  /// Raw payment status from backend: 'PENDING' | 'PAID'.
  final String paymentStatus;

  /// 'CASH' | 'GCASH' | 'CARD' | null.
  final String? paymentMethod;

  // ── Provider / Worker ───────────────────────────────────────────────────────
  final String? workerUid;
  final String? workerName;
  final String? workerPhone;

  /// QR code value displayed to the customer at handoff.
  final String? workerCode;

  /// Estimated arrival in minutes (live, not persisted).
  final int? etaMinutes;
  final DateTime? assignedAt;

  // ── Timestamps ──────────────────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Derived convenience getters ─────────────────────────────────────────────

  /// True when the booking is in a terminal state and no further user action
  /// or polling is expected.
  bool get isTerminal => BookingStatusMapper.isTerminal(status);

  /// True when the customer must complete OTP before proceeding.
  bool get requiresOtp => BookingStatusMapper.requiresOtp(status);

  /// True when the customer must complete payment before proceeding.
  bool get requiresPayment => BookingStatusMapper.requiresPayment(status);

  /// True when the UI should poll for a provider assignment.
  bool get shouldPollAssignment =>
      BookingStatusMapper.shouldPollAssignment(status);

  /// Display label for status chips / card headers.
  String get statusLabel => BookingStatusMapper.customerLabel(status);

  /// One-line contextual subtitle for the booking hero / detail banner.
  String get statusSubtitle => BookingStatusMapper.heroSubtitle(status);

  /// Grouping bucket: 'needsAttention' | 'active' | 'upcoming' | 'completed'
  /// | 'cancelled'.
  String get groupCategory => BookingStatusMapper.groupCategory(status);

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';

  // ── Factories ───────────────────────────────────────────────────────────────

  /// Build from a [JobOrder] (used when the list already has the object in
  /// memory and the detail fetch has not completed yet).
  factory CustomerBooking.fromJobOrder(JobOrder jo) {
    final rawStatus = jo.jobOrderStatusToString;
    final photo = jo.merchantServicePhoto;
    return CustomerBooking(
      bookingId: jo.jobOrderID,
      bookingNumber: jo.jobOrderNumber,
      // JobOrder does not carry the customer UID — callers that need it should
      // use fromApiMap after fetching detail, or supply it separately.
      customerId: '',
      status: BookingStatusMapper.fromString(rawStatus),
      rawStatus: rawStatus,
      serviceName: jo.merchantServiceName,
      serviceCategory: jo.merchantName,
      servicePhotoUrl: photo.isEmpty ? null : photo,
      scheduledAt: jo.scheduleDate,
      addressLine: jo.address,
      fullAddress: null,
      totalAmount: jo.totalAmount,
      currency: 'PHP',
      paymentStatus: jo.paymentStatus ?? 'PENDING',
      paymentMethod: jo.paymentMethodUsed,
      // Worker details are not available on the list model; filled in after
      // a detail refresh via copyWith.
      workerUid: null,
      workerName: null,
      workerPhone: null,
      workerCode: null,
      etaMinutes: null,
      assignedAt: null,
      createdAt: jo.createdDate,
      updatedAt: jo.viewDate ?? jo.createdDate,
    );
  }

  /// Build from the raw API map returned inside `{ success: true, booking: … }`.
  ///
  /// Handles the cross-platform field aliases added by `formatBooking` on the
  /// backend (bookingId/id, scheduledAt/scheduleAt/schedule, workerUid/providerUid,
  /// customerId/userId/customerUid).
  factory CustomerBooking.fromApiMap(Map<String, dynamic> json) {
    final rawStatus =
        (json['status'] as String?) ?? (json['statusLower'] as String?) ?? '';

    final idRaw = json['bookingId'] ?? json['id'];
    final bookingId = idRaw?.toString() ?? '';

    // Resolve the scheduled datetime from any of the three aliases.
    final scheduleRaw =
        (json['scheduledAt'] ?? json['scheduleAt'] ?? json['schedule'])
            ?.toString();
    final scheduledAt = scheduleRaw != null
        ? (DateTime.tryParse(scheduleRaw) ?? DateTime.now())
        : DateTime.now();

    final createdRaw = json['createdAt']?.toString();
    final createdAt = createdRaw != null
        ? (DateTime.tryParse(createdRaw) ?? DateTime.now())
        : DateTime.now();

    final updatedRaw = json['updatedAt']?.toString();
    final updatedAt = updatedRaw != null
        ? (DateTime.tryParse(updatedRaw) ?? createdAt)
        : createdAt;

    final assignedRaw = json['assignedAt']?.toString();
    final assignedAt =
        assignedRaw != null ? DateTime.tryParse(assignedRaw) : null;

    final photoRaw =
        (json['servicePhoto'] ?? json['merchantServicePhoto'])?.toString();

    return CustomerBooking(
      bookingId: bookingId,
      bookingNumber:
          (json['bookingCode'] as String?) ?? 'SVN-$bookingId'.padLeft(9, '0'),
      customerId:
          (json['customerId'] ?? json['userId'] ?? json['customerUid'] ?? '')
              .toString(),
      status: BookingStatusMapper.fromString(rawStatus),
      rawStatus: rawStatus,
      serviceName: (json['serviceName'] ??
              json['merchantServiceName'] ??
              json['service_name'] ??
              '')
          .toString(),
      serviceCategory: (json['serviceCategory'] ??
              json['categoryName'] ??
              json['merchantName'] ??
              '')
          .toString(),
      servicePhotoUrl:
          (photoRaw != null && photoRaw.isNotEmpty) ? photoRaw : null,
      scheduledAt: scheduledAt,
      addressLine: (json['address'] ?? json['addressLine'] ?? '').toString(),
      fullAddress: json['fullAddress']?.toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?) ?? 'PHP',
      paymentStatus: (json['paymentStatus'] as String?) ?? 'PENDING',
      paymentMethod:
          (json['paymentMethod'] ?? json['paymentMethodUsed'])?.toString(),
      workerUid: (json['workerUid'] ?? json['providerUid'])?.toString(),
      workerName: json['workerName']?.toString(),
      workerPhone: json['workerPhone']?.toString(),
      workerCode: json['workerCode']?.toString(),
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
      assignedAt: assignedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ── Copy-with ────────────────────────────────────────────────────────────────

  CustomerBooking copyWith({
    String? bookingId,
    String? bookingNumber,
    String? customerId,
    BookingStatus? status,
    String? rawStatus,
    String? serviceName,
    String? serviceCategory,
    Object? servicePhotoUrl = _sentinel,
    DateTime? scheduledAt,
    String? addressLine,
    Object? fullAddress = _sentinel,
    double? totalAmount,
    String? currency,
    String? paymentStatus,
    Object? paymentMethod = _sentinel,
    Object? workerUid = _sentinel,
    Object? workerName = _sentinel,
    Object? workerPhone = _sentinel,
    Object? workerCode = _sentinel,
    Object? etaMinutes = _sentinel,
    Object? assignedAt = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerBooking(
      bookingId: bookingId ?? this.bookingId,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      rawStatus: rawStatus ?? this.rawStatus,
      serviceName: serviceName ?? this.serviceName,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      servicePhotoUrl: identical(servicePhotoUrl, _sentinel)
          ? this.servicePhotoUrl
          : servicePhotoUrl as String?,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      addressLine: addressLine ?? this.addressLine,
      fullAddress: identical(fullAddress, _sentinel)
          ? this.fullAddress
          : fullAddress as String?,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: identical(paymentMethod, _sentinel)
          ? this.paymentMethod
          : paymentMethod as String?,
      workerUid: identical(workerUid, _sentinel)
          ? this.workerUid
          : workerUid as String?,
      workerName: identical(workerName, _sentinel)
          ? this.workerName
          : workerName as String?,
      workerPhone: identical(workerPhone, _sentinel)
          ? this.workerPhone
          : workerPhone as String?,
      workerCode: identical(workerCode, _sentinel)
          ? this.workerCode
          : workerCode as String?,
      etaMinutes: identical(etaMinutes, _sentinel)
          ? this.etaMinutes
          : etaMinutes as int?,
      assignedAt: identical(assignedAt, _sentinel)
          ? this.assignedAt
          : assignedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerBooking &&
          runtimeType == other.runtimeType &&
          bookingId == other.bookingId &&
          rawStatus == other.rawStatus &&
          workerUid == other.workerUid &&
          etaMinutes == other.etaMinutes;

  @override
  int get hashCode => Object.hash(bookingId, rawStatus, workerUid, etaMinutes);

  @override
  String toString() =>
      'CustomerBooking(id: $bookingId, number: $bookingNumber, status: $status)';
}

// Sentinel object used to distinguish "caller passed null" from "caller did not
// pass the argument" in copyWith — avoids the need for an Optional wrapper.
const Object _sentinel = Object();
