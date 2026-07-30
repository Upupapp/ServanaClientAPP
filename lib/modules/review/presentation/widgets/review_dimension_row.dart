import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/review/domain/review_dimension.dart';
import 'package:flutter/material.dart';

/// A single dimension rating row: label on left, 5 stars on right.
class ReviewDimensionRow extends StatelessWidget {
  const ReviewDimensionRow({
    super.key,
    required this.dimensionKey,
    required this.score,
    required this.onScoreChanged,
    this.enabled = true,
  });

  final String dimensionKey;
  final int score; // 0 = unset
  final ValueChanged<int> onScoreChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final label = ReviewDimensionScore.labelFor(dimensionKey);
    return Semantics(
      label: '$label: ${score == 0 ? 'not rated' : '$score out of 5'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 14,
                  color: ColorPalette.secondaryText,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final val = i + 1;
                final filled = val <= score;
                return Semantics(
                  label: '$label: $val of 5',
                  button: true,
                  selected: score == val,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: enabled ? () => onScoreChanged(val) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: filled ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                        size: 22,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
