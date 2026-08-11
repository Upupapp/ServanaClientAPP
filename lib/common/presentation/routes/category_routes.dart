import 'package:client/common/domain/services/service_category_config.dart';

/// Route names for the four category entry points.
///
/// These strings are a PUBLIC CONTRACT, not an implementation detail: they are
/// live `pushNamed` targets and appear in deep links and notification payloads.
/// They were previously static constants on four screen widgets
/// (`AirconRepairScreen`, `BeautyWellnessScreen`, `HairNailsScreen`,
/// `MassageScreen`) whose `build()` methods the router never called — every one
/// of those routes builds [CategoryExperienceScreen] instead. Deleting the dead
/// widgets would have taken the live route names with them, so they live here.
///
/// The values are unchanged. Renaming any of them breaks existing deep links.
abstract final class CategoryRoutes {
  static const String aircon = 'AirconRepair';
  static const String beautyWellness = 'BeautyWellness';
  static const String hairNails = 'HairNails';
  static const String massage = 'Massage';

  /// Route name for [id], for callers that hold a category rather than a name.
  static String forCategory(ServiceCategoryId id) => switch (id) {
        ServiceCategoryId.aircon => aircon,
        ServiceCategoryId.beautyWellness => beautyWellness,
        ServiceCategoryId.hairAndNails => hairNails,
        ServiceCategoryId.massage => massage,
        ServiceCategoryId.generic => beautyWellness,
      };
}
