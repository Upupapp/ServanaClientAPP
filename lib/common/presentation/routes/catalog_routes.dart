/// Route names and paths for the canonical Catalog V2 browse flow.
///
/// Every catalog route is keyed on a canonical backend id — `catalog_categories.id`,
/// `catalog_subcategories.id`, `services.id`. Never a slug, never a name, and
/// never a legacy `service_options` id.
///
/// That matters most for [service]. A Service that Admin moves to a different
/// Subcategory keeps its `services.id`, so a saved link, a favourite and a
/// notification all keep resolving across the move (§55). A slug would not: a
/// rename rewrites it.
///
/// These strings are a public contract — deep links and notification payloads
/// carry them. Renaming one breaks links already in the field.
abstract final class CatalogRoutes {
  // ── Names (targets for goNamed / pushNamed) ────────────────────────────────
  static const String browse = 'CatalogBrowse';
  static const String category = 'CatalogCategory';
  static const String subcategory = 'CatalogSubcategory';
  static const String service = 'CatalogService';

  // ── Paths, relative to the shell branch that hosts them ────────────────────
  static const String browsePath = 'catalog';
  static const String categoryPath = 'catalog/category/:categoryId';
  static const String subcategoryPath = 'catalog/subcategory/:subcategoryId';

  /// `/service/:serviceId` — deliberately short and stable. This is the link
  /// shared, saved and pushed most often.
  static const String servicePath = 'service/:serviceId';

  /// Parses a path parameter into a canonical id.
  ///
  /// Returns null rather than throwing on anything that is not a positive
  /// integer, so a malformed deep link becomes a safe "unavailable" screen
  /// instead of a crash on cold start.
  static int? parseId(String? raw) {
    if (raw == null) return null;
    final value = int.tryParse(raw.trim());
    if (value == null || value <= 0) return null;
    return value;
  }
}
