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
  static String routeNameFor(BookingFlowType flowType) =>
      switch (flowType) {
        BookingFlowType.bwAddOns => 'BwAddOns',
        BookingFlowType.airconOptions => 'AirconOptions',
        BookingFlowType.generic => 'BwAddOns',
      };

  static String routeNameForCategory(ServiceCategoryId categoryId) =>
      routeNameFor(resolve(categoryId));

  static Map<String, dynamic>? extraFor({
    required BookingFlowType flowType,
    required ServiceOptionSummary option,
    required CategoryPresentationConfig config,
  }) {
    return switch (flowType) {
      BookingFlowType.bwAddOns => {
          'option': option.rawData,
          'serviceId': config.serviceId,
        },
      BookingFlowType.airconOptions => {
          'option': option.rawData,
          'serviceId': config.serviceId,
        },
      BookingFlowType.generic => null,
    };
  }
}
