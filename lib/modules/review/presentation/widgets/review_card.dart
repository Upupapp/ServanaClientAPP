import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/review/domain/servana_review.dart';
import 'package:client/modules/review/presentation/widgets/review_moderation_banner.dart';
import 'package:client/modules/review/presentation/widgets/review_rating_control.dart';
import 'package:flutter/material.dart';

/// Displays a submitted review in a card layout.
/// Used on booking detail and review history screens.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.onReport,
    this.showPrivate = false,
  });

  final ServanaReview review;
  final VoidCallback? onReport;
  final bool showPrivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorPalette.border(.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReviewModerationBanner(status: review.moderationStatus),

          // Rating row
          Row(
            children: [
              ReviewStarDisplay(
                  rating: review.overallRating.toDouble(), size: 18),
              const Spacer(),
              if (review.isEdited)
                Text(
                  'Edited',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 11,
                    color: ColorPalette.accentText,
                  ),
                ),
              if (review.createdAt != null) ...[
                const SizedBox(width: 6),
                Text(
                  _formatDate(review.createdAt!),
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 11,
                    color: ColorPalette.accentText,
                  ),
                ),
              ],
            ],
          ),

          // Public comment
          if ((review.publicComment ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.publicComment!,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 14,
                color: ColorPalette.secondaryText,
                height: 1.45,
              ),
            ),
          ],

          // Private feedback (only shown to the reviewer themselves)
          if (showPrivate && (review.privateFeedback ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorPalette.primaryColorDark.withOpacity(.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 14, color: ColorPalette.accentText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      review.privateFeedback!,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 13,
                        color: ColorPalette.accentText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Provider response
          if (review.hasResponse) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.reply_rounded,
                    size: 14, color: ColorPalette.primaryColorDark),
                const SizedBox(width: 6),
                Text(
                  'Provider response',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review.providerResponse!.body,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 13,
                color: ColorPalette.secondaryText,
                height: 1.4,
              ),
            ),
          ],

          // Report action
          if (onReport != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onReport,
                child: Text(
                  'Report',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    color: ColorPalette.accentText,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
