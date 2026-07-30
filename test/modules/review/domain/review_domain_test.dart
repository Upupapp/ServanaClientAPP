import 'package:client/modules/review/domain/review_aggregate.dart';
import 'package:client/modules/review/domain/review_dimension.dart';
import 'package:client/modules/review/domain/review_draft.dart';
import 'package:client/modules/review/domain/review_eligibility.dart';
import 'package:client/modules/review/domain/review_moderation_status.dart';
import 'package:client/modules/review/domain/review_visibility.dart';
import 'package:client/modules/review/domain/servana_review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReviewVisibility', () {
    test('fromString maps correctly', () {
      expect(ReviewVisibility.fromString('PUBLIC'), ReviewVisibility.public);
      expect(ReviewVisibility.fromString('ANONYMOUS_PUBLIC'),
          ReviewVisibility.anonymousPublic);
      expect(ReviewVisibility.fromString('PRIVATE'), ReviewVisibility.private);
      expect(ReviewVisibility.fromString(null), ReviewVisibility.public);
      expect(ReviewVisibility.fromString('UNKNOWN'), ReviewVisibility.public);
    });

    test('apiValue round-trips', () {
      for (final v in ReviewVisibility.values) {
        expect(ReviewVisibility.fromString(v.apiValue), v);
      }
    });
  });

  group('ReviewModerationStatus', () {
    test('fromString maps correctly', () {
      expect(ReviewModerationStatus.fromString('PENDING'),
          ReviewModerationStatus.pending);
      expect(ReviewModerationStatus.fromString('APPROVED'),
          ReviewModerationStatus.approved);
      expect(ReviewModerationStatus.fromString('FLAGGED'),
          ReviewModerationStatus.flagged);
      expect(ReviewModerationStatus.fromString(null),
          ReviewModerationStatus.notRequired);
    });

    test('isVisible is true for notRequired and approved only', () {
      expect(ReviewModerationStatus.notRequired.isVisible, isTrue);
      expect(ReviewModerationStatus.approved.isVisible, isTrue);
      expect(ReviewModerationStatus.pending.isVisible, isFalse);
      expect(ReviewModerationStatus.removed.isVisible, isFalse);
    });

    test('isSuppressed is true for hidden/removed/rejected', () {
      expect(ReviewModerationStatus.hidden.isSuppressed, isTrue);
      expect(ReviewModerationStatus.removed.isSuppressed, isTrue);
      expect(ReviewModerationStatus.rejected.isSuppressed, isTrue);
      expect(ReviewModerationStatus.approved.isSuppressed, isFalse);
    });
  });

  group('ReviewDimensionScore', () {
    test('labelFor returns a non-empty string for all known keys', () {
      for (final key in [
        'SERVICE_QUALITY',
        'PROFESSIONALISM',
        'PUNCTUALITY',
        'COMMUNICATION',
        'VALUE',
        'CLEANLINESS',
        'ACCURACY'
      ]) {
        expect(ReviewDimensionScore.labelFor(key), isNotEmpty);
      }
    });

    test('labelFor returns lowercased fallback for unknown key', () {
      expect(ReviewDimensionScore.labelFor('UNKNOWN_KEY'), 'unknown key');
    });

    test('fromMap parses correctly', () {
      final score = ReviewDimensionScore.fromMap({
        'dimensionKey': 'PUNCTUALITY',
        'score': 4,
      });
      expect(score.dimensionKey, 'PUNCTUALITY');
      expect(score.score, 4);
      expect(score.label, ReviewDimensionScore.labelFor('PUNCTUALITY'));
    });
  });

  group('ReviewDimensionSet', () {
    test('forCategory returns cleaning set for cleaning services', () {
      final dims = ReviewDimensionSet.forCategory('house cleaning');
      expect(dims, containsAll(['CLEANLINESS', 'SERVICE_QUALITY']));
    });

    test('forCategory returns installation set for repair', () {
      final dims = ReviewDimensionSet.forCategory('appliance repair');
      expect(dims, containsAll(['ACCURACY', 'SERVICE_QUALITY']));
    });

    test('forCategory returns general set for unknown', () {
      final dims = ReviewDimensionSet.forCategory(null);
      expect(dims, ReviewDimensionSet.general);
    });
  });

  group('ReviewDraft', () {
    test('initial state: unset rating', () {
      const draft = ReviewDraft(bookingId: 'b1');
      expect(draft.overallRating, 0);
      expect(draft.isRatingSet, isFalse);
      expect(draft.isSubmittable, isFalse);
    });

    test('copyWith overallRating makes it submittable', () {
      const draft = ReviewDraft(bookingId: 'b1');
      final updated = draft.copyWith(overallRating: 4);
      expect(updated.isRatingSet, isTrue);
      expect(updated.isSubmittable, isTrue);
    });

    test('setDimension merges without clobbering other keys', () {
      const draft = ReviewDraft(bookingId: 'b1', dimensions: {'A': 3});
      final updated = draft.setDimension('B', 5);
      expect(updated.dimensions['A'], 3);
      expect(updated.dimensions['B'], 5);
    });
  });

  group('ReviewEligibility', () {
    test('fromMap eligible=true', () {
      final e = ReviewEligibility.fromMap({
        'bookingId': 'bk1',
        'eligible': true,
        'reason': null,
        'reviewId': null,
        'availableActions': ['CREATE_REVIEW'],
        'reviewWindow': {
          'opensAt': '2026-07-01T00:00:00.000Z',
          'closesAt': '2026-07-15T00:00:00.000Z',
        },
      });
      expect(e.eligible, isTrue);
      expect(e.availableActions, contains('CREATE_REVIEW'));
      expect(e.hasReview, isFalse);
      expect(e.reviewWindowOpensAt, isNotNull);
    });

    test('fromMap with existing review', () {
      final e = ReviewEligibility.fromMap({
        'bookingId': 'bk1',
        'eligible': false,
        'reason': 'REVIEW_ALREADY_SUBMITTED',
        'reviewId': 'rv-abc',
        'availableActions': ['EDIT_REVIEW'],
        'editableUntil': '2026-07-03T10:00:00.000Z',
      });
      expect(e.eligible, isFalse);
      expect(e.hasReview, isTrue);
      expect(e.canEdit, isTrue);
      expect(e.canView, isFalse);
    });
  });

  group('ReviewAggregate', () {
    test('empty returns zero state', () {
      final agg = ReviewAggregate.empty('uid1');
      expect(agg.hasReviews, isFalse);
      expect(agg.averageRating, 0);
      expect(agg.displayRating, '');
    });

    test('fromMap parses distribution correctly', () {
      final agg = ReviewAggregate.fromMap({
        'providerUid': 'uid1',
        'averageRating': 4.5,
        'reviewCount': 20,
        'distribution': {'1': 0, '2': 1, '3': 2, '4': 7, '5': 10},
      });
      expect(agg.hasReviews, isTrue);
      expect(agg.averageRating, 4.5);
      expect(agg.distribution[5], 10);
      expect(agg.displayRating, '4.5');
    });

    test('fromMap fills missing distribution buckets with 0', () {
      final agg = ReviewAggregate.fromMap({
        'providerUid': 'uid1',
        'averageRating': 3.0,
        'reviewCount': 5,
        'distribution': {'5': 5},
      });
      expect(agg.distribution[1], 0);
      expect(agg.distribution[2], 0);
      expect(agg.distribution[5], 5);
    });
  });

  group('ServanaReview', () {
    Map<String, dynamic> makeReviewMap({
      String? visibility,
      String? moderationStatus,
    }) =>
        {
          'reviewId': 'rv-1',
          'bookingId': 'bk-1',
          'overallRating': 4,
          'publicComment': 'Great service',
          'visibility': visibility ?? 'PUBLIC',
          'moderationStatus': moderationStatus ?? 'NOT_REQUIRED',
          'dimensions': [
            {'dimensionKey': 'PUNCTUALITY', 'score': 5},
          ],
        };

    test('fromMap basic fields', () {
      final r = ServanaReview.fromMap(makeReviewMap());
      expect(r.reviewId, 'rv-1');
      expect(r.overallRating, 4);
      expect(r.publicComment, 'Great service');
      expect(r.visibility, ReviewVisibility.public);
      expect(r.moderationStatus, ReviewModerationStatus.notRequired);
      expect(r.dimensions, hasLength(1));
      expect(r.dimensions.first.dimensionKey, 'PUNCTUALITY');
    });

    test('isVisible delegates to moderationStatus', () {
      final visible = ServanaReview.fromMap(
          makeReviewMap(moderationStatus: 'NOT_REQUIRED'));
      final suppressed =
          ServanaReview.fromMap(makeReviewMap(moderationStatus: 'REMOVED'));
      expect(visible.isVisible, isTrue);
      expect(suppressed.isVisible, isFalse);
    });

    test('hasResponse is false when no providerResponse key', () {
      final r = ServanaReview.fromMap(makeReviewMap());
      expect(r.hasResponse, isFalse);
    });

    test('isEdited is false without editedAt', () {
      final r = ServanaReview.fromMap(makeReviewMap());
      expect(r.isEdited, isFalse);
    });

    test('isEdited is true with editedAt', () {
      final m = makeReviewMap()..['editedAt'] = '2026-07-10T12:00:00.000Z';
      final r = ServanaReview.fromMap(m);
      expect(r.isEdited, isTrue);
    });
  });
}
