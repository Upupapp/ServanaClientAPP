/// Catalog categories Home has no curated card for.
///
/// ## Why this is a separate row rather than a replacement grid
///
/// `ServanaHomeCategoryGrid` draws four hand-designed cards — bespoke
/// gradient, icon and phrase each — and their keys (`beauty_wellness`,
/// `hair_nails`, `massage`, `aircon`) are what Home's navigation AND the
/// category campaign registry are keyed on. The catalog's own vocabulary is
/// different: `slugify` on the backend produces hyphens, so the same category
/// arrives as `beauty-wellness`. Swapping the grid's contents for catalog rows
/// would therefore have done three things at once — dropped the curated
/// styling, broken the campaign lookup silently, and routed through keys the
/// bespoke category experiences do not recognise.
///
/// So the curated four are left exactly as they are, and this row adds only
/// what they do not already cover. Purely additive: a customer sees everything
/// they saw before, plus the categories that existed in the catalog and were
/// unreachable from Home.
///
/// ## Routed by id, never by slug
///
/// These go to `CatalogRoutes.category`, which is keyed on
/// `catalog_categories.id` so that renaming a category cannot break a link
/// already in the field.
library;

import 'package:client/common/constants/app_spacing.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/homepage/application/home_composition_controller.dart';
import 'package:flutter/material.dart';

/// The keys the curated grid already draws, in ITS vocabulary.
///
/// Compared against [HomeCategory.curatedKey], which normalises the backend's
/// hyphens to underscores. Kept next to the comparison rather than imported
/// from the grid so the grid stays a pure presentation widget.
const Set<String> kCuratedCategoryKeys = <String>{
  'beauty_wellness',
  'hair_nails',
  'massage',
  'aircon',
};

typedef CatalogCategoryTap = void Function(HomeCategory category);

class HomeMoreCategories extends StatelessWidget {
  const HomeMoreCategories({
    super.key,
    required this.state,
    required this.onTap,
  });

  final HomeCategoriesState state;
  final CatalogCategoryTap onTap;

  @override
  Widget build(BuildContext context) {
    // Loading, unavailable, or a catalog that only contains what Home already
    // draws — all render nothing. Home's curated grid is above this and is
    // never blocked by it, which is the point: this row can fail completely
    // and Home is exactly as good as it was before it existed.
    if (state is! HomeCategoriesReady) return const SizedBox.shrink();

    final extra = (state as HomeCategoriesReady)
        .categories
        .where((c) => !kCuratedCategoryKeys.contains(c.curatedKey))
        .toList(growable: false);

    if (extra.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: homeGutter(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'More services',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ColorPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          // Wrap rather than a fixed-count grid: the number of extra
          // categories is whatever Admin has created.
          //
          // A Wrap gives each child UNBOUNDED width, so reflowing protects the
          // row and not the chip — a long category name at 200% text still
          // overflows its own run. LayoutBuilder supplies the cap, and each
          // chip is told what it may not exceed.
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in extra)
                  _CategoryChip(
                    category: category,
                    maxWidth: constraints.maxWidth,
                    onTap: () {
                      AppHaptics.selection();
                      onTap(category);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.maxWidth,
    required this.onTap,
  });

  final HomeCategory category;

  /// The widest this chip may be. A Wrap does not impose one.
  final double maxWidth;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = category.serviceCount;

    return Semantics(
      button: true,
      label: count != null && count > 0
          ? '${category.name}, $count services'
          : category.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // 44 is AccessibilityTokens.minTouchTarget. A chip that reflows is
          // still a tap target.
          constraints: BoxConstraints(minHeight: 44, maxWidth: maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorPalette.accentText.withOpacity(.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flexible so the NAME yields first. The count is two or three
              // characters and clipping it turns "12 services" into noise,
              // whereas a shortened name is still recognisable.
              Flexible(
                child: Text(
                  category.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: ColorPalette.secondaryText,
                  ),
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    color: ColorPalette.accentText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
