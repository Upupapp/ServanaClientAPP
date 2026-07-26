import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/presentation/widgets/service_thumbnail.dart';

/// A single bookable service option surfaced in search results.
///
/// Corresponds to one level-2 service group from the backend catalog
/// (e.g. "Aircon Cleaning" or "Swedish Massage"), not a level-3 sub-variant.
/// This keeps search cards consistent with the Category Experience cards.
class SearchResult {
  const SearchResult({
    required this.serviceId,
    required this.serviceName,
    required this.level2,
    required this.minPricePesos,
    required this.maxPricePesos,
    required this.requiresBranch,
    required this.categoryId,
    required this.categoryLabel,
  });

  final int serviceId;
  final String serviceName;
  final String level2;
  final int minPricePesos;
  final int maxPricePesos;
  final bool requiresBranch;
  final ServiceCategoryId categoryId;
  final String categoryLabel;

  String get imageAsset => serviceImageAsset(level2);

  String get stableId => '${serviceId}_$level2';

  String get priceDisplay {
    if (minPricePesos <= 0) return 'Get a quote';
    if (minPricePesos == maxPricePesos) return '₱$minPricePesos';
    return 'From ₱$minPricePesos';
  }
}

/// Maps a top-level service's [name] (and optionally [serviceId]) to a
/// [ServiceCategoryId] for routing. Uses name-matching as a robust fallback
/// since serviceIds may change as the catalog grows.
ServiceCategoryId? categoryIdFromService({
  required int serviceId,
  required String name,
}) {
  // Primary: explicit ID mapping (must be updated if the catalog changes).
  switch (serviceId) {
    case 1:
      return ServiceCategoryId.aircon;
    case 2:
      return ServiceCategoryId.beautyWellness;
    case 3:
      return ServiceCategoryId.hairAndNails;
    case 4:
      return ServiceCategoryId.massage;
  }
  // Fallback: name matching.
  final n = name.toLowerCase();
  if (n.contains('aircon') || n.contains('air con')) {
    return ServiceCategoryId.aircon;
  }
  if (n.contains('massage') || n.contains('spa')) {
    return ServiceCategoryId.massage;
  }
  if (n.contains('hair') || n.contains('nail')) {
    return ServiceCategoryId.hairAndNails;
  }
  if (n.contains('beauty') || n.contains('wellness') || n.contains('facial') ||
      n.contains('wax') || n.contains('lash')) {
    return ServiceCategoryId.beautyWellness;
  }
  return null;
}

/// Returns the human-readable chip label for a [ServiceCategoryId].
String categoryLabel(ServiceCategoryId id) => switch (id) {
      ServiceCategoryId.aircon => 'Aircon',
      ServiceCategoryId.beautyWellness => 'Beauty & Wellness',
      ServiceCategoryId.hairAndNails => 'Hair & Nails',
      ServiceCategoryId.massage => 'Massage',
      ServiceCategoryId.generic => 'Services',
    };
