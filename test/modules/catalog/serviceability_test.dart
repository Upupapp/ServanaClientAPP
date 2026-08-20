/// Asking "can this be booked here?" before the customer fills in a form.
///
/// Every body below was captured from `api.servana.com.ph` on 2026-08-20 by
/// calling the live route, not written to agree with the parser:
///
///   /1/serviceability?lat=14.5547&lon=121.0244
///     {"serviceable":true,"reason":null,"defaulted":false}
///   /19/serviceability?lat=10.3157&lon=123.8854      (Cebu, Manila-only family)
///     {"serviceable":false,"reason":"OUTSIDE_SERVICE_AREA","defaulted":false}
///   /180/serviceability?lat=14.5547&lon=121.0244     (covered, zero providers)
///     {"serviceable":false,"reason":"NO_CAPABLE_PROVIDER","defaulted":false}
///   /1/serviceability                                 (no coordinates)
///     {"serviceable":false,"reason":"INVALID_LOCATION","defaulted":false}
library;

import 'dart:convert';

import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/modules/catalog/domain/serviceability.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/screen_test_container.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: const {'content-type': 'application/json'},
    );

/// Serves the live envelope, and records what was asked.
class _Backend {
  _Backend(this.answer);

  final Object Function() answer;
  final List<Uri> asked = <Uri>[];

  http.Client client() => MockClient((request) async {
        if (request.url.path.endsWith('/serviceability')) {
          asked.add(request.url);
          final body = answer();
          if (body is http.Response) return body;
          return _json(body);
        }
        if (request.url.path.contains('alluseraddresses')) {
          return _json({
            'status': 'success',
            'data': [
              {
                'addressId': 'CAD1',
                'lat': 14.5547,
                'lon': 121.0244,
                'addressOne': '12 Sample Street',
              }
            ],
          });
        }
        return _json(
            {'success': true, 'status': 'success', 'data': <dynamic>[]});
      });
}

Object _ok() => {
      'status': 'success',
      'data': {'serviceable': true, 'reason': null, 'defaulted': false},
    };

Object _refusal(String reason) => {
      'status': 'success',
      'data': {'serviceable': false, 'reason': reason, 'defaulted': false},
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async => resetScreenDependencies());

  group('the verdict is parsed as the server sends it', () {
    test('a yes carries no message — silence is the right output', () {
      final result = Serviceability.fromJson(
          jsonDecode(jsonEncode(_ok())) as Map<String, dynamic>);

      expect(result.serviceable, isTrue);
      expect(result.reason, isNull);
      // A banner reading "this works" is noise on every screen it appears on.
      expect(result.message, isNull);
    });

    test('each refusal the backend can send has its own copy', () {
      const expected = {
        'OUTSIDE_SERVICE_AREA': ServiceabilityReason.outsideServiceArea,
        'NO_CAPABLE_PROVIDER': ServiceabilityReason.noCapableProvider,
        'INVALID_LOCATION': ServiceabilityReason.invalidLocation,
      };

      final messages = <String>{};
      expected.forEach((wire, reason) {
        final result = Serviceability.fromJson(
            jsonDecode(jsonEncode(_refusal(wire))) as Map<String, dynamic>);

        expect(result.serviceable, isFalse, reason: wire);
        expect(result.reason, reason, reason: wire);
        expect(result.message, isNotNull, reason: wire);
        messages.add(result.message!);
      });

      // Distinct copy per reason. Collapsing them would put "try another
      // address" in front of a customer whose problem is that nobody can do
      // the job — a loop with no exit.
      expect(messages, hasLength(3));
    });

    test('outside-area invites another address; no-provider does not', () {
      final outside = Serviceability.fromJson(
          jsonDecode(jsonEncode(_refusal('OUTSIDE_SERVICE_AREA')))
              as Map<String, dynamic>);
      final noProvider = Serviceability.fromJson(
          jsonDecode(jsonEncode(_refusal('NO_CAPABLE_PROVIDER')))
              as Map<String, dynamic>);

      expect(outside.message, contains('another saved address'));
      // The customer can do nothing about supply.
      expect(noProvider.message, isNot(contains('address')));
    });

    test('a reason this build has never heard of does not flip the verdict',
        () {
      // A newer server naming a new reason must not make a bookable service
      // unbookable.
      final stillYes = Serviceability.fromJson({
        'data': {'serviceable': true, 'reason': 'SOMETHING_NEW'},
      });
      expect(stillYes.serviceable, isTrue);
      expect(stillYes.reason, ServiceabilityReason.unknown);

      final stillNo = Serviceability.fromJson({
        'data': {'serviceable': false, 'reason': 'SOMETHING_NEW'},
      });
      expect(stillNo.serviceable, isFalse);
      expect(stillNo.message, isNotNull);
    });

    test('an absent field is never read as a yes', () {
      // The one direction this answer must not fail in.
      expect(Serviceability.fromJson(const {'data': {}}).serviceable, isFalse);
      expect(Serviceability.fromJson(const {}).serviceable, isFalse);
    });
  });

  group('the request carries the point the booking will carry', () {
    test('coordinates are sent at six decimals, matching the location id',
        () async {
      final backend = _Backend(_ok);
      await registerScreenDependencies(client: backend.client());

      await dpLocator<CatalogRepository>()
          .serviceability(serviceId: 1, lat: 14.5547, lon: 121.0244);

      expect(backend.asked, hasLength(1));
      // §42's `loc_{lat}_{lon}` format is six decimals, so the point asked
      // about here is the point the booking will resolve against.
      expect(backend.asked.single.queryParameters['lat'], '14.554700');
      expect(backend.asked.single.queryParameters['lon'], '121.024400');
      expect(backend.asked.single.path,
          endsWith('/catalog/services/1/serviceability'));
    });
  });

  group('the store asks on address selection, not at submit', () {
    Future<BwBookingStore> arrange(_Backend backend) async {
      await registerScreenDependencies(client: backend.client());
      final store = dpLocator<BwBookingStore>();
      store.beginBranchlessBooking();
      store.selectOption(const {
        'id': 1,
        'catalogServiceId': 1,
        'level3': 'Gluta Drip',
      });
      await store.loadSavedAddresses();
      return store;
    }

    test('selecting an address produces a verdict', () async {
      final backend = _Backend(() => _refusal('OUTSIDE_SERVICE_AREA'));
      final store = await arrange(backend);

      store.selectAddress(store.savedAddresses.first);
      await Future<void>.delayed(Duration.zero);

      expect(backend.asked, hasLength(1));
      expect(store.serviceability?.serviceable, isFalse);
      expect(store.serviceability?.reason,
          ServiceabilityReason.outsideServiceArea);
    });

    test('a failed check leaves the verdict NULL, never a refusal', () async {
      // The rule that keeps this from costing bookings: if the app cannot ask,
      // it does not know. The server runs the same test at submit and refuses
      // honestly, so silence costs a wasted form at worst — a wrong
      // "unavailable" costs the booking outright.
      final backend = _Backend(() => _json({'error': 'boom'}, 500));
      final store = await arrange(backend);

      store.selectAddress(store.savedAddresses.first);
      await Future<void>.delayed(Duration.zero);

      expect(store.serviceability, isNull);
    });

    test('an address with no usable coordinates is reported, not assumed',
        () async {
      final backend = _Backend(_ok);
      await registerScreenDependencies(client: backend.client());
      final store = dpLocator<BwBookingStore>();
      store.beginBranchlessBooking();
      store.selectOption(const {'id': 1, 'catalogServiceId': 1});

      // 0,0 is Null Island, which is what an absent coordinate arrives as.
      store.selectAddress(const {'addressId': 'X', 'lat': 0, 'lon': 0});
      await Future<void>.delayed(Duration.zero);

      expect(
          store.serviceability?.reason, ServiceabilityReason.invalidLocation);
      // And it did not waste a round trip to learn that.
      expect(backend.asked, isEmpty);
    });

    test('a legacy option with no canonical id is not guessed at', () async {
      // `id` on a legacy option map is a `service_options.id`. It equals the
      // canonical id for every promoted row today and stops doing so for the
      // first Service created through the Admin API — so asking with it would
      // be right until it silently was not.
      final backend = _Backend(_ok);
      await registerScreenDependencies(client: backend.client());
      final store = dpLocator<BwBookingStore>();
      store.beginBranchlessBooking();
      store.selectOption(const {'id': 19, 'level3': 'Body Massage'});

      store.selectAddress(const {'addressId': 'X', 'lat': 14.5, 'lon': 121.0});
      await Future<void>.delayed(Duration.zero);

      expect(backend.asked, isEmpty);
      expect(store.serviceability, isNull);
    });

    test('a stale verdict does not linger over a new address', () async {
      final backend = _Backend(() => _refusal('OUTSIDE_SERVICE_AREA'));
      final store = await arrange(backend);

      store.selectAddress(store.savedAddresses.first);
      await Future<void>.delayed(Duration.zero);
      expect(store.serviceability, isNotNull);

      // Selecting again must clear before it re-asks, or the previous
      // address's refusal sits over the new one for a whole round trip.
      store.selectAddress(const {'addressId': 'Y', 'lat': 0, 'lon': 0});
      expect(
          store.serviceability?.reason, ServiceabilityReason.invalidLocation);
    });
  });
}
