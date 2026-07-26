import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/categories/data/category_experience_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _mainOption(String id, String level2) => {
      'id': id,
      'name': 'Option $id',
      'level2': level2,
      'basePrice': 100.0,
    };

Map<String, dynamic> _addonOption(String id) => {
      'id': id,
      'name': 'Add-on $id',
      'optionType': 'ADD_ON',
      'basePrice': 50.0,
    };

class _FakeApiClient extends ServanaApiClient {
  final Map<String, dynamic> _response;
  _FakeApiClient(this._response) : super(baseUrl: 'http://fake.test');

  @override
  Future<Map<String, dynamic>> listOptionsWithAddons(
      {required int serviceId}) async {
    return _response;
  }
}

void main() {
  group('CategoryExperienceRepository.loadOptions()', () {
    test('H6: level2AllowList filters to matching options only', () async {
      final raw = {
        'data': [
          _mainOption('1', 'drip'),
          _mainOption('2', 'facial'),
          _mainOption('3', 'nail'),
        ],
      };
      final repo = CategoryExperienceRepository(_FakeApiClient(raw));

      final results = await repo.loadOptions(
        serviceId: 2,
        level2AllowList: {'drip', 'facial'},
      );

      expect(results.length, 2);
      expect(results.map((o) => o.categoryKey).toSet(),
          equals({'drip', 'facial'}));
    });

    test('H7: level2Pattern filters to regex-matching options only', () async {
      final raw = {
        'data': [
          _mainOption('1', 'hair'),
          _mainOption('2', 'nail'),
          _mainOption('3', 'facial'),
          _mainOption('4', 'manicure'),
        ],
      };
      final repo = CategoryExperienceRepository(_FakeApiClient(raw));

      final results = await repo.loadOptions(
        serviceId: 2,
        level2Pattern: r'hair|nail|manicure',
      );

      expect(results.length, 3);
      expect(results.map((o) => o.categoryKey).toSet(),
          equals({'hair', 'nail', 'manicure'}));
    });

    test('add-ons are excluded regardless of filter', () async {
      final raw = {
        'data': [
          _mainOption('1', 'drip'),
          _addonOption('99'),
        ],
      };
      final repo = CategoryExperienceRepository(_FakeApiClient(raw));

      final results = await repo.loadOptions(serviceId: 2);

      expect(results.length, 1);
      expect(results.first.id, '1');
    });

    test('options with empty level2 pass all filters (include-no-tag rule)',
        () async {
      final raw = {
        'data': [
          {'id': '1', 'name': 'Unlabeled', 'basePrice': 100.0},
          _mainOption('2', 'drip'),
        ],
      };
      final repo = CategoryExperienceRepository(_FakeApiClient(raw));

      final results = await repo.loadOptions(
        serviceId: 2,
        level2AllowList: {'facial'},
      );

      // The unlabeled option has no level2 → passes include-no-tag rule.
      // 'drip' is not in allowList → excluded.
      expect(results.length, 1);
      expect(results.first.id, '1');
    });

    test('calls api with the correct serviceId', () async {
      int? capturedId;
      final client = _CountingApiClient(
          captureId: (id) => capturedId = id, response: {'data': []});
      final repo = CategoryExperienceRepository(client);

      await repo.loadOptions(serviceId: 7);

      expect(capturedId, 7);
    });
  });
}

class _CountingApiClient extends ServanaApiClient {
  final void Function(int) captureId;
  final Map<String, dynamic> response;

  _CountingApiClient({required this.captureId, required this.response})
      : super(baseUrl: 'http://fake.test');

  @override
  Future<Map<String, dynamic>> listOptionsWithAddons(
      {required int serviceId}) async {
    captureId(serviceId);
    return response;
  }
}
