import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/modules/categories/domain/service_booking_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceBookingEntryResolver.resolve', () {
    test('beautyWellness → bwAddOns', () {
      expect(
        ServiceBookingEntryResolver.resolve(ServiceCategoryId.beautyWellness),
        BookingFlowType.bwAddOns,
      );
    });

    test('hairAndNails → bwAddOns', () {
      expect(
        ServiceBookingEntryResolver.resolve(ServiceCategoryId.hairAndNails),
        BookingFlowType.bwAddOns,
      );
    });

    test('massage → bwAddOns', () {
      expect(
        ServiceBookingEntryResolver.resolve(ServiceCategoryId.massage),
        BookingFlowType.bwAddOns,
      );
    });

    test('aircon → airconOptions', () {
      expect(
        ServiceBookingEntryResolver.resolve(ServiceCategoryId.aircon),
        BookingFlowType.airconOptions,
      );
    });

    test('generic → generic', () {
      expect(
        ServiceBookingEntryResolver.resolve(ServiceCategoryId.generic),
        BookingFlowType.generic,
      );
    });
  });

  group('ServiceBookingEntryResolver.routeNameFor', () {
    test('bwAddOns → BwAddOns', () {
      expect(
        ServiceBookingEntryResolver.routeNameFor(BookingFlowType.bwAddOns),
        'BwAddOns',
      );
    });

    test('airconOptions → AirconOptions', () {
      expect(
        ServiceBookingEntryResolver.routeNameFor(
            BookingFlowType.airconOptions),
        'AirconOptions',
      );
    });
  });

  group('ServiceBookingEntryResolver.routeNameForCategory', () {
    test('aircon maps to AirconOptions route', () {
      expect(
        ServiceBookingEntryResolver.routeNameForCategory(
            ServiceCategoryId.aircon),
        'AirconOptions',
      );
    });

    test('massage maps to BwAddOns route', () {
      expect(
        ServiceBookingEntryResolver.routeNameForCategory(
            ServiceCategoryId.massage),
        'BwAddOns',
      );
    });
  });
}
