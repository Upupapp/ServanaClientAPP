import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/modules/categories/domain/category_experience.dart';

/// Which booking sub-flow to enter after the user taps a service option.
enum BookingFlowType {
  /// Beauty, hair, or massage: tapping an option navigates to BwAddOnsScreen.
  bwAddOns,

  /// Aircon: tapping an option navigates to AirconOptionsScreen.
  airconOptions,

  /// Fallback for future categories.
  generic,
}

abstract final class ServiceBookingEntryResolver {
  static BookingFlowType resolve(ServiceCategoryId categoryId) =>
      switch (categoryId) {
        ServiceCategoryId.beautyWellness => BookingFlowType.bwAddOns,
        ServiceCategoryId.hairAndNails => BookingFlowType.bwAddOns,
        ServiceCategoryId.massage => BookingFlowType.bwAddOns,
        ServiceCategoryId.aircon => BookingFlowType.airconOptions,
        ServiceCategoryId.generic => BookingFlowType.generic,
      };

  /// Route name to push for [flowType].
  static String routeNameFor(BookingFlowType flowType) => switch (flowType) {
        BookingFlowType.bwAddOns => 'BwAddOns',
        BookingFlowType.airconOptions => 'AirconOptions',
        BookingFlowType.generic => 'BwAddOns',
      };

  static String routeNameForCategory(ServiceCategoryId categoryId) =>
      routeNameFor(resolve(categoryId));

  /// Navigation payload for a booking entry point.
  ///
  /// Three keys, and the distinction between them is the point:
  ///
  ///  - `serviceId` — the FAMILY id the legacy booking flow is keyed on
  ///    (aircon, beauty & wellness). It selects which flow to run, not what is
  ///    being booked.
  ///  - `canonicalServiceId` — the specific bookable `services.id`, present
  ///    only when the payload carried one. This is the Catalog V2 identity.
  ///  - `option` — the legacy option map the booking stores already parse.
  ///    A compatibility payload, passed through untouched.
  ///
  /// `canonicalServiceId` is omitted rather than guessed when unknown. The
  /// legacy options route does not carry it, and deriving it from the option
  /// id would be correct only until the first Service created through the
  /// catalog API — the backend resolves that mapping itself via
  /// `services.legacy_service_option_id`, so an absent key is handled and a
  /// wrong one would not be.
  static Map<String, dynamic>? extraFor({
    required BookingFlowType flowType,
    required ServiceOptionSummary option,
    required CategoryPresentationConfig config,
  }) {
    final payload = <String, dynamic>{
      'option': option.rawData,
      'serviceId': config.serviceId,
      if (option.canonicalServiceId != null)
        'canonicalServiceId': option.canonicalServiceId,
    };
    return switch (flowType) {
      BookingFlowType.bwAddOns => payload,
      BookingFlowType.airconOptions => payload,
      BookingFlowType.generic => null,
    };
  }
}
