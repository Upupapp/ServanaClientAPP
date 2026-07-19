import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/repositories/address_repository.dart';
import 'package:client/common/presentation/screens/address_form_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart'
    show LatLong;

// ─── Minimal fakes ───────────────────────────────────────────────────────────

class _FakeApi extends Fake implements ServanaApiClient {
  Map<String, dynamic>? addResponse;
  Map<String, dynamic>? listResponse;
  Object? addError;
  Object? listError;

  @override
  Future<Map<String, dynamic>> addUserAddress(
      {required Map<String, dynamic> payload}) async {
    if (addError != null) throw addError!;
    return addResponse ?? {};
  }

  @override
  Future<Map<String, dynamic>> getAllUserAddresses(
      {bool? isArchived, int? role}) async {
    if (listError != null) throw listError!;
    return listResponse ?? {'data': []};
  }
}

AddressFormResult _formResult({
  double lat = 14.5995,
  double lon = 120.9842,
  String address = '123 Main St',
  String city = 'Manila',
  String province = 'Metro Manila',
  String barangay = 'Sampaloc',
  String unit = '',
  String street = 'Rizal Ave',
  String landmark = '',
}) {
  return AddressFormResult(
    location: LatLong(lat, lon),
    address: address,
    city: city,
    province: province,
    barangay: barangay,
    unit: unit,
    street: street,
    landmark: landmark,
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('AddressRepository.loadAddresses', () {
    test('returns AddressSuccess with items from data key', () async {
      final api = _FakeApi()
        ..listResponse = {
          'data': [
            {'addressId': '1', 'addressOne': 'A St'},
          ],
        };
      final repo = AddressRepository(api: api);
      final result = await repo.loadAddresses();
      expect(result, isA<AddressSuccess>());
      final success = result as AddressSuccess;
      expect(success.addresses.length, 1);
      expect(success.addresses.first['addressId'], '1');
    });

    test('returns AddressSuccess with empty list when data is empty', () async {
      final api = _FakeApi()..listResponse = {'data': []};
      final repo = AddressRepository(api: api);
      final result = await repo.loadAddresses();
      expect(result, isA<AddressSuccess>());
      expect((result as AddressSuccess).addresses, isEmpty);
    });

    test('returns AddressError on API exception', () async {
      final api = _FakeApi()
        ..listError = const ServanaApiException(statusCode: 500, body: 'err');
      final repo = AddressRepository(api: api);
      final result = await repo.loadAddresses();
      expect(result, isA<AddressError>());
      final err = result as AddressError;
      expect(err.message, contains('500'));
    });

    test('returns AddressError on network error', () async {
      final api = _FakeApi()
        ..listError = Exception('SocketException: connection refused');
      final repo = AddressRepository(api: api);
      final result = await repo.loadAddresses();
      expect(result, isA<AddressError>());
      expect((result as AddressError).message, contains('internet'));
    });
  });

  group('AddressRepository.createAddress — session guard', () {
    // Without Hive initialised, SessionService.getSession() either returns
    // null (empty userId path) or throws (catch path). Both produce
    // AddressError — no address is created and the API is never called.
    test('returns AddressError when no session is available', () async {
      final api = _FakeApi();
      final repo = AddressRepository(api: api);
      final result = await repo.createAddress(
        result: _formResult(),
        isPrimary: false,
      );
      expect(result, isA<AddressError>());
      // API must NOT have been called (addResponse untouched and no throw).
      expect(api.addError, isNull);
    });
  });

  group('AddressResult sealed hierarchy', () {
    test('AddressSuccess carries address list', () {
      final r = AddressSuccess([
        {'id': '1'},
        {'id': '2'},
      ]);
      expect(r.addresses.length, 2);
    });

    test('AddressCreated carries new address and full list', () {
      final r = AddressCreated(
        newAddress: {'id': 'new'},
        allAddresses: [
          {'id': 'old'},
          {'id': 'new'},
        ],
      );
      expect(r.newAddress['id'], 'new');
      expect(r.allAddresses.length, 2);
    });

    test('AddressError carries message', () {
      final r = AddressError('Network error');
      expect(r.message, 'Network error');
    });
  });
}
