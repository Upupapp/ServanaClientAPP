import 'package:client/modules/review/domain/review_visibility.dart';

/// In-memory draft for the review form — never persisted to disk.
class ReviewDraft {
  const ReviewDraft({
    required this.bookingId,
    this.overallRating = 0,
    this.dimensions = const {},
    this.publicComment = '',
    this.privateFeedback = '',
    this.visibility = ReviewVisibility.public,
    this.clientRequestId,
  });

  final String bookingId;
  final int overallRating; // 0 = unset, 1–5 = set
  final Map<String, int> dimensions;
  final String publicComment;
  final String privateFeedback;
  final ReviewVisibility visibility;
  final String? clientRequestId;

  bool get isRatingSet => overallRating >= 1 && overallRating <= 5;
  bool get isSubmittable => isRatingSet;

  ReviewDraft copyWith({
    int? overallRating,
    Map<String, int>? dimensions,
    String? publicComment,
    String? privateFeedback,
    ReviewVisibility? visibility,
    String? clientRequestId,
  }) =>
      ReviewDraft(
        bookingId: bookingId,
        overallRating: overallRating ?? this.overallRating,
        dimensions: dimensions ?? this.dimensions,
        publicComment: publicComment ?? this.publicComment,
        privateFeedback: privateFeedback ?? this.privateFeedback,
        visibility: visibility ?? this.visibility,
        clientRequestId: clientRequestId ?? this.clientRequestId,
      );

  ReviewDraft setDimension(String key, int score) => copyWith(
        dimensions: Map.from(dimensions)..[key] = score,
      );
}
