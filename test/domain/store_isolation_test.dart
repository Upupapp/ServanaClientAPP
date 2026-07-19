import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/booking/booking_draft.dart';
import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:mocktail/mocktail.dart';

class MockServanaApiClient extends Mock implements ServanaApiClient {}

Map<String, dynamic> _option(String name) => {
      'id': 1,
      'optionType': 'SERVICE',
      'name': name,
      'basePrice': '1500',
    };

void main() {
  group('store isolation — AirconBookingStore options survive auth transition', () {
    late AirconBookingStore airconStore;

    setUp(() {
      airconStore = AirconBookingStore(api: MockServanaApiClient());
    });

    test('options are NOT cleared by BookingDraftService lifecycle', () {
      runInAction(() => airconStore.optionsWithAddons.add(_option('Aircon Clean')));
      expect(airconStore.bookableOptions, hasLength(1));

      // Simulate the full draft restore cycle that fires on AuthenticationAuthenticated
      final draftService = BookingDraftService();
      draftService.save(BookingDraft(
        id: 'draft-a',
        createdAt: DateTime.now(),
        returnRouteName: 'AirconOptionsScreen',
        flowType: BookingFlowType.aircon,
      ));
      draftService.restore();
      draftService.clear();

      expect(airconStore.bookableOptions, hasLength(1));
      expect(airconStore.bookableOptions.first['name'], equals('Aircon Clean'));
    });

    test('reset() is the only mechanism that clears bookableOptions', () {
      runInAction(() => airconStore.optionsWithAddons.add(_option('Deep Clean')));
      expect(airconStore.bookableOptions, hasLength(1));

      // Verify the one path that IS expected to clear options
      airconStore.reset();
      expect(airconStore.bookableOptions, isEmpty);
    });

    test('options from multiple categories survive draft clear independently', () {
      runInAction(() {
        airconStore.optionsWithAddons
          ..add(_option('Window Type'))
          ..add(_option('Split Type'));
      });
      expect(airconStore.bookableOptions, hasLength(2));

      BookingDraftService().clear(); // No-op on a fresh service — must not affect store

      expect(airconStore.bookableOptions, hasLength(2));
    });
  });
}
