/// The customer journey, walked end to end through the real objects.
///
/// ## What this is for
///
/// The MVP question is not "does each unit work" — 2,600 tests already answer
/// that — it is "can one customer get from the catalog to a reviewed booking
/// without hitting a step that cannot be completed". Every unit test in this
/// suite stops at the seam it owns, which is right for a unit test and useless
/// as a go/no-go.
///
/// This drives the SAME repositories and controllers the app resolves, over a
/// transport answering with production's envelopes, and asserts each step hands
/// the next one something it can use.
///
/// ## Which steps are automated here, and which are not
///
/// Automated: catalog browse, service detail, the booking handoff, booking
/// creation, My Bookings, booking detail, review eligibility.
///
/// NOT automated, and deliberately named rather than silently skipped — a
/// walkthrough that quietly omits a step reads as a green light for it:
///
///  - **Email verification.** Sign-up mails a 6-digit OTP to a human inbox.
///  - **Booking OTP.** `POST /api/bookings` mails an `otpCode`; verifying it is
///    the same out-of-band step.
///  - **PayMongo checkout.** A hosted page in a WebView on a real device.
///  - **A provider accepting, arriving and completing.** Needs the other app.
///
/// Those four are the manual script. Everything before and between them is
/// asserted below.
///
/// ## Fixtures
///
/// Captured from `api.servana.com.ph` on 2026-08-20, by requesting the same
/// paths the app requests. A fixture that agrees with the client by
/// construction proves nothing; these agree with the SERVER by construction.
/// When production changes shape they go stale and should be re-captured rather
/// than edited to match the client.
library;

import 'dart:convert';

import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/modules/bookings/data/booking_repository.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/catalog/application/catalog_controller.dart';
import 'package:client/modules/catalog/application/canonical_booking_handoff.dart';
import 'package:client/modules/catalog/application/service_detail_controller.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:client/modules/review/data/reviews_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/screen_test_container.dart';

const _customerUid = 'test-customer-uid';
const _bookingId = 4242;

/// `GET /api/catalog` — trimmed to one Service per category, keeping the exact
/// nesting and field names production returns.
const _catalog = {
  'status': 'success',
  'data': {
    'categories': [
      {
        'ref': 'category:1',
        'id': 1,
        'name': 'Home Maintenance',
        'slug': 'home-maintenance',
        'displayOrder': 0,
        'subcategoryCount': 1,
        'serviceCount': 1,
        'subcategories': [
          {
            'ref': 'subcategory:1',
            'id': 1,
            'categoryId': 1,
            'name': 'Electrical',
            'slug': 'electrical',
            'displayOrder': 0,
            'serviceCount': 1,
            'services': [
              {
                'ref': 'service:180',
                'id': 180,
                'subcategoryId': 1,
                'subcategoryName': 'Electrical',
                'categoryId': 1,
                'categoryName': 'Home Maintenance',
                'name': 'Wiring fuitures',
                'slug': 'wiring-fuitures-180',
                'status': 'active',
                'displayOrder': 0,
                'bookable': true,
                'basePrice': 5000,
                'unit': '1 hour',
              },
            ],
          },
        ],
      },
      {
        'ref': 'category:3',
        'id': 3,
        'name': 'Personal Care',
        'slug': 'personal-care',
        'displayOrder': 2,
        'subcategoryCount': 1,
        'serviceCount': 1,
        'subcategories': [
          {
            'ref': 'subcategory:7',
            'id': 7,
            'categoryId': 3,
            'name': 'Beauty Drip',
            'slug': 'beauty-drip',
            'displayOrder': 0,
            'serviceCount': 1,
            'services': [
              {
                'ref': 'service:1',
                'id': 1,
                'subcategoryId': 7,
                'subcategoryName': 'Beauty Drip',
                'categoryId': 3,
                'categoryName': 'Personal Care',
                'name': 'Gluta Drip',
                'slug': 'gluta-drip-1',
                'status': 'active',
                'displayOrder': 0,
                'bookable': true,
                'basePrice': 990,
                'unit': 'per session',
              },
            ],
          },
        ],
      },
    ],
    'summary': {'categories': 3, 'subcategories': 12, 'services': 95},
  },
};

/// `GET /api/catalog/services/1`, verbatim apart from the addon list being
/// trimmed to two.
const _serviceDetail = {
  'status': 'success',
  'data': {
    'ref': 'service:1',
    'id': 1,
    'subcategoryId': 7,
    'subcategoryName': 'Beauty Drip',
    'categoryId': 3,
    'categoryName': 'Personal Care',
    'name': 'Gluta Drip',
    'slug': 'gluta-drip-1',
    'shortDescription': null,
    'imageUrl': null,
    'status': 'active',
    'displayOrder': 0,
    'bookable': true,
    'basePrice': 990,
    'unit': 'per session',
    'estimatedDurationMins': null,
    'fullDescription': null,
    'inclusions': <String>[],
    'exclusions': <String>[],
    'available': true,
    'addons': [
      {
        'ref': 'addon:10',
        'id': 10,
        'name': 'Collagen',
        'unit': 'per session',
        'basePrice': 350,
        'durationMins': 120,
      },
      {
        'ref': 'addon:6',
        'id': 6,
        'name': 'Vitamin C',
        'unit': 'per session',
        'basePrice': 350,
        'durationMins': 120,
      },
    ],
  },
};

const _savedAddress = {
  'addressId': 'CAD123',
  'userId': _customerUid,
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

/// `GET /api/users/:uid/bookings`.
///
/// The envelope is `{success, bookings}` and the money arrives as a STRING —
/// `COALESCE(final_price, quoted_price) AS total_amount` is Postgres `numeric`,
/// which the pg driver hands over as a string for values it will not narrow.
/// That is the shape that once rendered every booking as ₱0.00.
const _bookingsList = {
  'success': true,
  'bookings': [
    {
      'id': _bookingId,
      'bookingId': _bookingId,
      'bookingCode': 'SVN-004242',
      'userId': _customerUid,
      'customerUid': _customerUid,
      'status': 'PENDING_OTP',
      'statusLower': 'pending_otp',
      'effectiveStatus': 'PENDING_OTP',
      'schedule': '2026-08-24T03:00:00.000Z',
      'scheduleAt': '2026-08-24T03:00:00.000Z',
      'serviceId': 2,
      'serviceName': 'Beauty Drip',
      'serviceOptionName': 'Gluta Drip',
      'serviceCategory': 'Beauty & Wellness',
      'totalAmount': '990.00',
      'paymentStatus': 'PENDING',
      'paymentMethodUsed': 'CASH',
      'addressLine': '12 Sample Street, Taguig',
    },
  ],
};

/// `GET /api/:id` — booking detail. Same row, under a `booking` key.
const _bookingDetail = {
  'success': true,
  'booking': {
    'id': _bookingId,
    'bookingCode': 'SVN-004242',
    'userId': _customerUid,
    'status': 'PENDING_OTP',
    'effectiveStatus': 'PENDING_OTP',
    'schedule': '2026-08-24T03:00:00.000Z',
    'serviceOptionName': 'Gluta Drip',
    'totalAmount': '990.00',
    'paymentStatus': 'PENDING',
    'addressLine': '12 Sample Street, Taguig',
  },
};

/// `GET /api/bookings/:id/review-eligibility`, in the shape
/// `getReviewEligibility` returns for a booking that is not finished.
const _reviewNotYet = {
  'bookingId': '$_bookingId',
  'eligible': false,
  'reason': 'BOOKING_NOT_COMPLETED',
  'reviewId': null,
  'reviewWindow': null,
  'editableUntil': null,
  'availableActions': <String>[],
};

class _Production {
  final List<http.Request> requests = <http.Request>[];

  http.Client client() => MockClient((request) async {
        requests.add(request);
        final path = request.url.path;

        if (path == '/api/catalog') return _json(_catalog);
        if (path.startsWith('/api/catalog/services/')) {
          return _json(_serviceDetail);
        }
        if (path.contains('alluseraddresses')) {
          return _json({
            'status': 'success',
            'data': [_savedAddress],
          });
        }
        if (path == '/api/bookings' && request.method == 'POST') {
          return _json({
            'success': true,
            'booking': {'id': _bookingId, 'status': 'PENDING_OTP'},
          });
        }
        if (path.endsWith('/bookings') && request.method == 'GET') {
          return _json(_bookingsList);
        }
        if (path.endsWith('/review-eligibility')) return _json(_reviewNotYet);
        if (path == '/api/$_bookingId') return _json(_bookingDetail);

        return _json(
            {'success': true, 'status': 'success', 'data': <dynamic>[]});
      });

  http.Response _json(Object body) => http.Response(
        jsonEncode(body),
        200,
        headers: const {'content-type': 'application/json'},
      );

  bool requested(String path) => requests.any((r) => r.url.path.contains(path));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Production backend;

  setUp(() async {
    backend = _Production();
    await registerScreenDependencies(client: backend.client());

    const key = 'c2VydmFuYS10ZXN0LWNpcGhlci1rZXktMzJieXRlcyE=';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => switch (call.method) {
        'readAll' => <String, String>{},
        'read' => key,
        _ => null,
      },
    );
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(UserSessionAdapter());
    }
    await SessionService.saveSession(const UserSession(
      customerID: _customerUid,
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

  test('a customer walks from the catalog to a booking they can see', () async {
    // ── 1. Browse ────────────────────────────────────────────────────────────
    final catalog = dpLocator<CatalogController>();
    await catalog.load();

    expect(catalog.catalog.isEmpty, isFalse,
        reason: 'nothing to browse means nothing to book');
    final personalCare = catalog.catalog.categoryById(3);
    expect(personalCare, isNotNull);
    final service = personalCare!.subcategories.first.services.first;
    expect(service.id, 1);
    expect(service.bookable, isTrue);

    // ── 2. Open the service ──────────────────────────────────────────────────
    final detailController = dpLocator<ServiceDetailController>();
    await detailController.load(service.id);
    final detail = detailController.detail;

    expect(detail, isNotNull, reason: 'the detail screen has nothing to show');
    expect(detail!.available, isTrue);
    expect(detail.addons, hasLength(2));

    // ── 3. Hand off to a checkout ────────────────────────────────────────────
    expect(resolveBookingFlow(detail.service),
        CanonicalBookingFlow.beautyWellness);
    final option = canonicalOptionMap(detail);
    expect(option['id'], 1, reason: 'the canonical id must reach the payload');

    final store = dpLocator<BwBookingStore>();
    store.beginBranchlessBooking();
    store.selectOption(option);
    store.toggleAddon(10);

    // ── 4. Address, schedule, payment ────────────────────────────────────────
    await store.loadSavedAddresses();
    expect(store.savedAddresses, hasLength(1));
    store.selectAddress(store.savedAddresses.first);
    store.setSchedule(DateTime.now().add(const Duration(days: 4, hours: 3)));
    store.setPaymentMethod('CASH');

    expect(store.branchRequired, isFalse);
    expect(store.effectiveSchedule, isNotNull);

    // ── 5. Book ──────────────────────────────────────────────────────────────
    await store.createBooking();

    expect(store.submissionError, isNull);
    expect(store.createdBookingId, _bookingId);

    // ── 6. My Bookings ───────────────────────────────────────────────────────
    final bookings = dpLocator<BookingRepository>();
    final mine = await bookings.getBookings(_customerUid);

    expect(mine, hasLength(1), reason: 'the booking just made must appear');
    final listed = mine.single;
    expect(listed.bookingId, '$_bookingId');
    // The number the customer just agreed to pay, arriving as a STRING.
    expect(listed.totalAmount, 990.0,
        reason: 'a numeric-as-string total is what rendered every booking as '
            'PHP 0.00');

    // ── 7. Booking detail ────────────────────────────────────────────────────
    final opened = await bookings.getBookingById('$_bookingId');
    expect(opened.bookingId, '$_bookingId');
    expect(opened.totalAmount, 990.0,
        reason: 'the list and the detail must agree about the money');

    // ── 8. Review eligibility ────────────────────────────────────────────────
    final reviews = dpLocator<ReviewsRepository>();
    final eligibility = await reviews.getEligibility('$_bookingId');

    expect(eligibility.eligible, isFalse,
        reason: 'a booking that has not happened cannot be reviewed');
    expect(backend.requested('review-eligibility'), isTrue);
  });

  test('every step of the walk actually reached the network', () async {
    final catalog = dpLocator<CatalogController>();
    await catalog.load();
    await dpLocator<ServiceDetailController>().load(1);

    final store = dpLocator<BwBookingStore>();
    store.beginBranchlessBooking();
    store.selectOption(
      canonicalOptionMap(dpLocator<ServiceDetailController>().detail!),
    );
    await store.loadSavedAddresses();
    store.selectAddress(store.savedAddresses.first);
    store.setSchedule(DateTime.now().add(const Duration(days: 4)));
    store.setPaymentMethod('CASH');
    await store.createBooking();
    await dpLocator<BookingRepository>().getBookings(_customerUid);

    // A walkthrough that satisfies itself from cached state proves nothing
    // about the app talking to a server.
    for (final path in const [
      '/api/catalog',
      '/api/catalog/services/1',
      'alluseraddresses',
      '/api/bookings',
      '/bookings',
    ]) {
      expect(backend.requested(path), isTrue, reason: 'never requested $path');
    }
  });

  test('the booking payload is idempotent across a retry of the same draft',
      () async {
    final store = dpLocator<BwBookingStore>();
    store.beginBranchlessBooking();
    store.selectOption(canonicalOptionMap(
      // Straight from the production body rather than a hand-built model.
      _detailFromFixture(),
    ));
    await store.loadSavedAddresses();
    store.selectAddress(store.savedAddresses.first);
    store.setSchedule(DateTime.now().add(const Duration(days: 4)));
    store.setPaymentMethod('CASH');

    await store.createBooking();
    final firstKey = _idempotencyKeyOf(backend.requests);

    // `isSubmitting` stays true after a success, so a retry has to come from a
    // fresh attempt on the same draft. Reset only the guard.
    store.isSubmitting = false;
    await store.createBooking();
    final secondKey = _idempotencyKeyOf(backend.requests);

    expect(firstKey, isNotNull);
    expect(secondKey, equals(firstKey),
        reason: 'regenerating the key on retry is what turns one booking into '
            'two');
  });
}

/// The service detail, parsed from the captured body by the app's OWN factory.
///
/// Building a `CatalogServiceDetail` by hand here would prove the test agrees
/// with itself. Parsing the captured body proves the model agrees with the
/// server.
CatalogServiceDetail _detailFromFixture() => CatalogServiceDetail.fromJson(
      (_serviceDetail['data']! as Map).cast<String, dynamic>(),
    );

String? _idempotencyKeyOf(List<http.Request> requests) {
  for (final request in requests.reversed) {
    if (request.url.path == '/api/bookings' && request.method == 'POST') {
      return request.headers['X-Idempotency-Key'] ??
          request.headers['x-idempotency-key'];
    }
  }
  return null;
}
