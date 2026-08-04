import 'package:flutter/widgets.dart';

import 'package:client/common/domain/services/service_category_config.dart';

/// Everything a category campaign popup needs, per category.
///
/// One record per creative. Adding a campaign is a matter of measuring its
/// artwork and adding an entry here — no new modal, no new tap handler, no new
/// route.
@immutable
class CategoryCampaign {
  const CategoryCampaign({
    required this.categoryId,
    required this.campaignKey,
    required this.categoryKey,
    required this.assetPath,
    required this.assetWidth,
    required this.assetHeight,
    required this.ctaRect,
    required this.semanticSummary,
    required this.primaryActionLabel,
    required this.closeLabel,
  });

  final ServiceCategoryId categoryId;

  /// Stable analytics identifier for this creative.
  final String campaignKey;

  /// The Home grid key, matching `_categoryIdFromKey` in the router.
  final String categoryKey;

  final String assetPath;

  /// Real pixel dimensions of the shipped PNG.
  ///
  /// Stored rather than assumed: both creatives were specified as 928x1648 and
  /// delivered as 941x1672. Driving [aspectRatio] from the spec instead of the
  /// file would inset the artwork inside its own box, and the CTA overlay —
  /// which is positioned against that box — would drift off the drawn button.
  final int assetWidth;
  final int assetHeight;

  double get aspectRatio => assetWidth / assetHeight;

  /// The drawn call-to-action as fractions of the artboard, measured from the
  /// shipped PNG by locating the saturated pill against the dark backdrop.
  final Rect ctaRect;

  /// One coherent sentence for a screen reader, replacing the ~20 fragments of
  /// text baked into the artwork.
  final String semanticSummary;

  final String primaryActionLabel;
  final String closeLabel;
}

/// The campaigns that currently exist.
///
/// A category with no entry keeps its previous behaviour — tapping navigates
/// straight through — so adding a creative here is the only thing that turns a
/// popup on, and removing it is the only thing needed to turn one off.
abstract final class CategoryCampaignRegistry {
  /// Beauty & Wellness.
  ///
  /// CTA pill measured at x 133..806, y 1492..1585 of 941x1672.
  static const CategoryCampaign beautyWellness = CategoryCampaign(
    categoryId: ServiceCategoryId.beautyWellness,
    campaignKey: 'beauty_wellness_category_popup_v1',
    categoryKey: 'beauty_wellness',
    assetPath: 'assets/images/categories/beauty_wellness_popup_v1.png',
    assetWidth: 941,
    assetHeight: 1672,
    ctaRect: Rect.fromLTWH(0.1413, 0.8923, 0.7163, 0.0562),
    semanticSummary:
        'Beauty and Wellness. Feel refreshed, confident, and cared for. '
        'Book beauty, massage, facial, nail, and salon services with trusted '
        'providers and convenient scheduling.',
    primaryActionLabel: 'Explore Beauty and Wellness',
    closeLabel: 'Close Beauty and Wellness promotion',
  );

  /// Hair & Nails.
  ///
  /// CTA pill measured at x 119..816, y 1503..1598 of 941x1672.
  static const CategoryCampaign hairAndNails = CategoryCampaign(
    categoryId: ServiceCategoryId.hairAndNails,
    campaignKey: 'hair_nails_category_popup_v1',
    categoryKey: 'hair_nails',
    assetPath: 'assets/images/categories/hair_nails_popup_v1.png',
    assetWidth: 941,
    assetHeight: 1672,
    ctaRect: Rect.fromLTWH(0.1265, 0.8989, 0.7418, 0.0574),
    semanticSummary:
        'Hair and Nails. Look your best, every day. Book haircut, styling, '
        'hair-treatment, manicure, pedicure, and nail-art services with '
        'skilled professionals and easy scheduling.',
    primaryActionLabel: 'Explore Hair and Nails',
    closeLabel: 'Close Hair and Nails promotion',
  );

  static const List<CategoryCampaign> all = <CategoryCampaign>[
    beautyWellness,
    hairAndNails,
  ];

  /// The campaign for [key], or null when that category has none.
  static CategoryCampaign? forCategoryKey(String key) {
    for (final c in all) {
      if (c.categoryKey == key) return c;
    }
    return null;
  }
}
