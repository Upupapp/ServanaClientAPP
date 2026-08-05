/// One place that decides how a saved address is written out on screen.
///
/// Seven screens each built their own `'$addressOne, $postTown'`, and every one
/// of them assumed `addressOne` held street-level detail only. It did not:
/// `_composeAddressLine` in the address form appended the city to it, from the
/// same `locality` that also populated the city field. So both halves carried
/// the city and all seven screens printed it twice — a customer in Taguig with
/// no street data saw "Taguig, Taguig", one in Manila saw
/// "15, Del Pilar, Manila, Manila".
///
/// The form no longer writes the city into `addressOne`, but rows saved by
/// 1.0.0+36 and earlier still have it, and nothing rewrites them. So the join
/// has to tolerate a trailing city rather than assume it was never there.
library;

/// Joins the street-level line and the city, dropping the city when the line
/// already ends with it.
///
/// Comparison is case-insensitive and ignores surrounding whitespace, because
/// the two values reach the database from different fields and different
/// geocoder responses — "Makati City" and "makati city" are the same place, and
/// a customer who typed one while the geocoder supplied the other should not
/// see both.
///
/// Only a trailing match is removed. A city name that legitimately appears
/// mid-line — "12 Manila Street, Quezon City" — is left alone, because there
/// the word is part of the street name and deleting it would corrupt a correct
/// address to tidy up an incorrect one.
String formatAddressLine(String? addressOne, String? postTown) {
  final line = (addressOne ?? '').trim();
  final city = (postTown ?? '').trim();

  if (line.isEmpty) return city;
  if (city.isEmpty) return line;

  // Split on commas so the check is against a whole trailing component. A
  // substring test would match "Manila" inside "Manila Street" and silently
  // truncate a real address.
  final parts = line.split(',').map((s) => s.trim()).toList();
  if (parts.isNotEmpty && parts.last.toLowerCase() == city.toLowerCase()) {
    final withoutCity = parts.sublist(0, parts.length - 1).join(', ');
    // "Taguig" with postTown "Taguig" collapses to nothing but the city.
    return withoutCity.isEmpty ? city : '$withoutCity, $city';
  }

  return '$line, $city';
}

/// Whether a stored row still carries the city inside its street line.
///
/// Not used to render anything — it exists so a backfill, or a diagnostic, can
/// identify affected rows by the same rule the display uses, instead of a
/// second definition that drifts from this one.
bool addressLineRepeatsCity(String? addressOne, String? postTown) {
  final line = (addressOne ?? '').trim();
  final city = (postTown ?? '').trim();
  if (line.isEmpty || city.isEmpty) return false;
  final parts = line.split(',').map((s) => s.trim()).toList();
  return parts.isNotEmpty && parts.last.toLowerCase() == city.toLowerCase();
}
