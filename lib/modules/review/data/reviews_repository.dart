import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/review/domain/review_aggregate.dart';
import 'package:client/modules/review/domain/review_draft.dart';
import 'package:client/modules/review/domain/review_eligibility.dart';
import 'package:client/modules/review/domain/servana_review.dart';

class ReviewsRepository {
  ReviewsRepository({required ServanaApiClient api}) : _api = api;

  final ServanaApiClient _api;

  Future<ReviewEligibility> getEligibility(String bookingId) async {
    final res = await _api.getReviewEligibility(bookingId);
    return ReviewEligibility.fromMap(_map(res));
  }

  Future<ServanaReview> createReview(ReviewDraft draft) async {
    final res = await _api.createReview(
      bookingId: draft.bookingId,
      overallRating: draft.overallRating,
      dimensions: draft.dimensions,
      publicComment: draft.publicComment.trim().isNotEmpty
          ? draft.publicComment.trim()
          : null,
      privateFeedback: draft.privateFeedback.trim().isNotEmpty
          ? draft.privateFeedback.trim()
          : null,
      visibility: draft.visibility.apiValue,
      clientRequestId: draft.clientRequestId,
    );
    return ServanaReview.fromMap(_map(res));
  }

  Future<ServanaReview?> getByBooking(String bookingId) async {
    try {
      final res = await _api.getReviewByBooking(bookingId);
      final data = res['data'] ?? res;
      if (data == null) return null;
      return ServanaReview.fromMap(_map(data));
    } on ServanaApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<ServanaReview?> getById(String reviewId) async {
    try {
      final res = await _api.getReviewById(reviewId);
      final data = res['data'] ?? res;
      if (data == null) return null;
      return ServanaReview.fromMap(_map(data));
    } on ServanaApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<ServanaReview> editReview(String reviewId, ReviewDraft draft) async {
    final res = await _api.editReview(
      reviewId: reviewId,
      overallRating: draft.overallRating,
      dimensions: draft.dimensions,
      publicComment: draft.publicComment.trim().isNotEmpty
          ? draft.publicComment.trim()
          : null,
      privateFeedback: draft.privateFeedback.trim().isNotEmpty
          ? draft.privateFeedback.trim()
          : null,
      visibility: draft.visibility.apiValue,
    );
    return ServanaReview.fromMap(_map(res['data'] ?? res));
  }

  Future<void> deleteReview(String reviewId) async {
    await _api.deleteReview(reviewId);
  }

  Future<List<ServanaReview>> listMyReviews() async {
    final res = await _api.listMyReviews();
    final list = (res['reviews'] ?? res['data']) as List? ?? [];
    return list.map((e) => ServanaReview.fromMap(_map(e))).toList();
  }

  Future<void> reportReview({
    required String reviewId,
    required String reason,
    String? details,
  }) async {
    await _api.reportReview(
        reviewId: reviewId, reason: reason, details: details);
  }

  Future<ReviewAggregate> getProviderAggregate(String providerUid) async {
    final res = await _api.getProviderAggregate(providerUid);
    return ReviewAggregate.fromMap(_map(res['data'] ?? res));
  }

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map<String, dynamic> ? v : <String, dynamic>{};
}
