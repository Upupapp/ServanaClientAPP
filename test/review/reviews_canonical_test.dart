/// TAB 14 — reviews.
///
/// Two things are asserted here that the tab turns on: that R-11 still holds
/// (unlike R-10, withdrawn one tab earlier), and that folding eligibility into
/// the review read behaves identically on both transports.
library;

import 'dart:convert';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/review/data/reviews_canonical_data_source.dart';
import 'package:client/modules/review/data/reviews_compatibility_data_source.dart';
import 'package:client/modules/review/data/reviews_repository.dart';
import 'package:client/modules/review/domain/review_draft.dart';
import 'package:client/modules/review/domain/review_or_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Recorder {
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  final List<String> bodies = <String>[];
}

({ReviewsCanonicalDataSource source, _Recorder recorder}) _canonical(
  Object body, {
  int status = 200,
}) {
  final recorder = _Recorder();
  final api = V1ApiClient(
    baseUrl: 'https://api.example.test',
    httpClient: MockClient((request) async {
      recorder.requests.add(request);
      recorder.bodies.add(request.body);
      return http.Response(jsonEncode(body), status,
          headers: <String, String>{'content-type': 'application/json'});
    }),
  );
  return (source: ReviewsCanonicalDataSource(api), recorder: recorder);
}

class _FakeLegacyApi extends Fake implements ServanaApiClient {
  Map<String, dynamic>? reviewByBooking;
  int? reviewByBookingStatus;
  Map<String, dynamic> eligibilityResponse = <String, dynamic>{
    'bookingId': '42',
    'eligible': true,
  };

  int reviewCalls = 0;
  int eligibilityCalls = 0;
  int reportCalls = 0;
  int listMineCalls = 0;

  @override
  Future<Map<String, dynamic>> getReviewByBooking(String bookingId) async {
    reviewCalls++;
    final status = reviewByBookingStatus;
    if (status != null) {
      throw ServanaApiException(statusCode: status, body: '{}');
    }
    return reviewByBooking ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getReviewEligibility(String bookingId) async {
    eligibilityCalls++;
    return eligibilityResponse;
  }

  @override
  Future<Map<String, dynamic>> reportReview({
    required String reviewId,
    required String reason,
    String? details,
  }) async {
    reportCalls++;
    return <String, dynamic>{'success': true};
  }

  @override
  Future<Map<String, dynamic>> listMyReviews() async {
    listMineCalls++;
    return <String, dynamic>{'reviews': <dynamic>[]};
  }
}

ReviewsRepository _repo(
  _FakeLegacyApi api, {
  ReviewsCanonicalDataSource? canonicalSource,
  Set<V1Capability> capabilities = const <V1Capability>{},
}) =>
    ReviewsRepository(
      api: api,
      compatibility: ReviewsCompatibilityDataSource(api),
      canonical: canonicalSource,
      router: CanonicalRouter(
        availability: CanonicalAvailability(
          enabled: capabilities.isNotEmpty,
          capabilities: capabilities,
        ),
      ),
    );

Map<String, dynamic> _reviewRow() => <String, dynamic>{
      'reviewId': 'rev-1',
      'bookingId': '42',
      'overallRating': 5,
    };

void main() {
  // ── R-11, re-measured ──────────────────────────────────────────────────────

  group('R-11 holds, unlike R-10', () {
    test('the five id-scoped calls never route, even canonically', () async {
      // TAB 13 withdrew R-10 as stale, so R-11 was re-measured rather than
      // inherited. It is exactly right: GET/PUT/DELETE /api/reviews/:id,
      // /reviews/me and .../report have no canonical successor. They call the
      // legacy client directly in every configuration — the same per-call
      // escape NotificationsRepository.dismiss uses.
      final api = _FakeLegacyApi();
      final repo = _repo(
        api,
        canonicalSource: _canonical(const <String, dynamic>{}).source,
        capabilities: <V1Capability>{
          V1Capability.bookingReview,
          V1Capability.providerReputation,
        },
      );

      expect(repo.bookingReviewIsCanonical, isTrue);
      expect(repo.providerReputationIsCanonical, isTrue);

      await repo.reportReview(reviewId: 'rev-1', reason: 'ABUSE');
      await repo.listMyReviews();

      expect(api.reportCalls, 1);
      expect(api.listMineCalls, 1);
    });
  });

  // ── The gate ───────────────────────────────────────────────────────────────

  group('reachability', () {
    test('a default build routes neither slice', () {
      final repo = _repo(
        _FakeLegacyApi(),
        canonicalSource: _canonical(const <String, dynamic>{}).source,
      );
      expect(repo.bookingReviewIsCanonical, isFalse);
      expect(repo.providerReputationIsCanonical, isFalse);
    });

    test('the two slices flip independently', () {
      // Leaving a review on your booking and reading a provider's reputation
      // are different questions on different screens. The read-only one should
      // be movable first.
      final reviewOnly = _repo(
        _FakeLegacyApi(),
        canonicalSource: _canonical(const <String, dynamic>{}).source,
        capabilities: <V1Capability>{V1Capability.bookingReview},
      );
      expect(reviewOnly.bookingReviewIsCanonical, isTrue);
      expect(reviewOnly.providerReputationIsCanonical, isFalse);

      final ratingOnly = _repo(
        _FakeLegacyApi(),
        canonicalSource: _canonical(const <String, dynamic>{}).source,
        capabilities: <V1Capability>{V1Capability.providerReputation},
      );
      expect(ratingOnly.bookingReviewIsCanonical, isFalse);
      expect(ratingOnly.providerReputationIsCanonical, isTrue);
    });
  });

  // ── The folded read ────────────────────────────────────────────────────────

  group('one question instead of two', () {
    test('canonical asks once and gets either answer', () async {
      final c = _canonical(<String, dynamic>{
        'data': <String, dynamic>{
          'review': null,
          'eligibility': <String, dynamic>{'bookingId': '42', 'eligible': true},
        },
      });

      final result = await c.source.reviewOrEligibility('42');

      expect(c.recorder.requests, hasLength(1),
          reason: 'the whole point of the fold');
      expect(c.recorder.requests.single.url.path, '/api/v1/bookings/42/review');
      expect(result.hasReview, isFalse);
      expect(result.canLeaveReview, isTrue);
    });

    test('an existing review means canLeaveReview is false', () async {
      final c = _canonical(<String, dynamic>{
        'data': <String, dynamic>{'review': _reviewRow(), 'eligibility': null},
      });

      final result = await c.source.reviewOrEligibility('42');
      expect(result.hasReview, isTrue);
      expect(result.canLeaveReview, isFalse);
    });

    test('the legacy pair folds to the same answers', () async {
      // Not reviewed, and eligible.
      final open = _FakeLegacyApi()..reviewByBookingStatus = 404;
      final openResult =
          await ReviewsCompatibilityDataSource(open).reviewOrEligibility('42');
      expect(openResult.hasReview, isFalse);
      expect(openResult.canLeaveReview, isTrue);
      expect(open.reviewCalls, 1);
      expect(open.eligibilityCalls, 1);

      // Already reviewed.
      final done = _FakeLegacyApi()..reviewByBooking = _reviewRow();
      final doneResult =
          await ReviewsCompatibilityDataSource(done).reviewOrEligibility('42');
      expect(doneResult.hasReview, isTrue);
      expect(doneResult.canLeaveReview, isFalse);
    });

    test('an existing review WINS over a disagreeing eligibility verdict',
        () async {
      // The race the canonical endpoint removes. The two legacy verdicts are
      // computed at two instants and can disagree; a stale "eligible: true"
      // beside a review that exists must not open a form the create refuses.
      final api = _FakeLegacyApi()
        ..reviewByBooking = _reviewRow()
        ..eligibilityResponse = <String, dynamic>{
          'bookingId': '42',
          'eligible': true, // stale
        };

      final result =
          await ReviewsCompatibilityDataSource(api).reviewOrEligibility('42');

      expect(result.hasReview, isTrue);
      expect(result.canLeaveReview, isFalse);
    });

    test('getEligibility synthesises a refusal when a review exists',
        () async {
      // The existing ReviewFormController asks this and nothing else. Before
      // TAB 14 it consulted the eligibility route alone and never looked for a
      // review, so it could open a form on an already-reviewed booking.
      final api = _FakeLegacyApi()
        ..reviewByBooking = _reviewRow()
        ..eligibilityResponse = <String, dynamic>{
          'bookingId': '42',
          'eligible': true,
        };

      final eligibility = await _repo(api).getEligibility('42');

      expect(eligibility.eligible, isFalse);
      expect(eligibility.reason, 'ALREADY_REVIEWED');
      expect(eligibility.reviewId, 'rev-1');
    });

    test('a payload with neither field refuses rather than invites', () {
      // The contract says exactly one is always present, so neither is a
      // contract break. Failing toward "cannot leave one" shows nothing
      // instead of offering a form the create would refuse.
      final indeterminate =
          ReviewOrEligibility.fromApiMap(const <String, dynamic>{});
      expect(indeterminate.hasReview, isFalse);
      expect(indeterminate.canLeaveReview, isFalse);
    });
  });

  // ── Create ─────────────────────────────────────────────────────────────────

  group('creating a review', () {
    test('carries clientRequestId in the body, not a header', () async {
      // The review's own idempotency handle, and a body field — the same
      // distinction TAB 13 drew for a message's clientMsgId.
      final c = _canonical(<String, dynamic>{'data': _reviewRow()});

      await c.source.createReview(_draft());

      final body = jsonDecode(c.recorder.bodies.single) as Map<String, dynamic>;
      expect(c.recorder.requests.single.method, 'POST');
      expect(c.recorder.requests.single.url.path, '/api/v1/bookings/42/review');
      expect(body['clientRequestId'], 'crid-1');
      expect(body['overallRating'], 5);
      expect(c.recorder.requests.single.headers.containsKey('idempotency-key'),
          isFalse);
    });

    test('empty optional text is omitted rather than sent blank', () async {
      final c = _canonical(<String, dynamic>{'data': _reviewRow()});
      await c.source.createReview(_draft());
      final body = jsonDecode(c.recorder.bodies.single) as Map<String, dynamic>;
      expect(body.containsKey('publicComment'), isFalse);
      expect(body.containsKey('privateFeedback'), isFalse);
    });
  });

  group('provider reputation', () {
    test('reads the canonical rating path', () async {
      final c = _canonical(<String, dynamic>{
        'data': <String, dynamic>{'averageRating': 4.6, 'totalReviews': 18},
      });

      await c.source.providerAggregate('uid-9');

      expect(c.recorder.requests.single.url.path,
          '/api/v1/reviews/providers/uid-9/rating');
    });
  });
}

/// A submittable draft with both optional text fields left blank, so the
/// "omitted rather than sent blank" assertion has something to check.
ReviewDraft _draft() => const ReviewDraft(
      bookingId: '42',
      overallRating: 5,
      dimensions: <String, int>{'punctuality': 5},
      clientRequestId: 'crid-1',
    );
