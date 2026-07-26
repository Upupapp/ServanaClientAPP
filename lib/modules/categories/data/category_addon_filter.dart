/// Centralised add-on detection.
///
/// Fixes divergence between bw_options_screen (checked optionType only) and
/// bw_booking_store / aircon_booking_store (triple check).  Every call-site
/// now delegates here so the contract is maintained in one place.
abstract final class CategoryAddonFilter {
  /// Returns true when [option] is an add-on and must be excluded from the
  /// primary options list.
  static bool isAddon(Map<String, dynamic> option) =>
      option['optionType'] == 'ADD_ON' ||
      option['isAddon'] == true ||
      option['is_addon'] == true;

  /// Inverse of [isAddon] — use in `where` clauses.
  static bool isNotAddon(Map<String, dynamic> option) => !isAddon(option);
}
