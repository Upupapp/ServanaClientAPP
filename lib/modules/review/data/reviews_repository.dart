/// Reviews feature repository.
///
///     ReviewsRepository
///       → ReviewsCanonicalDataSource      per capability
///       → ReviewsCompatibilityDataSource  otherwise
///
/// ## Four route; five never will
///
/// TAB 01's R-11 said reviews cannot migrate as one feature, and TAB 14
/// re-measured it and found it exactly right. The manifest's remedy — decline
/// to name the domain — was correct and incomplete: the four calls that DO have
/// successors are a coherent slice, and the five that do not are the per-call
/// escape this codebase has used since TAB 02.
///
/// | Call | Transport |
/// | --- | --- |
/// | [reviewOrEligibility] | routed — `bookingReview` |
/// | [createReview] | routed — `bookingReview` |
/// | [getProviderAggregate] | routed — `providerReputation` |
/// | [getById], [editReview], [deleteReview], [listMyReviews], [reportReview] | **always legacy** |
///
/// The five are called directly on [ServanaApiClient], in every configuration,
/// exactly as `NotificationsRepository.dismiss` and
/// `MessagingRepository.reportMessage` are. Managing a review by its own id —
/// reading, editing, deleting, listing yours, reporting somebody's — has no
/// canonical surface at all.
///
/// ## Two capabilities, because they are two questions
///
/// `bookingReview` is "the review I leave on my booking". `providerReputation`
/// is "what other customers said about this provider", which is read from a
/// provider profile with no booking in sight. They share a backend domain and
/// nothing else, and an operator should be able to move the read-only one
/// first.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/review/data/reviews_data_source.dart';
import 'package:client/modules/review/domain/review_aggregate.dart';
import 'package:client/modules/review/domain/review_draft.dart';
import 'package:client/modules/review/domain/review_eligibility.dart';
import 'package:client/modules/review/domain/review_or_eligibility.dart';
import 'package:client/modules/review/domain/servana_review.dart';

class ReviewsRepository {
  ReviewsRepository({
    required ServanaApiClient api,
    required ReviewsDataSource compatibility,
    ReviewsDataSource? canonical,
    CanonicalRouter? router,
  })  : _api = api,
        _compatibility = compatibility,
        _canonical = canonical,
        _router = router;

  /// Serves the five calls with no canonical successor.
  final ServanaApiClient _api;

  final ReviewsDataSource _compatibility;
  final ReviewsDataSource? _canonical;
  final CanonicalRouter? _router;

  ReviewsDataSource _sourceFor(V1Capability capability) {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<ReviewsDataSource>(
      capability,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  /// True when the booking review is served by `/api/v1`. Diagnostics only.
  bool get bookingReviewIsCanonical =>
      _canonical != null &&
      (_router?.isCanonical(V1Capability.bookingReview) ?? false);

  /// True when provider ratings are served by `/api/v1`. Diagnostics only.
  bool get providerReputationIsCanonical =>
      _canonical != null &&
      (_router?.isCanonical(V1Capability.providerReputation) ?? false);

  // ── Routed ────────────────────────────────────────────────────────────────

  /// The caller's review for [bookingId], or the verdict on leaving one.
  ///
  /// One question. The canonical endpoint answers it in one response; the
  /// compatibility source assembles the same answer from the two legacy calls.
  Future<ReviewOrEligibility> reviewOrEligibility(String bookingId) =>
      _sourceFor(V1Capability.bookingReview).reviewOrEligibility(bookingId);

  /// Whether a review may be left on [bookingId].
  ///
  /// Retained for the existing form controller, and now answered through the
  /// folded read — so it accounts for a review that already exists, which
  /// asking the eligibility route alone did not.
  Future<ReviewEligibility> getEligibility(String bookingId) async {
    final result = await reviewOrEligibility(bookingId);
    return result.eligibility ??
        // A booking that already has a review is not eligible for another, and
        // the canonical payload expresses that by sending the review instead of
        // a verdict. Synthesising the refusal here keeps the existing caller
        // working without teaching it the new shape.
        ReviewEligibility(
          bookingId: bookingId,
          eligible: false,
          reason: 'ALREADY_REVIEWED',
          reviewId: result.review?.reviewId,
        );
  }

  /// The review on [bookingId], or null.
  Future<ServanaReview?> getByBooking(String bookingId) async =>
      (await reviewOrEligibility(bookingId)).review;

  Future<ServanaReview> createReview(ReviewDraft draft) =>
      _sourceFor(V1Capability.bookingReview).createReview(draft);

  Future<ReviewAggregate> getProviderAggregate(String providerUid) =>
      _sourceFor(V1Capability.providerReputation).providerAggregate(providerUid);

  // ── Always legacy: no canonical successor ─────────────────────────────────

  /// Reads a review by its own id. No canonical successor (R-11).
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

  /// Edits a review. No canonical successor (R-11).
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

  /// Deletes a review. No canonical successor (R-11).
  Future<void> deleteReview(String reviewId) async {
    await _api.deleteReview(reviewId);
  }

  /// The caller's own reviews. No canonical successor (R-11).
  Future<List<ServanaReview>> listMyReviews() async {
    final res = await _api.listMyReviews();
    final list = (res['reviews'] ?? res['data']) as List? ?? [];
    return list.map((e) => ServanaReview.fromMap(_map(e))).toList();
  }

  /// Reports a review for moderation. No canonical successor (R-11).
  Future<void> reportReview({
    required String reviewId,
    required String reason,
    String? details,
  }) async {
    await _api.reportReview(
        reviewId: reviewId, reason: reason, details: details);
  }

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map<String, dynamic> ? v : <String, dynamic>{};
}
