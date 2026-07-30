import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/repositories/address_repository.dart';
import 'package:client/modules/profile/application/address_controller.dart';
import 'package:client/modules/profile/domain/customer_address.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _Repo extends Fake implements AddressRepository {
  List<Map<String, dynamic>> _data = [];
  Object? _error;

  void willReturn(List<Map<String, dynamic>> list) {
    _data = list;
    _error = null;
  }

  void willThrow(Object e) => _error = e;

  @override
  Future<AddressResult> loadAddresses() async {
    if (_error != null) throw _error!;
    return AddressSuccess(_data);
  }
}

class _Api extends Fake implements ServanaApiClient {
  bool primaryThrows = false;
  bool deleteThrows = false;
  String? lastPrimaryId;
  String? lastDeleteId;

  @override
  Future<Map<String, dynamic>> makeAddressPrimary({
    required String addressId,
  }) async {
    lastPrimaryId = addressId;
    if (primaryThrows) throw Exception('primary failed');
    return {'status': 'success'};
  }

  @override
  Future<Map<String, dynamic>> deleteAddress({
    required String addressId,
  }) async {
    lastDeleteId = addressId;
    if (deleteThrows) throw Exception('delete failed');
    return {'status': 'success'};
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Map<String, dynamic> _addr(String id,
        {bool isPrimary = false, String label = 'Home'}) =>
    {
      'addressId': id,
      'userId': 'u1',
      'addressOne': '123 Test Street',
      'addressTwo': 'Unit A',
      'postTown': 'Makati',
      'country': 'Philippines',
      'label': label,
      'isPrimary': isPrimary,
      'lat': 14.5995,
      'lon': 120.9842,
    };

AddressController _makeCtrl({_Repo? repo, _Api? api}) => AddressController(
      repository: repo ?? _Repo(),
      api: api ?? _Api(),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AddressController.loadAddresses()', () {
    test('populates addresses from repository', () async {
      final repo = _Repo()..willReturn([_addr('a1'), _addr('a2')]);
      final ctrl = _makeCtrl(repo: repo);

      await ctrl.loadAddresses();

      expect(ctrl.addresses.length, 2);
      expect(ctrl.addresses.first.addressId, 'a1');
      expect(ctrl.isLoading, isFalse);
      expect(ctrl.error, isNull);
    });

    test('sets error on exception', () async {
      final repo = _Repo()..willThrow(Exception('network'));
      final ctrl = _makeCtrl(repo: repo);

      await ctrl.loadAddresses();

      expect(ctrl.addresses, isEmpty);
      expect(ctrl.error, isNotNull);
    });

    test('notifyListeners() is called after load', () async {
      final repo = _Repo()..willReturn([_addr('a1')]);
      final ctrl = _makeCtrl(repo: repo);
      var notified = false;
      ctrl.addListener(() => notified = true);

      await ctrl.loadAddresses();

      expect(notified, isTrue);
    });

    test('concurrent calls do not double-load', () async {
      final repo = _Repo()..willReturn([_addr('a1')]);
      final ctrl = _makeCtrl(repo: repo);

      await Future.wait([ctrl.loadAddresses(), ctrl.loadAddresses()]);

      expect(ctrl.addresses.length, 1);
    });
  });

  group('AddressController.setPrimaryAddress()', () {
    test('sets matching address as primary optimistically', () async {
      final repo = _Repo()
        ..willReturn([_addr('a1'), _addr('a2', isPrimary: true)]);
      final api = _Api();
      final ctrl = _makeCtrl(repo: repo, api: api);
      await ctrl.loadAddresses();

      final ok = await ctrl.setPrimaryAddress('a1');

      expect(ok, isTrue);
      expect(ctrl.addresses.firstWhere((a) => a.addressId == 'a1').isPrimary,
          isTrue);
      expect(ctrl.addresses.firstWhere((a) => a.addressId == 'a2').isPrimary,
          isFalse);
      expect(api.lastPrimaryId, 'a1');
    });

    test('returns false and exposes error on API failure', () async {
      final repo = _Repo()..willReturn([_addr('a1')]);
      final api = _Api()..primaryThrows = true;
      final ctrl = _makeCtrl(repo: repo, api: api);
      await ctrl.loadAddresses();

      final ok = await ctrl.setPrimaryAddress('a1');

      expect(ok, isFalse);
      expect(ctrl.isMutating, isFalse);
      expect(ctrl.error, isNotNull);
    });

    test('primaryAddress getter returns the primary address', () async {
      final repo = _Repo()
        ..willReturn([_addr('a1'), _addr('a2', isPrimary: true)]);
      final ctrl = _makeCtrl(repo: repo);
      await ctrl.loadAddresses();

      expect(ctrl.primaryAddress?.addressId, 'a2');
    });
  });

  group('AddressController.deleteAddress()', () {
    test('removes address from list on success', () async {
      final repo = _Repo()..willReturn([_addr('a1'), _addr('a2')]);
      final ctrl = _makeCtrl(repo: repo);
      await ctrl.loadAddresses();
      expect(ctrl.addresses.length, 2);

      final ok = await ctrl.deleteAddress('a1');

      expect(ok, isTrue);
      expect(ctrl.addresses.length, 1);
      expect(ctrl.addresses.first.addressId, 'a2');
    });

    test('returns false and preserves list on API failure', () async {
      final repo = _Repo()..willReturn([_addr('a1'), _addr('a2')]);
      final api = _Api()..deleteThrows = true;
      final ctrl = _makeCtrl(repo: repo, api: api);
      await ctrl.loadAddresses();

      final ok = await ctrl.deleteAddress('a1');

      expect(ok, isFalse);
      expect(ctrl.addresses.length, 2);
      expect(ctrl.error, isNotNull);
    });
  });

  group('AddressController.resetPrivateData()', () {
    test('clears all addresses and state', () async {
      final repo = _Repo()..willReturn([_addr('a1')]);
      final ctrl = _makeCtrl(repo: repo);
      await ctrl.loadAddresses();
      expect(ctrl.addresses, isNotEmpty);

      ctrl.resetPrivateData();

      expect(ctrl.addresses, isEmpty);
      expect(ctrl.isLoading, isFalse);
      expect(ctrl.isMutating, isFalse);
      expect(ctrl.error, isNull);
    });
  });

  group('CustomerAddress helpers', () {
    final addr = CustomerAddress(
      addressId: 'a1',
      userId: 'u1',
      addressOne: '123 Rizal Avenue',
      addressTwo: 'Suite 5',
      postTown: 'Makati City',
      label: 'Office',
      isPrimary: true,
    );

    test('displayLabel returns label when present', () {
      expect(addr.displayLabel, 'Office');
    });

    test('displayLabel falls back to "Address" when label is null', () {
      final a =
          CustomerAddress(addressId: 'a', userId: 'u', addressOne: '1 Main St');
      expect(a.displayLabel, 'Address');
    });

    test('displayLine1 returns addressOne', () {
      expect(addr.displayLine1, '123 Rizal Avenue');
    });

    test('displayLine2 joins addressTwo and postTown', () {
      expect(addr.displayLine2, 'Suite 5, Makati City');
    });
  });
}
