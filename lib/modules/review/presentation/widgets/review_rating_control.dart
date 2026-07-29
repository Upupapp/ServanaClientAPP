import 'package:flutter/material.dart';

/// Interactive 5-star rating selector.
///
/// Starts in an unselected state (rating == 0). Calls [onRatingChanged] on tap.
/// Supports TalkBack/VoiceOver — each star has a semantic label.
class ReviewRatingControl extends StatelessWidget {
  const ReviewRatingControl({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 44.0,
    this.enabled = true,
  });

  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: rating == 0
          ? 'Rating not yet selected'
          : '$rating out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final starValue = i + 1;
          final filled = starValue <= rating;
          return Semantics(
            button: true,
            label: '$starValue star${starValue == 1 ? '' : 's'}',
            selected: starValue == rating,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: enabled ? () => onRatingChanged(starValue) : null,
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                  size: size * 0.72,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Read-only compact star display (e.g. in cards/headers).
class ReviewStarDisplay extends StatelessWidget {
  const ReviewStarDisplay({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.showLabel = true,
  });

  final double rating; // 0.0–5.0
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final hasRating = rating > 0;
    return Semantics(
      label: hasRating ? '${rating.toStringAsFixed(1)} stars' : 'No rating yet',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: hasRating ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
            size: size,
          ),
          if (showLabel) ...[
            const SizedBox(width: 3),
            Text(
              hasRating ? rating.toStringAsFixed(1) : '–',
              style: TextStyle(
                fontSize: size * 0.85,
                fontWeight: FontWeight.w600,
                color: hasRating ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
