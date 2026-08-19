/// `CustomerBooking.fromApiMap` must lose nothing the booking detail screen
/// used to derive for itself.
///
/// ## Why this file exists
///
/// `BookingRepository` was built, registered and never consumed: the booking
/// detail screen kept calling `ServanaApiClient.getBooking` and reading the
/// raw map by hand. Wiring the screen to the repository is the fix, but it is
/// only safe if the domain model carries everything the screen's own parsing
/// carried — and when this was checked, it did not. Five behaviours would have
/// regressed, and one of them was money.
///
/// So each test below is one of those five, written as the assertion that
/// would have caught it. They are not hypothetical: every one describes what
/// `fromApiMap` actually did before this change.
library;

import 'package:client/common/domain/booking/customer_booking.dart';
import 'package:flutter_test/flutter_test.dart';

/// A booking as `formatBooking` serves it, with the fields that matter here.
Map<String, dynamic> booking({
  Map<String, dynamic> overrides = const <String, dynamic>{},
}) =>
    <String, dynamic>{
      'bookingId': 42,
      'bookingCode': 'SVN-000042',
      'status': 'CONFIRMED',
      'scheduledAt': '2026-08-20T09:00:00.000Z',
      'createdAt': '2026-08-18T09:00:00.000Z',
      ...overrides,
    };

void main() {
  group('the amount, which is the one that costs money', () {
    test('falls back to finalPrice when totalAmount is absent', () {
      // `totalAmount` is not a column on the bookings table and never was.
      // Reading it alone is exactly how every booking detail rendered ₱0.00.
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{'finalPrice': 1850}),
      );

      expect(b.totalAmount, 1850.0);
    });

    test('falls back to quotedPrice when neither of the others is there', () {
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{'quotedPrice': 999.5}),
      );

      expect(b.totalAmount, 999.5);
    });

    test('reads a numeric that arrived as a string', () {
      // Postgres numeric reaches JSON as int, double or string depending on
      // the value and the driver. A cast straight to double throws on an int
      // and yields null on a string, and null becomes 0.
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{'finalPrice': '2450.75'}),
      );

      expect(b.totalAmount, 2450.75);
    });

    test('prefers totalAmount when the backend does send it', () {
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{
          'totalAmount': 100,
          'finalPrice': 200,
        }),
      );

      expect(b.totalAmount, 100.0);
    });
  });

  group('the service name is the thing the customer chose', () {
    test('prefers serviceOptionName over its parent serviceName', () {
      // level_3 is the specific service; level_2 is the family it belongs to.
      // Showing the family renames the customer's booking.
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{
          'serviceOptionName': "Emperor's Drip",
          'serviceName': 'Massage & Wellness',
        }),
      );

      expect(b.serviceName, "Emperor's Drip");
    });

    test('falls back to serviceName when there is no option name', () {
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{'serviceName': 'Aircon Cleaning'}),
      );

      expect(b.serviceName, 'Aircon Cleaning');
    });
  });

  group('the category is the place, not the family', () {
    test('reads branchName, which was joined and never read', () {
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{
          'branchName': 'Servana Makati',
          'serviceCategory': 'Beauty & Wellness',
        }),
      );

      expect(b.serviceCategory, 'Servana Makati');
    });

    test('falls back to the family when no place is named', () {
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{
          'serviceCategory': 'Beauty & Wellness',
        }),
      );

      expect(b.serviceCategory, 'Beauty & Wellness');
    });
  });

  group('the status a customer is shown reconciles three sources', () {
    test('a working provider outranks a CONFIRMED booking row', () {
      // The booking row still says CONFIRMED while the provider is on the job.
      // Reading rawStatus alone tells the customer nothing is happening.
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{'workerStatus': 'IN_PROGRESS'}),
      );

      expect(b.effectiveWireStatus, 'IN_PROGRESS');
      expect(b.rawStatus, 'CONFIRMED', reason: 'the row itself is untouched');
    });

    test("the backend's own projection wins outright", () {
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{
          'effectiveStatus': 'WORKER_ASSIGNED',
          'workerStatus': 'ACCEPTED',
        }),
      );

      expect(b.effectiveWireStatus, 'WORKER_ASSIGNED');
    });

    test('a terminal booking row outranks any worker status', () {
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{
          'status': 'CANCELLED',
          'workerStatus': 'IN_PROGRESS',
        }),
      );

      expect(b.effectiveWireStatus, 'CANCELLED');
    });

    test('reads the assignmentStatus alias too', () {
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{'assignmentStatus': 'ARRIVED'}),
      );

      expect(b.effectiveWireStatus, 'ARRIVED');
    });
  });

  group('coordinates are null when unknown, never zero', () {
    test('absent coordinates are null', () {
      // getBookingById selects no coordinate columns, so this is the normal
      // case rather than an edge one.
      final b = CustomerBooking.fromApiMap(booking());

      expect(b.latitude, isNull);
      expect(b.longitude, isNull);
    });

    test('exactly zero is read as unknown', () {
      // (0, 0) is in the Atlantic off West Africa and cannot be a Philippine
      // service address. A zero here beats the tracking screen's Manila
      // fallback and plots the destination in the Gulf of Guinea.
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{'latitude': 0, 'longitude': 0}),
      );

      expect(b.latitude, isNull);
      expect(b.longitude, isNull);
    });

    test('a real coordinate survives', () {
      final b = CustomerBooking.fromApiMap(
        booking(
          overrides: <String, dynamic>{
            'latitude': 14.5995,
            'longitude': 120.9842,
          },
        ),
      );

      expect(b.latitude, 14.5995);
      expect(b.longitude, 120.9842);
    });
  });

  group('the fields the screen carried and the model did not', () {
    test('downPayment and numberOfPersonnel are read', () {
      final b = CustomerBooking.fromApiMap(
        booking(overrides: <String, dynamic>{
          'downPayment': 500,
          'numberOfPersonnel': 3,
        }),
      );

      expect(b.downPayment, 500.0);
      expect(b.numberOfPersonnel, 3);
    });

    test('both default to zero rather than throwing', () {
      final b = CustomerBooking.fromApiMap(booking());

      expect(b.downPayment, 0.0);
      expect(b.numberOfPersonnel, 0);
    });
  });
}
