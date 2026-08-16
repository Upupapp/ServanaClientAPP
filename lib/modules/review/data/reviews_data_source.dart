/// The contract both review transports satisfy.
///
///     ReviewsRepository
///       → ReviewsCanonicalDataSource      per capability
///       → ReviewsCompatibilityDataSource  otherwise
///
/// ## Four of nine, and R-11 was right
///
/// TAB 01's R-11 recorded reviews as a partial surface: *"9 review calls …
/// 4 have `ALIAS` successors; 5 (`GET/PUT/DELETE /api/reviews/:id`,
/// `/reviews/me`, `…/report`) are `KEEP`"*, and the manifest declined to define
/// a `reviews` capability because of it.
///
/// TAB 14 re-measured it — TAB 13 having just withdrawn R-10 as stale — and
/// **R-11 holds exactly**. The counts are precise:
///
/// | Client call | Canonical successor |
/// | --- | --- |
/// | `getEligibility` | `bookings.review.get` (folded in) |
/// | `getByBooking` | `bookings.review.get` |
/// | `createReview` | `bookings.review.create` |
/// | `getProviderAggregate` | `reviews.provider.rating` |
/// | `getById` | **none** |
/// | `editReview` | **none** |
/// | `deleteReview` | **none** |
/// | `listMyReviews` | **none** |
/// | `reportReview` | **none** |
///
/// So R-11's *conclusion* stands and its *remedy* was too blunt. The domain
/// cannot be named, but the four that migrate are a coherent slice and the five
/// that do not are the per-call escape this codebase has used since TAB 02.
/// Only the four appear here.
///
/// ## Two calls become one, and that closes a race
///
/// `bookings.review.get` returns `ReviewOrEligibility` — *"the caller's own
/// review for a booking, or the eligibility verdict when there is none"* — and
/// the contract names the client's current two-call habit as the reason:
///
/// > A SECOND call the client makes to decide whether to show the form. Folded
/// > into the read above, because asking twice means a screen that offers a
/// > form the next call refuses.
///
/// [reviewOrEligibility] is therefore ONE method, and the compatibility source
/// assembles the same shape from the two legacy calls.
library;

import 'package:client/modules/review/domain/review_aggregate.dart';
import 'package:client/modules/review/domain/review_draft.dart';
import 'package:client/modules/review/domain/review_or_eligibility.dart';
import 'package:client/modules/review/domain/servana_review.dart';

abstract interface class ReviewsDataSource {
  /// The caller's review for [bookingId], or the eligibility verdict when
  /// there is none. Exactly one of the two is present.
  Future<ReviewOrEligibility> reviewOrEligibility(String bookingId);

  /// Leaves a review.
  Future<ServanaReview> createReview(ReviewDraft draft);

  /// A provider's aggregate rating.
  Future<ReviewAggregate> providerAggregate(String providerUid);
}
