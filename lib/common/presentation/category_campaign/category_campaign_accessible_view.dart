import 'package:flutter/material.dart';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';

/// Native rendering of a category campaign.
///
/// The creatives carry their message as pixels. Rasterised text cannot respond
/// to the system text size, cannot be read by a screen reader, and cannot
/// reflow — so at large text scales, or when the image fails to load, the
/// campaign has to be able to say the same thing in real widgets.
///
/// This is not a degraded fallback. Every claim in the artwork appears here as
/// structured, scalable, announceable content, which for some customers is
/// strictly the better presentation.
class CategoryCampaignAccessibleView extends StatefulWidget {
  const CategoryCampaignAccessibleView({
    required this.heading,
    required this.tagline,
    required this.body,
    required this.services,
    required this.benefits,
    required this.primaryActionLabel,
    required this.closeLabel,
    required this.accentColor,
    required this.onExplore,
    required this.onClose,
    required this.onReady,
    super.key,
  });

  final String heading;
  final String tagline;
  final String body;
  final List<String> services;
  final List<String> benefits;
  final String primaryActionLabel;
  final String closeLabel;
  final Color accentColor;
  final VoidCallback onExplore;
  final VoidCallback onClose;

  /// Called once the layout has painted, so the caller can count an impression
  /// only for a campaign the customer actually saw.
  final VoidCallback onReady;

  @override
  State<CategoryCampaignAccessibleView> createState() =>
      _CategoryCampaignAccessibleViewState();
}

class _CategoryCampaignAccessibleViewState
    extends State<CategoryCampaignAccessibleView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorPalette.primaryBackground,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Right-padded so long headings never run under the close
                // control, which sits in the same corner.
                Padding(
                  padding: const EdgeInsets.only(right: 44),
                  child: Text(
                    widget.heading,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.tagline,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.body,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 14,
                    height: 1.45,
                    color: ColorPalette.secondaryText.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                _Section(label: 'Services', items: widget.services),
                const SizedBox(height: 12),
                _Section(label: 'Why Servana', items: widget.benefits),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  // 52 clears the 48dp minimum with room for a focus ring.
                  height: 52,
                  child: FilledButton(
                    onPressed: widget.onExplore,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Text(
                      widget.primaryActionLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: widget.onClose,
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Semantics(
              button: true,
              label: widget.closeLabel,
              excludeSemantics: true,
              child: IconButton(
                onPressed: widget.onClose,
                iconSize: 24,
                // Matches the artwork layout's 48dp control.
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                icon: Icon(
                  Icons.close_rounded,
                  color: ColorPalette.secondaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.items});

  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: ColorPalette.secondaryText.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryColorDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 14,
                      height: 1.4,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
