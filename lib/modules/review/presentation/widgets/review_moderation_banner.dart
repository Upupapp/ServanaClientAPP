import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/review/domain/review_moderation_status.dart';
import 'package:flutter/material.dart';

class ReviewModerationBanner extends StatelessWidget {
  const ReviewModerationBanner({super.key, required this.status});

  final ReviewModerationStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.isVisible) return const SizedBox.shrink();

    final (icon, label, bg, fg) = _config(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 13,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, String, Color, Color) _config(ReviewModerationStatus s) {
    switch (s) {
      case ReviewModerationStatus.pending:
      case ReviewModerationStatus.flagged:
        return (
          Icons.hourglass_top_rounded,
          'This review is being reviewed by our team and is temporarily not public.',
          const Color(0xFFFEF3C7),
          const Color(0xFF92400E),
        );
      case ReviewModerationStatus.rejected:
      case ReviewModerationStatus.removed:
        return (
          Icons.block_rounded,
          'This review was removed for violating our community guidelines.',
          ColorPalette.danger.withOpacity(.08),
          ColorPalette.danger,
        );
      case ReviewModerationStatus.hidden:
        return (
          Icons.visibility_off_outlined,
          'This review is temporarily hidden.',
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280),
        );
      default:
        return (Icons.info_outline, '', Colors.transparent, Colors.transparent);
    }
  }
}
