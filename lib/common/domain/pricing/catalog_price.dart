/// One definition of "what does this catalog row cost".
///
/// There were two, and they disagreed:
///
///   * `search_repository.dart:34` read only `base_price`, cast it `as num?`,
///     and defaulted to 0. A price arriving as a string, or under the camelCase
///     spelling, became 0 — which `SearchResult.priceDisplay` renders as
///     "Get a quote" on a service that has a perfectly good price.
///   * `category_experience.dart:_extractPrice` tried `basePrice`, `base_price`,
///     `price` and `amount`, and parsed strings.
///
/// So the same option could show a price on one screen and "Get a quote" on
/// another. The two endpoints feeding them genuinely differ in spelling —
/// `/services/full` writes `base_price` explicitly while `/options-with-addons`
/// ships `basePrice` from `toCamel` — which is exactly why neither reader
/// should be hardcoding one spelling.
///
/// Formatting stays with the caller: a category card shows a single price and a
/// search row shows a range. Those are legitimately different presentations of
/// the same number. It is the *extraction* that must not diverge.
library;

/// Pesos for a catalog row, or null when the row genuinely carries no price.
///
/// Null and 0 mean different things. Null is "no price on this row, ask for a
/// quote"; 0 is a real, free item. Collapsing them is what made a priced
/// service read as "Get a quote".
double? extractCatalogPricePesos(Map<String, dynamic> row) {
  // Both spellings, because the two catalog endpoints disagree. parityMiddleware
  // aliases them server-side, but only when the value was populated — so a
  // reader that assumes one spelling breaks the moment it is fed the other.
  const keys = ['basePrice', 'base_price', 'price', 'amount'];

  for (final key in keys) {
    final v = row[key];
    if (v == null) continue;
    if (v is num) return v.toDouble();
    if (v is String) {
      // Backend numerics can arrive as strings from pg; strip currency and
      // separators rather than returning null and showing "Get a quote".
      final cleaned = v.replaceAll(RegExp(r'[^0-9.\-]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

/// Pesos as a whole number, for callers that work in ints.
///
/// Returns null rather than 0 when there is no price, so the caller can tell
/// "free" apart from "unpriced" — the distinction the old `?? 0` destroyed.
int? extractCatalogPricePesosInt(Map<String, dynamic> row) =>
    extractCatalogPricePesos(row)?.round();
