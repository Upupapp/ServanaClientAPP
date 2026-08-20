/// Can a customer who found a service in the catalog actually book it?
///
/// ## Why this file exists
///
/// `journey_contract_test.dart` (TAB 01) pins the request and response SHAPES
/// against what production answered. It cannot answer the question above,
/// because a shape is not a journey: every fixture in it agrees with the server
/// and the app still has to get the customer from the service card to a created
/// booking.
///
/// This drives the real screens and the real stores over a transport that
/// answers with production's bodies, and asserts the customer reaches a
/// booking. It is the finder the MVP go/no-go actually needs.
///
/// ## The production facts these tests are built on — measured 2026-08-20
///
///  - `GET /api/catalog/summary` → 3 categories, 12 subcategories, 95 services.
///  - Category 1 Home Maintenance has 1 service, category 2 Home Services 30,
///    category 3 Personal Care 64. Only category 2 takes the aircon checkout;
///    the other 65 services take the Beauty & Wellness one.
///  - `GET /api/services/:id/branches` returns `{"success":true,"branches":[]}`
///    for NINE of the ten legacy families. Only family 2 has a branch, and it
///    is a sample row ("BGC Clinic").
///  - The backend's own create validator types `branchId?: number` and
///    `createBooking` guards every branch read with
///    `if (payload.branchId !== undefined)`. A booking with no branch is
///    accepted.
///
/// So a client-side rule that REFUSES to submit without a branch is stricter
/// than the server, and it is the only thing standing between a customer and a
/// booking for 65 of the 95 services on offer.
library;

import 'dart:convert';

import 'package:client/common/domain/booking/booking_create_request.dart';
import 'package:client/common/domain/booking/booking_draft.dart'
    show BookingFlowType;
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_branch_slot_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_checkout_screen.dart';
import 'package:client/modules/catalog/application/canonical_booking_handoff.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/screen_test_container.dart';

/// One saved address, in the shape `GET /api/user/alluseraddresses` returns.
///
/// `locationId` matters: the backend resolves it to coordinates and refuses a
/// booking without one ("Address missing locationId."), and the format is the
/// mobile-compatible `loc_{lat}_{lon}` of §42.
const _savedAddress = {
  'addressId': 'CAD123',
  'userId': 'test-customer-uid',
  'locationId': 'loc_14.554700_121.024400',
  'addressOne': '12 Sample Street',
  'addressTwo': 'Unit 4',
  'postTown': 'Taguig',
  'country': 'Philippines',
  'lat': 14.5547,
  'lon': 121.0244,
  'label': 'Home',
  'isPrimary': true,
};

/// `POST /api/bookings` on success. `booking.id` is what the parser reads.
const _bookingCreated = {
  'success': true,
  'booking': {
    'id': 4242,
    'status': 'PENDING_OTP',
    'workerCode': null,
  },
};

/// A canonical Personal Care service, in the shape
/// `GET /api/catalog/services/:id` returns. Service 1 is "Beauty Drip" in
/// production; category 3, so it takes the Beauty & Wellness checkout.
CatalogServiceDetail _personalCareService() => const CatalogServiceDetail(
      service: CatalogService(
        id: 1,
        subcategoryId: 7,
        subcategoryName: 'Beauty Drip',
        categoryId: 3,
        categoryName: 'Personal Care',
        name: 'Glutathione Drip',
        slug: 'glutathione-drip-1',
        status: CatalogStatus.active,
        displayOrder: 0,
        bookable: true,
        basePrice: 3500,
        unit: 'per session',
      ),
      available: true,
    );

/// A canonical Home Services service — category 2, so it takes aircon.
CatalogServiceDetail _homeServicesService() => const CatalogServiceDetail(
      service: CatalogService(
        id: 130,
        subcategoryId: 2,
        subcategoryName: 'Cleaning',
        categoryId: 2,
        categoryName: 'Home Services',
        name: 'Aircon Cleaning for Cassette Type',
        slug: 'aircon-cleaning-cassette-130',
        status: CatalogStatus.active,
        displayOrder: 0,
        bookable: true,
        basePrice: 3190,
        unit: 'per unit',
      ),
      available: true,
    );

/// Records every request so a test can assert on the payload that was sent —
/// the booking payload is money, and asserting on the store's own fields would
/// only prove the store agrees with itself.
class _RecordingBackend {
  final List<http.Request> requests = <http.Request>[];

  http.Client client() => MockClient((request) async {
        requests.add(request);
        final path = request.url.path;

        if (path.contains('/alluseraddresses')) {
          return _json({
            'status': 'success',
            'data': [_savedAddress],
          });
        }
        if (path == '/api/bookings' && request.method == 'POST') {
          return _json(_bookingCreated);
        }
        if (path.contains('/branches')) {
          // Production's answer for nine of ten families.
          return _json({'success': true, 'branches': <dynamic>[]});
        }
        return _json(
            {'success': true, 'status': 'success', 'data': <dynamic>[]});
      });

  http.Response _json(Object body) => http.Response(
        jsonEncode(body),
        200,
        headers: const {'content-type': 'application/json'},
      );

  /// The decoded body of the booking create, or null if none was attempted.
  Map<String, dynamic>? get bookingPayload {
    for (final r in requests.reversed) {
      if (r.url.path == '/api/bookings' && r.method == 'POST') {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingBackend backend;

  setUp(() async {
    backend = _RecordingBackend();
    await registerScreenDependencies(client: backend.client());

    // A STABLE cipher key. The container's stub answers `read` with null, so
    // every `retrieveCipherKey` would mint a NEW key, open the Hive box with a
    // cipher that cannot decrypt it, and fall into the delete-and-reopen
    // branch — losing the session between the write and the read. A signed-in
    // customer is the whole premise of a booking test.
    const key = 'c2VydmFuYS10ZXN0LWNpcGhlci1rZXktMzJieXRlcyE=';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => switch (call.method) {
        'readAll' => <String, String>{},
        'read' => call.arguments['key'] == 'shadow_heat_key' ? key : null,
        _ => null,
      },
    );

    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(UserSessionAdapter());
    }
    await SessionService.saveSession(const UserSession(
      customerID: 'test-customer-uid',
      mobileNumber: '09171234567',
      fullname: 'Test Customer',
      emailAddress: 'test@example.com',
      token: 'test-token',
    ));
    dpLocator<AuthStateService>().update(AuthStatus.authenticated);
  });

  tearDown(() async {
    await SessionService.deleteSession();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
    await resetScreenDependencies();
  });

  group('a Personal Care service found in the catalog can be booked', () {
    test('the handoff seeds the Beauty & Wellness store with the canonical id',
        () {
      final detail = _personalCareService();
      final option = canonicalOptionMap(detail);

      expect(resolveBookingFlow(detail.service),
          CanonicalBookingFlow.beautyWellness);
      // The id that lands in the payload's `serviceOptionId` is the canonical
      // `services.id` the customer selected, not a legacy option row.
      expect(option['id'], 1);
      expect(option['catalogCategoryId'], 3);
    });

    test('the customer reaches a created booking', () async {
      final store = dpLocator<BwBookingStore>();
      store.selectOption(canonicalOptionMap(_personalCareService()));

      await store.loadSavedAddresses();
      expect(store.savedAddresses, isNotEmpty,
          reason: 'the address list is the first thing checkout needs');
      store.selectAddress(store.savedAddresses.first);

      // The catalog handoff routes STRAIGHT to checkout — there is no branch
      // screen on this path, and production has no branch to offer anyway.
      store.setSchedule(DateTime.now().add(const Duration(days: 2, hours: 3)));
      store.setPaymentMethod('CASH');

      await store.createBooking();

      expect(store.submissionError, isNull,
          reason: 'a service with no branches must still be bookable — the '
              'backend types branchId as optional');
      expect(store.createdBookingId, 4242);
    });

    test('the payload carries no branch, and the server is not asked for one',
        () async {
      final store = dpLocator<BwBookingStore>();
      store.selectOption(canonicalOptionMap(_personalCareService()));
      await store.loadSavedAddresses();
      store.selectAddress(store.savedAddresses.first);
      store.setSchedule(DateTime.now().add(const Duration(days: 2)));
      store.setPaymentMethod('CASH');

      await store.createBooking();

      final payload = backend.bookingPayload;
      expect(payload, isNotNull, reason: 'nothing was ever submitted');
      expect(payload!.containsKey('branchId'), isFalse,
          reason: 'sending branchId: null makes the backend validator reject '
              'the booking with "A valid branch is required."');
      expect(payload['serviceOptionId'], 1);
      expect(payload['userAddressId'], 'CAD123');
      expect(payload['paymentMethod'], 'CASH');
      // UTC on the wire: a naive local timestamp turns a 9am booking into a
      // 1am one for anyone whose device is not in Asia/Manila.
      expect(payload['schedule'], endsWith('Z'));
    });
  });

  group('a Home Services service takes the aircon checkout and still books',
      () {
    test('the flow resolves to aircon and submits', () async {
      final detail = _homeServicesService();
      expect(resolveBookingFlow(detail.service), CanonicalBookingFlow.aircon);

      final store = dpLocator<AirconBookingStore>();
      store.selectOption(canonicalOptionMap(detail));
      await store.loadSavedAddresses();
      store.selectAddress(store.savedAddresses.first);
      store.setSchedule(DateTime.now().add(const Duration(days: 1, hours: 2)));
      store.setPaymentMethod('CASH');

      await store.createBooking();

      expect(store.submissionError, isNull);
      expect(store.createdBookingId, 4242);
    });
  });

  group('a branch is required only when the service offers one', () {
    test('no branches loaded means no branch demanded', () {
      final request = BookingCreateRequest(
        flowType: BookingFlowType.beautyWellness,
        serviceOptionId: 1,
        userAddressId: 'CAD123',
        schedule: DateTime.now().add(const Duration(days: 1)),
        paymentMethod: 'CASH',
        requiresBranch: false,
      );
      expect(request.validate(), isEmpty);
    });

    test('a branch flow that HAS branches still demands one', () {
      final request = BookingCreateRequest(
        flowType: BookingFlowType.beautyWellness,
        serviceOptionId: 1,
        userAddressId: 'CAD123',
        schedule: DateTime.now().add(const Duration(days: 1)),
        paymentMethod: 'CASH',
        requiresBranch: true,
      );
      expect(request.validate(), contains(BookingRequestInvalidity.noBranch));
    });

    test('the store demands a branch only while it holds branches to choose',
        () async {
      final store = dpLocator<BwBookingStore>();
      expect(store.branches, isEmpty);
      expect(store.branchRequired, isFalse,
          reason: 'production answers branches:[] for nine of ten families');

      store.branches.add(const {'branchId': 1, 'branchName': 'BGC Clinic'});
      expect(store.branchRequired, isTrue);
    });

    test(
        'a branch list left over from another category does not follow the '
        'customer into a canonical booking', () async {
      final store = dpLocator<BwBookingStore>();
      // What a visit to Beauty & Wellness (legacy family 2 — the one family
      // that HAS a branch) leaves behind. `clearSelectionOnly` deliberately
      // preserves it for catalog reuse.
      store.branches.add(const {'branchId': 1, 'branchName': 'BGC Clinic'});
      store.clearSelectionOnly();
      expect(store.branchRequired, isTrue,
          reason: 'the stale list is exactly the condition being guarded');

      store.beginBranchlessBooking();
      expect(store.branchRequired, isFalse);
    });
  });

  group('the checkout screen offers the control its own refusal names', () {
    testWidgets('a service with no branch gets a schedule picker',
        (tester) async {
      final store = dpLocator<BwBookingStore>();
      store.beginBranchlessBooking();
      store.selectOption(canonicalOptionMap(_personalCareService()));
      await store.loadSavedAddresses();

      await tester.pumpWidget(const MaterialApp(home: BwCheckoutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Tap to choose a date and time'), findsOneWidget);
      // The branch heading belongs to the flow that can actually offer one.
      expect(find.text('No branch selected.'), findsNothing);
    });

    testWidgets('the customer can pick a date and time and see it',
        (tester) async {
      final store = dpLocator<BwBookingStore>();
      store.beginBranchlessBooking();
      store.selectOption(canonicalOptionMap(_personalCareService()));
      await store.loadSavedAddresses();

      await tester.pumpWidget(const MaterialApp(home: BwCheckoutScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap to choose a date and time'));
      await tester.pumpAndSettle();
      // The date picker opens on today; OK accepts it.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      // Then the time picker.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(store.selectedSchedule, isNotNull,
          reason: 'the picker must reach the store, not only the screen');
      expect(store.effectiveSchedule, isNotNull);
    });

    testWidgets('a branch flow still shows the branch it selected',
        (tester) async {
      final store = dpLocator<BwBookingStore>();
      store.selectOption(canonicalOptionMap(_personalCareService()));
      store.branches.add(const {'branchId': 1, 'branchName': 'BGC Clinic'});
      store.selectBranch(const {'branchId': 1, 'branchName': 'BGC Clinic'});
      await store.loadSavedAddresses();

      await tester.pumpWidget(const MaterialApp(home: BwCheckoutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('BGC Clinic'), findsOneWidget);
      // ...and does NOT draw a second, contradicting schedule control.
      expect(find.text('Tap to choose a date and time'), findsNothing);
    });
  });

  group('the branch and slot screen no longer dead-ends', () {
    testWidgets('a service with no branches explains why and offers a time',
        (tester) async {
      final store = dpLocator<BwBookingStore>();
      store.beginBranchlessBooking();
      store.selectOption(canonicalOptionMap(_personalCareService()));

      await tester.pumpWidget(const MaterialApp(home: BwBranchSlotScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Time'), findsOneWidget);
      expect(
        find.textContaining('scheduled directly with your provider'),
        findsOneWidget,
        reason: 'an empty list with no explanation is the dead end itself',
      );
    });
  });
}
