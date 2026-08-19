/// Reviews over `/api/v1`.
///
/// ## Not reachable in any shipped build
///
/// Selected per capability — `bookingReview` for the booking's own review,
/// `providerReputation` for the aggregate rating.
///
/// ## What moving here buys
///
/// One round trip instead of two, and the race that came with the second. The
/// eligibility verdict is folded into the review read, so a screen cannot open
/// a form on a "yes" that the create then refuses.
library;

import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/review/data/reviews_data_source.dart';
import 'package:client/modules/review/domain/review_aggregate.dart';
import 'package:client/modules/review/domain/review_draft.dart';
import 'package:client/modules/review/domain/review_or_eligibility.dart';
import 'package:client/modules/review/domain/servana_review.dart';

class ReviewsCanonicalDataSource implements ReviewsDataSource {
  const ReviewsCanonicalDataSource(this._api);

  final V1ApiClient _api;

  @override
  Future<ReviewOrEligibility> reviewOrEligibility(String bookingId) async {
    final envelope = await _api.get(V1Endpoints.bookingReview(bookingId));
    return ReviewOrEligibility.fromApiMap(envelope.asMap);
  }

  @override
  Future<ServanaReview> createReview(ReviewDraft draft) async {
    final envelope = await _api.post(
      V1Endpoints.bookingReview(draft.bookingId),
      body: <String, dynamic>{
        'overallRating': draft.overallRating,
        'dimensions': draft.dimensions,
        if (draft.publicComment.trim().isNotEmpty)
          'publicComment': draft.publicComment.trim(),
        if (draft.privateFeedback.trim().isNotEmpty)
          'privateFeedback': draft.privateFeedback.trim(),
        'visibility': draft.visibility.apiValue,
        // The client-generated request id, as on the legacy route. It is the
        // review's own idempotency handle and travels in the body, so no
        // Idempotency-Key header is sent — the same distinction TAB 13 drew
        // for a message's clientMsgId.
        'clientRequestId': draft.clientRequestId,
      },
    );
    return ServanaReview.fromMap(envelope.asMap);
  }

  @override
  Future<ReviewAggregate> providerAggregate(String providerUid) async {
    final envelope = await _api.get(V1Endpoints.providerRating(providerUid));
    return ReviewAggregate.fromMap(envelope.asMap);
  }
}
