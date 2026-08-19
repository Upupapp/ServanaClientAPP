/// The wifi-off icon is a claim about the customer's network. It must only
/// appear when that claim is true.
///
/// `SearchController.errorIsConnectivity` drives the icon on the search error
/// view — `wifi_off_outlined` when true, `error_outline_rounded` when false.
/// It was computed as `failure is RetryableFailure`, and RetryableFailure
/// covers BOTH a 5xx and a genuine transport fault; only `isTransport`
/// separates them. So every server error drew the wifi icon.
///
/// That is the same lie the field was introduced to remove, just narrower —
/// and on 2026-08-19 it was live, because the catalog every search reads was
/// answering 500 in production.
library;

import 'package:client/core/network/api_failure.dart';
import 'package:client/modules/search/application/search_controller.dart';
import 'package:client/modules/search/data/search_repository.dart';
import 'package:client/modules/search/domain/search_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingRepository extends Fake implements SearchRepository {
  _FailingRepository(this.error);
  final Object error;

  @override
  Future<List<SearchResult>> fetchCatalog({bool forceRefresh = false}) async =>
      throw error;

  @override
  void clearCache() {}
}

Future<SearchController> _loadWith(Object error) async {
  final ctrl = SearchController(repository: _FailingRepository(error));
  await ctrl.init();
  return ctrl;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('a server fault must not accuse the network', () {
    test('a 5xx is retryable but is NOT connectivity', () async {
      // isTransport defaults to false: the server answered, it just failed.
      final ctrl = await _loadWith(
        const RetryableFailure(safeMessage: 'Server error'),
      );

      expect(ctrl.state, SearchLoadState.error);
      expect(ctrl.errorIsConnectivity, isFalse,
          reason: 'a 500 draws error_outline, never wifi_off');
    });

    test('a 401 is not connectivity either', () async {
      final ctrl = await _loadWith(
        const AuthFailure(safeMessage: 'Authentication is required'),
      );

      expect(ctrl.errorIsConnectivity, isFalse);
    });

    test('an unclassified exception does not claim the network', () async {
      // It escaped without being turned into an ApiFailure, so we do not know
      // what it was. Guessing "network" accuses a working connection.
      final ctrl = await _loadWith(Exception('something unexpected'));

      expect(ctrl.errorIsConnectivity, isFalse);
    });

    test('an unclassified exception does not put its toString on screen',
        () async {
      final ctrl = await _loadWith(Exception('PathNotFoundException: /tmp/x'));

      expect(ctrl.error, isNotNull);
      expect(ctrl.error, isNot(contains('PathNotFoundException')));
      expect(ctrl.error, isNot(contains('Exception')));
    });
  });

  group('a real transport failure still is connectivity', () {
    test('isTransport true means the request never reached the server',
        () async {
      final ctrl = await _loadWith(
        const RetryableFailure(
          safeMessage: 'No connection.',
          isTransport: true,
        ),
      );

      expect(ctrl.errorIsConnectivity, isTrue,
          reason: 'this is the one case where wifi_off is honest');
    });
  });

  group('the failure message shown is the one written for it', () {
    test('an ApiFailure renders its own safeMessage', () async {
      final ctrl = await _loadWith(
        const AuthFailure(safeMessage: 'Authentication is required'),
      );

      expect(ctrl.error, equals('Authentication is required'));
    });
  });
}
