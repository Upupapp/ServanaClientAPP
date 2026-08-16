/// Reviews as the app does them today.
///
/// ## The folded read, assembled from two calls
///
/// [reviewOrEligibility] is one method on the interface because the canonical
/// endpoint answers it in one response. This transport has no such endpoint, so
/// it issues both legacy calls and folds them here.
///
/// They run **in parallel**, which is safe because both are reads, and the
/// result is resolved with an existing review winning — see
/// [ReviewOrEligibility.fromLegacyPair]. That does not remove the race the
/// canonical endpoint removes; the two verdicts are still computed at two
/// instants. What it does is put the resolution in one place, so both
/// controllers get the same answer instead of each asking half the question.
///
/// Before this, `ReviewFormController` asked eligibility alone and
/// `ReviewDetailController` asked for the review alone. The form could open on
/// a booking that already had a review, because it never looked.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/review/data/reviews_data_source.dart';
import 'package:client/modules/review/domain/review_aggregate.dart';
import 'package:client/modules/review/domain/review_draft.dart';
import 'package:client/modules/review/domain/review_eligibility.dart';
import 'package:client/modules/review/domain/review_or_eligibility.dart';
import 'package:client/modules/review/domain/servana_review.dart';

class ReviewsCompatibilityDataSource implements ReviewsDataSource {
  const ReviewsCompatibilityDataSource(this._api);

  final ServanaApiClient _api;

  @override
  Future<ReviewOrEligibility> reviewOrEligibility(String bookingId) async {
    // Both are reads, so firing them together costs one round trip rather than
    // two. A failure of either still throws — this method answers one question
    // and half an answer is not one.
    final results = await Future.wait<Object?>(<Future<Object?>>[
      _reviewByBooking(bookingId),
      _api.getReviewEligibility(bookingId),
    ]);

    final review = results[0] as ServanaReview?;
    final eligibility = ReviewEligibility.fromMap(_map(results[1]));

    return ReviewOrEligibility.fromLegacyPair(
      review: review,
      eligibility: eligibility,
    );
  }

  Future<ServanaReview?> _reviewByBooking(String bookingId) async {
    try {
      final res = await _api.getReviewByBooking(bookingId);
      final data = res['data'] ?? res;
      if (data == null) return null;
      return ServanaReview.fromMap(_map(data));
    } on ServanaApiException catch (e) {
      // 404 is "not reviewed yet", which is the ordinary case and not an error.
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
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

  @override
  Future<ReviewAggregate> providerAggregate(String providerUid) async {
    final res = await _api.getProviderAggregate(providerUid);
    return ReviewAggregate.fromMap(_map(res['data'] ?? res));
  }

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map<String, dynamic> ? v : <String, dynamic>{};
}
