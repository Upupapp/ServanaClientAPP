import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/search/data/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _CatalogApi extends ServanaApiClient {
  _CatalogApi(this.response) : super(baseUrl: 'http://fake.test');

  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> listFullCatalog() async => response;
}

void main() {
  test('catalog view accepts compatible IDs and skips malformed rows',
      () async {
    final repository = SearchRepository(
      api: _CatalogApi({
        'services': [
          null,
          'invalid service',
          {
            'service_id': '1',
            'name': 'Aircon Services',
            'category': 'HOME_SERVICE',
            'options': [
              null,
              {
                'level_2': 'Cleaning',
                'items': [
                  'invalid item',
                  {'base_price': '750.00'},
                ],
              },
            ],
          },
        ],
      }),
    );

    final results = await repository.fetchCatalog();

    expect(results, hasLength(1));
    expect(results.single.serviceId, 1);
    expect(results.single.level2, 'Cleaning');
    expect(results.single.priceDisplay, '₱750');
  });
}
