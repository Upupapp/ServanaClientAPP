import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/domain/services/service_option_display.dart';
import 'package:client/common/presentation/widgets/service_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:client/common/domain/pricing/catalog_price.dart';

// ── Color / visual identity tokens ────────────────────────────────────────

@immutable
class CategoryThemeToken {
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color surfaceTint;

  const CategoryThemeToken({
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.surfaceTint,
  });
}

// ── Quick-action filter chips ──────────────────────────────────────────────

@immutable
class CategoryFilterChip {
  /// Display label, e.g. 'All', 'Facial', 'Cleaning'.
  final String label;

  /// Matched against the option's `level_2` field. null → 'All' (no filter).
  final String? level2Value;

  const CategoryFilterChip({required this.label, this.level2Value});
}

// ── How it works steps ─────────────────────────────────────────────────────

@immutable
class CategoryProcessStep {
  final int ordinal;
  final String title;
  final String description;

  const CategoryProcessStep({
    required this.ordinal,
    required this.title,
    required this.description,
  });
}

// ── Typed service option (no raw Map in UI) ────────────────────────────────

@immutable
class ServiceOptionSummary {
  final String id;
  final String name;
  final String? shortDescription;
  final double? basePrice;
  final String formattedPrice;
  final String? imageAsset;

  /// Raw `level_2` value; used ONLY for chip filtering in the controller.
  ///
  /// Never rendered. `CategoryFilterChip` carries its own customer-facing
  /// [CategoryFilterChip.label] precisely so this migration-era value cannot
  /// reach a screen — see the Catalog V2 acceptance gate, "no UI labels expose
  /// Level 2/3 semantics".
  final String categoryKey;

  final bool hasAddons;

  /// Canonical `services.id`, when the payload carries one.
  ///
  /// **Null on the legacy path, and that is correct rather than a gap.** The
  /// public catalog deliberately does not expose `legacy_service_option_id`
  /// (it is a migration artefact, and surfacing it would put migration
  /// semantics in the client), so this build cannot map a legacy option id to
  /// a canonical Service id locally.
  ///
  /// The backend does that resolution itself on booking creation —
  /// `services.legacy_service_option_id` is looked up in the insert — so a
  /// payload carrying only [id] still books the right Service. Callers should
  /// prefer this when non-null and fall back to [id] when null, which is what
  /// "carry canonical serviceId when available" means here.
  final int? canonicalServiceId;

  /// Original API map — preserved for BwBookingStore.selectOption() /
  /// AirconBookingStore.selectOption() compatibility.
  ///
  /// Compatibility surface, data layer only. It is passed to the booking
  /// stores, which already parse this exact shape; it must not be read by a
  /// widget for display, and nothing derives a label from it.
  final Object rawData;

  const ServiceOptionSummary({
    required this.id,
    required this.name,
    this.shortDescription,
    this.basePrice,
    required this.formattedPrice,
    this.imageAsset,
    required this.categoryKey,
    required this.hasAddons,
    required this.rawData,
    this.canonicalServiceId,
  });

  /// The identity a booking entry point should send.
  ///
  /// Canonical when known, else the legacy option id the backend resolves.
  /// One accessor so no call site has to re-derive the precedence.
  Object get bookableIdentity => canonicalServiceId ?? id;
}

// ── Mapper ─────────────────────────────────────────────────────────────────

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

abstract final class ServiceOptionSummaryMapper {
  static ServiceOptionSummary fromMap(Map<String, dynamic> o) {
    final id =
        (o['serviceOptionId'] ?? o['id'] ?? o['optionId'] ?? '').toString();
    final name = ServiceOptionDisplay.name(o);
    final description =
        o['shortDescription']?.toString() ?? o['description']?.toString();
    final price = _extractPrice(o);
    final level2 = ServiceOptionDisplay.level2(o);
    final addons = o['addons'];
    final hasAddons = addons is List && addons.isNotEmpty;

    return ServiceOptionSummary(
      id: id,
      name: name,
      shortDescription: description,
      basePrice: price,
      formattedPrice: _formatPrice(price),
      imageAsset: serviceImageAsset(name),
      categoryKey: level2,
      hasAddons: hasAddons,
      rawData: o,
      // Read only from an explicitly canonical key. Deliberately NOT derived
      // from `id`: `services.id` equals `service_options.id` for the rows the
      // promotion migration created, and stops equalling it for the first
      // Service an admin creates through the catalog API. Treating the legacy
      // id as canonical would be right today and silently wrong later.
      canonicalServiceId: _asInt(o['catalogServiceId'] ?? o['serviceId']),
    );
  }

  /// Delegates to the shared resolver so this screen and search cannot drift
  /// apart on what a row costs. They already had: search read one spelling and
  /// defaulted to 0, this read four and parsed strings, so the same option
  /// could show a price here and "Get a quote" there.
  static double? _extractPrice(Map<String, dynamic> o) =>
      extractCatalogPricePesos(o);

  static String _formatPrice(double? price) {
    if (price == null) return 'Price varies';
    final whole = price.truncate();
    if (price == whole) return '₱$whole';
    return '₱${price.toStringAsFixed(2)}';
  }
}

// ── Presentation configuration ─────────────────────────────────────────────

@immutable
class CategoryPresentationConfig {
  final ServiceCategoryId categoryId;

  /// Backend service ID (e.g. 1 = Aircon, 2 = B&W).
  final int serviceId;

  final CategoryThemeToken theme;
  final List<CategoryFilterChip> filterChips;
  final List<CategoryProcessStep> processSteps;
  final List<String> approvedBenefits;

  /// Headline shown during the category reveal.
  final String revealHeadline;
  final String revealSubtext;
  final String? semanticAnnouncement;

  /// Exact set of `level_2` values to include. Null = show all.
  final Set<String>? level2AllowList;

  /// Regex source string matched against `level_2`. Used only when
  /// [level2AllowList] is null. Null = show all.
  final String? level2Pattern;

  const CategoryPresentationConfig({
    required this.categoryId,
    required this.serviceId,
    required this.theme,
    required this.filterChips,
    required this.processSteps,
    required this.approvedBenefits,
    required this.revealHeadline,
    required this.revealSubtext,
    this.semanticAnnouncement,
    this.level2AllowList,
    this.level2Pattern,
  });

  String get displayTitle => revealHeadline;
}

// ── Registry ───────────────────────────────────────────────────────────────

abstract final class CategoryPresentationRegistry {
  static const beautyWellness = CategoryPresentationConfig(
    categoryId: ServiceCategoryId.beautyWellness,
    serviceId: 2,
    theme: CategoryThemeToken(
      primaryAccent: Color(0xFF3058C8),
      secondaryAccent: Color(0xFFE96F9C),
      heroGradientStart: Color(0xFF3058C8),
      heroGradientEnd: Color(0xFF1A3A9A),
      surfaceTint: Color(0xFFEFF3FF),
    ),
    filterChips: [
      CategoryFilterChip(label: 'All'),
      CategoryFilterChip(label: 'Drip', level2Value: 'drip'),
      CategoryFilterChip(label: 'Facial', level2Value: 'facial'),
    ],
    level2AllowList: {'drip', 'facial'},
    processSteps: [
      CategoryProcessStep(
          ordinal: 1,
          title: 'Choose a treatment',
          description: 'Browse available beauty services'),
      CategoryProcessStep(
          ordinal: 2,
          title: 'Select schedule & location',
          description: 'Pick a time and your preferred branch'),
      CategoryProcessStep(
          ordinal: 3,
          title: 'Confirm your booking',
          description: 'Review and pay securely'),
      CategoryProcessStep(
          ordinal: 4,
          title: 'Your professional arrives',
          description: 'Track your assigned professional'),
    ],
    approvedBenefits: [
      'Verified professionals',
      'Transparent pricing',
      'Convenient scheduling',
      'Secure payment',
    ],
    revealHeadline: 'Beauty & Wellness',
    revealSubtext: 'Feel refreshed, confident, and cared for.',
    semanticAnnouncement: 'Opening Beauty and Wellness category',
  );

  static const hairAndNails = CategoryPresentationConfig(
    categoryId: ServiceCategoryId.hairAndNails,
    serviceId: 2,
    theme: CategoryThemeToken(
      primaryAccent: Color(0xFF9B6DE3),
      secondaryAccent: Color(0xFFF89040),
      heroGradientStart: Color(0xFF7B4FBF),
      heroGradientEnd: Color(0xFF5A2D9E),
      surfaceTint: Color(0xFFF3EDFF),
    ),
    filterChips: [
      CategoryFilterChip(label: 'All'),
      CategoryFilterChip(label: 'Hair', level2Value: 'hair'),
      CategoryFilterChip(label: 'Nails', level2Value: 'nails'),
    ],
    level2Pattern: r'hair|nail|manicure|pedicure',
    processSteps: [
      CategoryProcessStep(
          ordinal: 1,
          title: 'Choose your style',
          description: 'Browse hair and nail services'),
      CategoryProcessStep(
          ordinal: 2,
          title: 'Select schedule & location',
          description: 'Pick a time and your preferred branch'),
      CategoryProcessStep(
          ordinal: 3,
          title: 'Confirm your booking',
          description: 'Review and pay securely'),
      CategoryProcessStep(
          ordinal: 4,
          title: 'Your professional arrives',
          description: 'Track your assigned professional'),
    ],
    approvedBenefits: [
      'Skilled stylists',
      'Clear service options',
      'Flexible scheduling',
      'Secure payment',
    ],
    revealHeadline: 'Hair & Nails',
    revealSubtext: 'Express yourself with every visit.',
    semanticAnnouncement: 'Opening Hair and Nails category',
  );

  static const massage = CategoryPresentationConfig(
    categoryId: ServiceCategoryId.massage,
    serviceId: 2,
    theme: CategoryThemeToken(
      primaryAccent: Color(0xFF2DBBA7),
      secondaryAccent: Color(0xFF3D8B7A),
      heroGradientStart: Color(0xFF2DBBA7),
      heroGradientEnd: Color(0xFF1A7A6A),
      surfaceTint: Color(0xFFEAF7F5),
    ),
    filterChips: [
      CategoryFilterChip(label: 'All'),
    ],
    level2Pattern: r'massage',
    processSteps: [
      CategoryProcessStep(
          ordinal: 1,
          title: 'Choose your massage',
          description: 'Browse restorative treatments'),
      CategoryProcessStep(
          ordinal: 2,
          title: 'Select schedule & location',
          description: 'Pick a time and your preferred branch'),
      CategoryProcessStep(
          ordinal: 3,
          title: 'Confirm your booking',
          description: 'Review and pay securely'),
      CategoryProcessStep(
          ordinal: 4,
          title: 'Your professional arrives',
          description: 'Track your assigned professional'),
    ],
    approvedBenefits: [
      'Certified therapists',
      'Restful experience',
      'Flexible scheduling',
      'Secure payment',
    ],
    revealHeadline: 'Massage',
    revealSubtext: 'Restore your body and calm your mind.',
    semanticAnnouncement: 'Opening Massage category',
  );

  static const aircon = CategoryPresentationConfig(
    categoryId: ServiceCategoryId.aircon,
    serviceId: 1,
    theme: CategoryThemeToken(
      primaryAccent: Color(0xFF2D78F5),
      secondaryAccent: Color(0xFF1A4A7C),
      heroGradientStart: Color(0xFF2D78F5),
      heroGradientEnd: Color(0xFF1040AA),
      surfaceTint: Color(0xFFEAF1FF),
    ),
    filterChips: [
      CategoryFilterChip(label: 'All'),
      CategoryFilterChip(label: 'Cleaning', level2Value: 'cleaning'),
      CategoryFilterChip(label: 'Installation', level2Value: 'installation'),
      CategoryFilterChip(label: 'Repair', level2Value: 'repair'),
    ],
    processSteps: [
      CategoryProcessStep(
          ordinal: 1,
          title: 'Select your service',
          description: 'Choose cleaning, installation, or repair'),
      CategoryProcessStep(
          ordinal: 2,
          title: 'Configure your unit',
          description: 'Enter HP, floor level, and distance'),
      CategoryProcessStep(
          ordinal: 3,
          title: 'Get your quote',
          description: 'Review the backend-calculated price'),
      CategoryProcessStep(
          ordinal: 4,
          title: 'Book and confirm',
          description: 'Pay and track your technician'),
    ],
    approvedBenefits: [
      'Certified technicians',
      'Backend-verified pricing',
      'Reliable service',
      'Secure payment',
    ],
    revealHeadline: 'Aircon Services',
    revealSubtext: 'Keep cool with trusted professionals.',
    semanticAnnouncement: 'Opening Aircon Services category',
  );

  static const generic = CategoryPresentationConfig(
    categoryId: ServiceCategoryId.generic,
    serviceId: 0,
    theme: CategoryThemeToken(
      primaryAccent: Color(0xFF3058C8),
      secondaryAccent: Color(0xFFF89040),
      heroGradientStart: Color(0xFF3058C8),
      heroGradientEnd: Color(0xFF1A3A9A),
      surfaceTint: Color(0xFFEFF3FF),
    ),
    filterChips: [
      CategoryFilterChip(label: 'All'),
    ],
    processSteps: [
      CategoryProcessStep(
          ordinal: 1,
          title: 'Choose a service',
          description: 'Browse available options'),
      CategoryProcessStep(
          ordinal: 2,
          title: 'Select your schedule',
          description: 'Pick a convenient time'),
      CategoryProcessStep(
          ordinal: 3,
          title: 'Confirm your booking',
          description: 'Review and pay securely'),
      CategoryProcessStep(
          ordinal: 4,
          title: 'Track your professional',
          description: 'Your assigned professional is on the way'),
    ],
    approvedBenefits: [
      'Verified professionals',
      'Transparent pricing',
      'Convenient scheduling',
      'Secure payment',
    ],
    revealHeadline: 'Services',
    revealSubtext: 'Quality service, booked around your schedule.',
  );

  static CategoryPresentationConfig forId(ServiceCategoryId id) => switch (id) {
        ServiceCategoryId.beautyWellness => beautyWellness,
        ServiceCategoryId.hairAndNails => hairAndNails,
        ServiceCategoryId.massage => massage,
        ServiceCategoryId.aircon => aircon,
        ServiceCategoryId.generic => generic,
      };
}
