import 'package:flutter/material.dart';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';

/// Native rendering of the launch campaign (LAUNCHBANNER+ §16).
///
/// The supplied creative carries its message as pixels. Rasterised text cannot
/// respond to the system text size, cannot be read by a screen reader, and
/// cannot reflow — so at large text scales, or when the image fails to load,
/// the campaign has to be able to say the same thing in real widgets.
///
/// This is not a degraded fallback. Every claim in the artwork appears here as
/// structured, scalable, announceable content, which for some customers is
/// strictly the better presentation.
class ServanaLaunchBenefitsAccessibleView extends StatelessWidget {
  const ServanaLaunchBenefitsAccessibleView({
    super.key,
    required this.onExplore,
    required this.onRemindLater,
    this.showThumbnail = false,
    this.assetPath,
  });

  final VoidCallback onExplore;
  final VoidCallback onRemindLater;

  /// Optional decorative thumbnail. Excluded from semantics — the text below
  /// already carries the meaning, and announcing both makes the customer hear
  /// the campaign twice.
  final bool showThumbnail;
  final String? assetPath;

  static const benefits = <(IconData, String, String)>[
    (
      Icons.grid_view_rounded,
      'Wide service selection',
      'From beauty to repairs and more — all in one place.',
    ),
    (
      Icons.event_available_rounded,
      'Convenient booking',
      'Pick your service, choose your time, we will handle the rest.',
    ),
    (
      Icons.lock_rounded,
      'Secure experience',
      'Your data and payments are always protected.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showThumbnail && assetPath != null) ...[
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                assetPath!,
                height: 96,
                fit: BoxFit.cover,
                // A failed thumbnail must not break the layout that exists
                // precisely because the image might fail.
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // §17: a real heading, so screen-reader users can navigate by heading
        // rather than hearing an undifferentiated wall of text.
        Semantics(
          header: true,
          child: Text(
            'Everything you need, all in one app',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: ColorPalette.secondaryText,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Browse services, choose your schedule, and get updates right from '
          'your phone.',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontSize: 15,
            height: 1.45,
            color: ColorPalette.accentText,
          ),
        ),
        const SizedBox(height: 20),

        for (final (icon, title, body) in benefits) ...[
          _BenefitRow(icon: icon, title: title, body: body),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // One node per benefit. Without this the reader announces the icon, the
      // title and the body as three unrelated fragments.
      label: '$title. $body',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorPalette.primaryColorLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: ColorPalette.primaryColorDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 13,
                    height: 1.35,
                    color: ColorPalette.accentText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
