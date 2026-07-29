import 'package:client/modules/review/domain/provider_review_response.dart';
import 'package:client/modules/review/domain/review_dimension.dart';
import 'package:client/modules/review/domain/review_moderation_status.dart';
import 'package:client/modules/review/domain/review_visibility.dart';

/// The canonical customer review domain model.
///
/// Constructed from API responses. All times are UTC; callers convert for display.
class ServanaReview {
  const ServanaReview({
    required this.reviewId,
    required this.bookingId,
    required this.overallRating,
    required this.visibility,
    required this.moderationStatus,
    required this.dimensions,
    this.providerUid,
    this.serviceId,
    this.publicComment,
    this.privateFeedback,
    this.providerResponse,
    this.createdAt,
    this.updatedAt,
    this.editedAt,
  });

  final String reviewId;
  final String bookingId;
  final String? providerUid;
  final String? serviceId;
  final int overallRating;
  final String? publicComment;
  final String? privateFeedback;
  final ReviewVisibility visibility;
  final ReviewModerationStatus moderationStatus;
  final List<ReviewDimensionScore> dimensions;
  final ProviderReviewResponse? providerResponse;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? editedAt;

  bool get isEdited => editedAt != null;
  bool get isVisible => moderationStatus.isVisible;
  bool get hasResponse => providerResponse != null;

  factory ServanaReview.fromMap(Map<String, dynamic> m) => ServanaReview(
    reviewId:         m['reviewId'] as String? ?? '',
    bookingId:        m['bookingId'] as String? ?? '',
    providerUid:      m['providerUid'] as String?,
    serviceId:        m['serviceId'] as String?,
    overallRating:    (m['overallRating'] as num?)?.toInt() ?? 0,
    publicComment:    m['publicComment'] as String?,
    privateFeedback:  m['privateFeedback'] as String?,
    visibility:       ReviewVisibility.fromString(m['visibility'] as String?),
    moderationStatus: ReviewModerationStatus.fromString(m['moderationStatus'] as String?),
    dimensions: (m['dimensions'] as List? ?? [])
        .map((e) => ReviewDimensionScore.fromMap(e as Map<String, dynamic>))
        .toList(),
    providerResponse: m['providerResponse'] != null
        ? ProviderReviewResponse.fromMap(m['providerResponse'] as Map<String, dynamic>)
        : null,
    createdAt: m['createdAt'] != null ? DateTime.tryParse(m['createdAt'].toString()) : null,
    updatedAt: m['updatedAt'] != null ? DateTime.tryParse(m['updatedAt'].toString()) : null,
    editedAt:  m['editedAt']  != null ? DateTime.tryParse(m['editedAt'].toString())  : null,
  );

  ServanaReview copyWith({
    ReviewModerationStatus? moderationStatus,
    ProviderReviewResponse? providerResponse,
  }) =>
      ServanaReview(
        reviewId:         reviewId,
        bookingId:        bookingId,
        providerUid:      providerUid,
        serviceId:        serviceId,
        overallRating:    overallRating,
        publicComment:    publicComment,
        privateFeedback:  privateFeedback,
        visibility:       visibility,
        moderationStatus: moderationStatus ?? this.moderationStatus,
        dimensions:       dimensions,
        providerResponse: providerResponse ?? this.providerResponse,
        createdAt:        createdAt,
        updatedAt:        updatedAt,
        editedAt:         editedAt,
      );
}
