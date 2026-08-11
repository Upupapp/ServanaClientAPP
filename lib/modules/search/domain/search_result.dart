import 'package:client/common/presentation/widgets/service_thumbnail.dart';

/// One canonical Service surfaced in search results.
///
/// [serviceId] is `services.id` — the canonical bookable entity, the same
/// integer the Subcategory list, Service Detail, the booking payload and
/// provider capability all use. Tapping a result routes on this id and never
/// reconstructs identity from a name (§35).
///
/// ## What changed, and why the granularity moved
///
/// This used to represent one level-2 GROUP (`Aircon 2` + `Cleaning`), keyed on
/// the legacy family id, with the group label as the card title. So a search
/// for "pimple" matched the group "Facial" and the customer then had to pick
/// the treatment on the next screen — the result was never the thing they
/// searched for.
///
/// It is now one Service. "Pimple Facial" is a result in its own right and
/// resolves straight to its own detail page.
///
/// Two consequences worth knowing:
///  - result counts go up (95 Services vs 13 groups)
///  - `Electrical Services` becomes searchable at all. The old index dropped
///    any family the hardcoded `categoryIdFromService` map did not recognise,
///    which silently excluded it.
class SearchResult {
  const SearchResult({
    required this.serviceId,
    required this.serviceName,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.categoryId,
    required this.categoryName,
    required this.minPricePesos,
    required this.maxPricePesos,
    required this.bookable,
  });

  /// Canonical `services.id`.
  final int serviceId;
  final String serviceName;

  final int subcategoryId;
  final String subcategoryName;

  /// Canonical `catalog_categories.id`. An int, not an app-side enum — the
  /// filter chips are built from whatever the backend actually returns, so a
  /// Category an admin adds tomorrow is filterable without an app release.
  final int categoryId;
  final String categoryName;

  final int minPricePesos;
  final int maxPricePesos;
  final bool bookable;

  /// The canonical catalog carries no imagery for any Service, so art still
  /// comes from the app's keyword map — now keyed on the Service name rather
  /// than the group label, which is more specific and therefore matches better.
  String get imageAsset => serviceImageAsset(serviceName);

  /// Stable list key. Canonical id alone is sufficient and unique; the old form
  /// concatenated a family id with a level-2 label.
  String get stableId => 'svc_$serviceId';

  /// `Personal Care › Facial` — the hierarchy context §30 requires beside every
  /// result, resolved from the Subcategory entity and never from a `level2`
  /// field.
  String get hierarchyPath => '$categoryName › $subcategoryName';

  String get priceDisplay {
    if (minPricePesos <= 0) return 'Get a quote';
    if (minPricePesos == maxPricePesos) return '₱$minPricePesos';
    return 'From ₱$minPricePesos';
  }

  /// Everything a free-text query is matched against. Includes the hierarchy so
  /// searching "beauty" surfaces the Services under Personal Care, and "facial"
  /// surfaces every Service in the Facial Subcategory (§31, §32).
  String get searchHaystack =>
      '$serviceName $subcategoryName $categoryName'.toLowerCase();
}

/// A category filter chip, derived from the loaded catalog rather than declared
/// in the binary.
class SearchCategoryChip {
  const SearchCategoryChip({required this.id, required this.label});

  /// Canonical `catalog_categories.id`.
  final int id;
  final String label;
}
