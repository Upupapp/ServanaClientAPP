import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/domain/booking/payment_status_parser.dart';

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
    this.effectiveWireStatus = '',
    this.latitude,
    this.longitude,
    this.downPayment = 0,
    this.numberOfPersonnel = 0,
    this.hasResolvedSchedule = true,
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

  /// The status the customer should be shown, after the booking row, the
  /// backend's projection and the worker's own status have been reconciled.
  ///
  /// [status] and [rawStatus] describe the BOOKING row alone.
  /// `BookingStatusMapper.effectiveWireStatus` is the rule that decides which
  /// of three sources wins, and the booking detail screen has always applied
  /// it. Carrying only `rawStatus` would mean a screen reading this model saw
  /// `CONFIRMED` for a booking whose provider is already `IN_PROGRESS`.
  final String effectiveWireStatus;

  /// Service destination coordinates, **null when unknown**.
  ///
  /// Never 0. `getBookingById` selects no coordinate columns — they live in
  /// MongoDB keyed by `location_id` — so absence is the normal case, and a
  /// zero here would beat the tracking screen's `?? 14.5995` Manila fallback
  /// and plot the destination at 0°N 0°E in the Gulf of Guinea. Exactly (0, 0)
  /// cannot be a Philippine service address, so it is read as unknown too.
  final double? latitude;
  final double? longitude;

  /// Amount already paid up front, and how many people the job was booked for.
  final double downPayment;
  final int numberOfPersonnel;

  /// False when [scheduledAt] is a substitute rather than the real schedule.
  ///
  /// [scheduledAt] is non-nullable and falls back to `now` so every screen has
  /// something to render. That is right for display and dangerous for
  /// anything that treats the value as fact: a reschedule sends the schedule
  /// it last read as `expectedSchedule`, and a fabricated instant is refused
  /// with BOOKING_SCHEDULE_CHANGED every time. A caller that needs the truth
  /// checks this first.
  final bool hasResolvedSchedule;

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

  bool get isPaid => PaymentStatusParser.normalize(paymentStatus) == 'PAID';

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
    final parsedSchedule =
        scheduleRaw != null ? DateTime.tryParse(scheduleRaw) : null;
    final scheduledAt = parsedSchedule ?? DateTime.now();

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
      // `serviceOptionName` FIRST. It is service_options.level_3 — the specific
      // thing the customer chose and what checkout showed them — while
      // `serviceName` is its level_2 parent. Reading the parent first renames
      // the customer's booking to the family it belongs to.
      serviceName: (json['serviceOptionName'] ??
              json['serviceName'] ??
              json['merchantServiceName'] ??
              json['service_name'] ??
              (json['service'] is Map
                  ? (json['service'] as Map)['name']
                  : null) ??
              '')
          .toString(),
      // `branchName` is in this chain because the branch IS the place the
      // service belongs to, it was already joined and returned, and it was
      // simply never read. The family is the last resort, not the first.
      serviceCategory: (json['merchantName'] ??
              json['branchName'] ??
              json['providerName'] ??
              json['serviceCategory'] ??
              json['categoryName'] ??
              '')
          .toString(),
      servicePhotoUrl:
          (photoRaw != null && photoRaw.isNotEmpty) ? photoRaw : null,
      scheduledAt: scheduledAt,
      addressLine: (json['addressLine'] ?? json['address'] ?? '').toString(),
      fullAddress: json['fullAddress']?.toString(),
      // `totalAmount` is not a column on the bookings table and never was — it
      // stores quoted_price and final_price. The backend now aliases
      // COALESCE(final_price, quoted_price) AS total_amount, but the fallbacks
      // stay: they keep this correct against a backend that has not been
      // deployed yet, and finalPrice/quotedPrice are the names the admin
      // portal and the provider app already use. Reading `totalAmount` alone
      // is how every booking rendered as ₱0.00.
      //
      // Read through [_money], which tolerates int, double AND string. The
      // chain this replaced was written as `(x as num?)?.toDouble() ?? … ??
      // double.tryParse(x.toString())`, and those tryParse arms could never
      // run: `as num?` on a String THROWS rather than yielding null, so a
      // string-valued price crashed the parse before reaching its own
      // fallback. Postgres numeric reaches JSON as any of the three depending
      // on value and driver.
      totalAmount: _money(json['totalAmount']) ??
          _money(json['finalPrice']) ??
          _money(json['quotedPrice']) ??
          0.0,
      currency: (json['currency'] as String?) ?? 'PHP',
      paymentStatus: PaymentStatusParser.fromBooking(json).isEmpty
          ? 'PENDING'
          : PaymentStatusParser.fromBooking(json),
      paymentMethod: (json['paymentMethod'] ??
              json['paymentMethodUsed'] ??
              json['payment_method'] ??
              (json['payment'] is Map
                  ? (json['payment'] as Map)['method']
                  : null))
          ?.toString()
          .trim()
          .toUpperCase(),
      workerUid:
          (json['workerUid'] ?? json['worker_uid'] ?? json['providerUid'])
              ?.toString(),
      workerName: json['workerName']?.toString(),
      workerPhone: json['workerPhone']?.toString(),
      workerCode: json['workerCode']?.toString(),
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
      assignedAt: assignedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      effectiveWireStatus: BookingStatusMapper.effectiveWireStatus(
        bookingStatus: rawStatus,
        effectiveStatus: json['effectiveStatus']?.toString(),
        workerStatus: (json['workerStatus'] ??
                json['worker_status'] ??
                json['assignmentStatus'])
            ?.toString(),
      ),
      latitude: _coordinate(json['latitude']),
      longitude: _coordinate(json['longitude']),
      downPayment: _money(json['downPayment']) ?? 0.0,
      numberOfPersonnel: _money(json['numberOfPersonnel'])?.toInt() ?? 0,
      hasResolvedSchedule: parsedSchedule != null,
    );
  }

  /// A monetary or numeric value, whatever JSON type it arrived as.
  ///
  /// Returns null for absent and for unparseable, so a caller's `??` chain
  /// decides the default rather than a cast deciding it by throwing. Never
  /// use `as num?` on one of these fields: Postgres numeric can arrive as a
  /// string, and that cast is an exception rather than a null.
  static double? _money(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  /// A coordinate, or null when it is absent or exactly zero.
  ///
  /// Named rather than inlined so both axes read the same and neither can
  /// drift back to `?? 0` — a zero survives every downstream `??` and is what
  /// put the tracking destination in the Gulf of Guinea.
  static double? _coordinate(Object? raw) {
    final value = _money(raw);
    if (value == null || value == 0) return null;
    return value;
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
