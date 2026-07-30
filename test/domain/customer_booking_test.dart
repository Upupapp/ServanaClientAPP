import 'package:client/common/data/models/job_order_model.dart';
import 'package:client/common/domain/booking/booking_status.dart';
import 'package:client/common/domain/booking/customer_booking.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

JobOrder _makeJobOrder({
  String jobOrderID = '42',
  String jobOrderNumber = 'SVN-000042',
  String merchantName = 'Wellness Co',
  String merchantServiceName = 'Deep Tissue Massage',
  String merchantServicePhoto = '',
  String jobOrderStatusToString = 'CONFIRMED',
  String address = '123 Main Street, Makati',
  double totalAmount = 1500.0,
  String? paymentStatus = 'PENDING',
  String? paymentMethodUsed,
  DateTime? scheduleDate,
  DateTime? createdDate,
  DateTime? viewDate,
}) {
  final now = DateTime(2025, 3, 15, 10, 0);
  final created = DateTime(2025, 3, 10, 8, 0);
  return JobOrder(
    jobOrderID: jobOrderID,
    jobOrderNumber: jobOrderNumber,
    merchantName: merchantName,
    merchantServiceName: merchantServiceName,
    merchantServicePhoto: merchantServicePhoto,
    jobOrderStatusToString: jobOrderStatusToString,
    address: address,
    numberOfPersonnel: 1,
    distanceFromOffice: 5,
    latitude: 14.5547,
    longitude: 121.0244,
    downPayment: 0.0,
    totalAmount: totalAmount,
    paymentType: 1,
    paymentStatus: paymentStatus,
    paymentMethodUsed: paymentMethodUsed,
    scheduleDate: scheduleDate ?? now,
    createdDate: createdDate ?? created,
    viewDate: viewDate,
  );
}

CustomerBooking _makeBooking({
  String bookingId = '1',
  String bookingNumber = 'SVN-000001',
  String customerId = 'uid-abc',
  BookingStatus status = BookingStatus.confirmed,
  String rawStatus = 'CONFIRMED',
  String serviceName = 'Massage',
  String serviceCategory = 'Wellness',
  String? servicePhotoUrl,
  DateTime? scheduledAt,
  String addressLine = '123 Main St',
  String? fullAddress,
  double totalAmount = 500.0,
  String currency = 'PHP',
  String paymentStatus = 'PENDING',
  String? paymentMethod,
  String? workerUid,
  String? workerName,
  String? workerPhone,
  String? workerCode,
  int? etaMinutes,
  DateTime? assignedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2025, 3, 15);
  return CustomerBooking(
    bookingId: bookingId,
    bookingNumber: bookingNumber,
    customerId: customerId,
    status: status,
    rawStatus: rawStatus,
    serviceName: serviceName,
    serviceCategory: serviceCategory,
    servicePhotoUrl: servicePhotoUrl,
    scheduledAt: scheduledAt ?? now,
    addressLine: addressLine,
    fullAddress: fullAddress,
    totalAmount: totalAmount,
    currency: currency,
    paymentStatus: paymentStatus,
    paymentMethod: paymentMethod,
    workerUid: workerUid,
    workerName: workerName,
    workerPhone: workerPhone,
    workerCode: workerCode,
    etaMinutes: etaMinutes,
    assignedAt: assignedAt,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── fromJobOrder ──────────────────────────────────────────────────────────

  group('CustomerBooking.fromJobOrder', () {
    test('maps bookingId from jobOrderID', () {
      final jo = _makeJobOrder(jobOrderID: '99');
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.bookingId, '99');
    });

    test('maps bookingNumber from jobOrderNumber', () {
      final jo = _makeJobOrder(jobOrderNumber: 'SVN-000099');
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.bookingNumber, 'SVN-000099');
    });

    test('sets customerId to empty string (not available on list model)', () {
      final jo = _makeJobOrder();
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.customerId, isEmpty);
    });

    test('maps status via BookingStatusMapper.fromString', () {
      final jo = _makeJobOrder(jobOrderStatusToString: 'ASSIGNED');
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.status, BookingStatus.assigned);
      expect(booking.rawStatus, 'ASSIGNED');
    });

    test('maps serviceName from merchantServiceName', () {
      final jo = _makeJobOrder(merchantServiceName: 'Swedish Massage');
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.serviceName, 'Swedish Massage');
    });

    test('maps serviceCategory from merchantName', () {
      final jo = _makeJobOrder(merchantName: 'Relax Spa');
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.serviceCategory, 'Relax Spa');
    });

    test('sets servicePhotoUrl to null when merchantServicePhoto is empty', () {
      final jo = _makeJobOrder(merchantServicePhoto: '');
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.servicePhotoUrl, isNull);
    });

    test('sets servicePhotoUrl when merchantServicePhoto is non-empty', () {
      final jo = _makeJobOrder(
          merchantServicePhoto: 'https://cdn.example.com/svc.jpg');
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.servicePhotoUrl, 'https://cdn.example.com/svc.jpg');
    });

    test('maps scheduledAt from scheduleDate', () {
      final date = DateTime(2025, 6, 20, 9, 30);
      final jo = _makeJobOrder(scheduleDate: date);
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.scheduledAt, date);
    });

    test('maps addressLine from address', () {
      final jo = _makeJobOrder(address: '456 Rizal Ave, BGC');
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.addressLine, '456 Rizal Ave, BGC');
    });

    test('maps totalAmount', () {
      final jo = _makeJobOrder(totalAmount: 2500.0);
      final booking = CustomerBooking.fromJobOrder(jo);
      expect(booking.totalAmount, 2500.0);
    });

    test('uses PHP as default currency', () {
      final booking = CustomerBooking.fromJobOrder(_makeJobOrder());
      expect(booking.currency, 'PHP');
    });

    test('maps paymentStatus from jobOrder; falls back to PENDING when null',
        () {
      final joPaid = _makeJobOrder(paymentStatus: 'PAID');
      expect(CustomerBooking.fromJobOrder(joPaid).paymentStatus, 'PAID');

      final joNull = _makeJobOrder(paymentStatus: null);
      expect(CustomerBooking.fromJobOrder(joNull).paymentStatus, 'PENDING');
    });

    test('maps paymentMethod from paymentMethodUsed', () {
      final jo = _makeJobOrder(paymentMethodUsed: 'GCASH');
      expect(CustomerBooking.fromJobOrder(jo).paymentMethod, 'GCASH');
    });

    test('maps createdAt from createdDate', () {
      final date = DateTime(2025, 1, 5);
      final jo = _makeJobOrder(createdDate: date);
      expect(CustomerBooking.fromJobOrder(jo).createdAt, date);
    });

    test('uses viewDate for updatedAt when present', () {
      final viewDate = DateTime(2025, 3, 12);
      final jo = _makeJobOrder(viewDate: viewDate);
      expect(CustomerBooking.fromJobOrder(jo).updatedAt, viewDate);
    });

    test('falls back to createdDate for updatedAt when viewDate is null', () {
      final created = DateTime(2025, 3, 10);
      final jo = _makeJobOrder(createdDate: created, viewDate: null);
      expect(CustomerBooking.fromJobOrder(jo).updatedAt, created);
    });

    test('worker fields are all null (not present on list model)', () {
      final booking = CustomerBooking.fromJobOrder(_makeJobOrder());
      expect(booking.workerUid, isNull);
      expect(booking.workerName, isNull);
      expect(booking.workerPhone, isNull);
      expect(booking.workerCode, isNull);
      expect(booking.etaMinutes, isNull);
      expect(booking.assignedAt, isNull);
    });
  });

  // ── fromApiMap ────────────────────────────────────────────────────────────

  group('CustomerBooking.fromApiMap', () {
    Map<String, dynamic> minimalMap() => {
          'bookingId': '10',
          'bookingCode': 'SVN-000010',
          'customerId': 'firebase-uid',
          'status': 'ASSIGNED',
          'serviceName': 'Cleaning',
          'serviceCategory': 'Home Services',
          'address': '789 Bonifacio St',
          'totalAmount': 800.0,
          'paymentStatus': 'PENDING',
          'scheduledAt': '2025-05-01T14:00:00.000Z',
          'createdAt': '2025-04-28T09:00:00.000Z',
          'updatedAt': '2025-04-29T10:00:00.000Z',
        };

    test('reads bookingId from "bookingId" field', () {
      final map = minimalMap();
      expect(CustomerBooking.fromApiMap(map).bookingId, '10');
    });

    test('reads bookingId from "id" field alias', () {
      final map = minimalMap()
        ..remove('bookingId')
        ..['id'] = '55';
      expect(CustomerBooking.fromApiMap(map).bookingId, '55');
    });

    test('reads customerId from "userId" alias', () {
      final map = minimalMap()
        ..remove('customerId')
        ..['userId'] = 'user-uid-789';
      expect(CustomerBooking.fromApiMap(map).customerId, 'user-uid-789');
    });

    test('reads customerId from "customerUid" alias', () {
      final map = minimalMap()
        ..remove('customerId')
        ..['customerUid'] = 'cuid-999';
      expect(CustomerBooking.fromApiMap(map).customerId, 'cuid-999');
    });

    test('reads scheduledAt from "scheduleAt" alias', () {
      final map = minimalMap()
        ..remove('scheduledAt')
        ..['scheduleAt'] = '2025-06-01T08:00:00.000Z';
      final booking = CustomerBooking.fromApiMap(map);
      expect(booking.scheduledAt, DateTime.parse('2025-06-01T08:00:00.000Z'));
    });

    test('reads scheduledAt from "schedule" alias', () {
      final map = minimalMap()
        ..remove('scheduledAt')
        ..['schedule'] = '2025-07-15T12:00:00.000Z';
      final booking = CustomerBooking.fromApiMap(map);
      expect(booking.scheduledAt, DateTime.parse('2025-07-15T12:00:00.000Z'));
    });

    test('reads workerUid from "providerUid" alias', () {
      final map = minimalMap()..['providerUid'] = 'prov-uid-123';
      expect(CustomerBooking.fromApiMap(map).workerUid, 'prov-uid-123');
    });

    test('"workerUid" takes precedence when both aliases present', () {
      final map = minimalMap()
        ..['workerUid'] = 'worker-uid-1'
        ..['providerUid'] = 'prov-uid-2';
      expect(CustomerBooking.fromApiMap(map).workerUid, 'worker-uid-1');
    });

    test('reads serviceName from "merchantServiceName" alias', () {
      final map = minimalMap()
        ..remove('serviceName')
        ..['merchantServiceName'] = 'AC Repair';
      expect(CustomerBooking.fromApiMap(map).serviceName, 'AC Repair');
    });

    test('reads serviceName from "service_name" alias', () {
      final map = minimalMap()
        ..remove('serviceName')
        ..['service_name'] = 'Pest Control';
      expect(CustomerBooking.fromApiMap(map).serviceName, 'Pest Control');
    });

    test('reads serviceCategory from "categoryName" alias', () {
      final map = minimalMap()
        ..remove('serviceCategory')
        ..['categoryName'] = 'Repairs';
      expect(CustomerBooking.fromApiMap(map).serviceCategory, 'Repairs');
    });

    test('reads serviceCategory from "merchantName" alias', () {
      final map = minimalMap()
        ..remove('serviceCategory')
        ..['merchantName'] = 'Quick Fix';
      expect(CustomerBooking.fromApiMap(map).serviceCategory, 'Quick Fix');
    });

    test('reads servicePhotoUrl from "merchantServicePhoto" alias', () {
      final map = minimalMap()
        ..['merchantServicePhoto'] = 'https://cdn.example.com/img.jpg';
      expect(CustomerBooking.fromApiMap(map).servicePhotoUrl,
          'https://cdn.example.com/img.jpg');
    });

    test('sets servicePhotoUrl to null when photo fields are absent', () {
      final map = minimalMap();
      expect(CustomerBooking.fromApiMap(map).servicePhotoUrl, isNull);
    });

    test('reads addressLine from "addressLine" alias', () {
      final map = minimalMap()
        ..remove('address')
        ..['addressLine'] = '100 Ayala Ave';
      expect(CustomerBooking.fromApiMap(map).addressLine, '100 Ayala Ave');
    });

    test('reads paymentMethod from "paymentMethodUsed" alias', () {
      final map = minimalMap()..['paymentMethodUsed'] = 'CARD';
      expect(CustomerBooking.fromApiMap(map).paymentMethod, 'CARD');
    });

    test('maps status string to canonical enum value', () {
      final map = minimalMap()..['status'] = 'IN_PROGRESS';
      expect(CustomerBooking.fromApiMap(map).status, BookingStatus.inProgress);
    });

    test('defaults currency to PHP when not provided', () {
      final map = minimalMap();
      expect(CustomerBooking.fromApiMap(map).currency, 'PHP');
    });

    test('reads explicit currency when provided', () {
      final map = minimalMap()..['currency'] = 'USD';
      expect(CustomerBooking.fromApiMap(map).currency, 'USD');
    });

    test('parses etaMinutes as int', () {
      final map = minimalMap()..['etaMinutes'] = 15;
      expect(CustomerBooking.fromApiMap(map).etaMinutes, 15);
    });

    test('parses assignedAt when provided', () {
      final map = minimalMap()..['assignedAt'] = '2025-04-29T09:30:00.000Z';
      expect(CustomerBooking.fromApiMap(map).assignedAt,
          DateTime.parse('2025-04-29T09:30:00.000Z'));
    });
  });

  // ── copyWith ──────────────────────────────────────────────────────────────

  group('CustomerBooking.copyWith', () {
    test('preserves all unmodified fields', () {
      final original = _makeBooking(
        bookingId: '5',
        serviceName: 'Haircut',
        totalAmount: 300.0,
        workerUid: 'worker-uid-abc',
      );
      final copy = original.copyWith(bookingNumber: 'SVN-000005');

      expect(copy.bookingId, original.bookingId);
      expect(copy.serviceName, original.serviceName);
      expect(copy.totalAmount, original.totalAmount);
      expect(copy.workerUid, original.workerUid);
    });

    test('updates specified fields', () {
      final original = _makeBooking(status: BookingStatus.confirmed);
      final updated = original.copyWith(
        status: BookingStatus.assigned,
        rawStatus: 'ASSIGNED',
      );
      expect(updated.status, BookingStatus.assigned);
      expect(updated.rawStatus, 'ASSIGNED');
    });

    test('can set nullable fields to null via sentinel bypass', () {
      final original =
          _makeBooking(servicePhotoUrl: 'https://example.com/photo.jpg');
      expect(original.servicePhotoUrl, isNotNull);
      // ignore: avoid_redundant_argument_values
      final nulled = original.copyWith(servicePhotoUrl: null);
      expect(nulled.servicePhotoUrl, isNull);
    });

    test('can set workerUid and etaMinutes together', () {
      final original = _makeBooking();
      final updated = original.copyWith(
        workerUid: 'worker-fire-123',
        etaMinutes: 12,
      );
      expect(updated.workerUid, 'worker-fire-123');
      expect(updated.etaMinutes, 12);
    });
  });

  // ── Derived getters ───────────────────────────────────────────────────────

  group('CustomerBooking derived getters', () {
    test('isTerminal is true for completed status', () {
      final booking = _makeBooking(status: BookingStatus.completed);
      expect(booking.isTerminal, isTrue);
    });

    test('isTerminal is false for assigned status', () {
      final booking = _makeBooking(status: BookingStatus.assigned);
      expect(booking.isTerminal, isFalse);
    });

    test('isPaid is true when paymentStatus is PAID', () {
      final booking = _makeBooking(paymentStatus: 'PAID');
      expect(booking.isPaid, isTrue);
    });

    test('isPaid is false when paymentStatus is PENDING', () {
      final booking = _makeBooking(paymentStatus: 'PENDING');
      expect(booking.isPaid, isFalse);
    });

    test('requiresOtp is true for pendingOtp status', () {
      final booking = _makeBooking(status: BookingStatus.pendingOtp);
      expect(booking.requiresOtp, isTrue);
    });

    test('shouldPollAssignment is true for awaitingAssignment', () {
      final booking = _makeBooking(status: BookingStatus.awaitingAssignment);
      expect(booking.shouldPollAssignment, isTrue);
    });

    test('statusLabel returns non-empty string', () {
      final booking = _makeBooking(status: BookingStatus.inProgress);
      expect(booking.statusLabel, isNotEmpty);
    });

    test('statusSubtitle returns non-empty string', () {
      final booking = _makeBooking(status: BookingStatus.inProgress);
      expect(booking.statusSubtitle, isNotEmpty);
    });

    test('groupCategory returns expected bucket for active status', () {
      final booking = _makeBooking(status: BookingStatus.enRoute);
      expect(booking.groupCategory, 'active');
    });
  });
}
