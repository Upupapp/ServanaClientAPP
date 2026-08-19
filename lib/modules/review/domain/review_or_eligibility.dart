/// Either the caller's review for a booking, or the verdict on leaving one.
///
/// ## Why one type instead of two calls
///
/// The client asks two questions today, from two controllers, and never both:
/// `ReviewFormController` asks `getEligibility` to decide whether to show the
/// form, and `ReviewDetailController` asks `getByBooking` to show an existing
/// review. Neither knows what the other would have learned.
///
/// The backend folded them, and said why:
///
/// > A SECOND call the client makes to decide whether to show the form. Folded
/// > into the read above, because asking twice means a screen that offers a
/// > form the next call refuses.
///
/// The race is real: eligibility is computed at one instant and the create is
/// validated at another, so a form opened on a stale "yes" is refused on
/// submit — after the customer has typed a review.
///
/// One question, one answer. *"Exactly one of the two is non-null."*
library;

import 'package:client/modules/review/domain/review_eligibility.dart';
import 'package:client/modules/review/domain/servana_review.dart';

class ReviewOrEligibility {
  /// Neither known. Reachable only from a contract break — see [fromApiMap].
  const ReviewOrEligibility._indeterminate()
      : review = null,
        eligibility = null;

  /// The booking already has a review by this caller.
  const ReviewOrEligibility.reviewed(ServanaReview this.review)
      : eligibility = null;

  /// There is no review yet; [eligibility] says whether one may be left.
  const ReviewOrEligibility.notReviewed(ReviewEligibility this.eligibility)
      : review = null;

  final ServanaReview? review;
  final ReviewEligibility? eligibility;

  bool get hasReview => review != null;

  /// True only when there is no review AND the backend permits one.
  ///
  /// An existing review makes this false without consulting [eligibility]:
  /// the backend's verdict for an already-reviewed booking is "not eligible",
  /// and a caller that checked eligibility alone would reach the same answer
  /// by a longer route. Stating it here keeps a screen from having to.
  bool get canLeaveReview => review == null && (eligibility?.eligible ?? false);

  static ReviewOrEligibility fromApiMap(Map<String, dynamic> json) {
    final rawReview = json['review'];
    if (rawReview is Map) {
      return ReviewOrEligibility.reviewed(
        ServanaReview.fromMap(Map<String, dynamic>.from(rawReview)),
      );
    }

    final rawEligibility = json['eligibility'];
    if (rawEligibility is Map) {
      return ReviewOrEligibility.notReviewed(
        ReviewEligibility.fromMap(Map<String, dynamic>.from(rawEligibility)),
      );
    }

    // Neither present. The contract says exactly one always is, so this is a
    // contract break rather than a state — and the safe reading is "no review,
    // and we cannot say you may leave one", which shows nothing rather than
    // offering a form the create would refuse.
    return const ReviewOrEligibility._indeterminate();
  }

  /// Builds the folded answer from the two legacy calls.
  ///
  /// The ordering matters and is the whole point: an existing review WINS.
  /// The legacy eligibility route is a separate computation and can disagree
  /// with the review read — that disagreement is the race the canonical
  /// endpoint removes, and until it is enabled the client resolves it the same
  /// way the backend does, by treating a review that exists as decisive.
  static ReviewOrEligibility fromLegacyPair({
    required ServanaReview? review,
    required ReviewEligibility eligibility,
  }) =>
      review != null
          ? ReviewOrEligibility.reviewed(review)
          : ReviewOrEligibility.notReviewed(eligibility);
}
