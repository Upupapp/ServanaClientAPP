import 'dart:io';

import 'package:client/modules/review/application/review_form_controller.dart';
import 'package:client/modules/review/data/reviews_repository.dart';
import 'package:client/modules/review/domain/review_draft.dart';
import 'package:client/modules/review/domain/review_eligibility.dart';
import 'package:client/modules/review/domain/review_moderation_status.dart';
import 'package:client/modules/review/domain/review_visibility.dart';
import 'package:client/modules/review/domain/servana_review.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockReviewsRepository extends Mock implements ReviewsRepository {}

class _FakeReviewDraft extends Fake implements ReviewDraft {}

late Directory _hiveDir;

void main() {
  setUpAll(() async {
    registerFallbackValue(_FakeReviewDraft());
    _hiveDir = await Directory.systemTemp.createTemp('hive_rv_test_');
    Hive.init(_hiveDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    try { await _hiveDir.delete(recursive: true); } catch (_) {}
  });

  late MockReviewsRepository repo;
  late ReviewFormController ctrl;

  ReviewEligibility makeEligible() => ReviewEligibility.fromMap({
    'bookingId': 'bk1',
    'eligible': true,
    'availableActions': ['CREATE_REVIEW'],
    'reviewWindow': {
      'opensAt': '2020-01-01T00:00:00.000Z',
      'closesAt': '2099-01-01T00:00:00.000Z',
    },
  });

  ReviewEligibility makeNotEligible(String reason) => ReviewEligibility.fromMap({
    'bookingId': 'bk1',
    'eligible': false,
    'reason': reason,
    'availableActions': [],
  });

  ServanaReview makeReview() => ServanaReview.fromMap({
    'reviewId':         'rv-1',
    'bookingId':        'bk1',
    'overallRating':    5,
    'visibility':       'PUBLIC',
    'moderationStatus': 'NOT_REQUIRED',
    'dimensions': [],
  });

  setUp(() {
    repo = MockReviewsRepository();
    ctrl = ReviewFormController(repository: repo);
  });

  tearDown(() => ctrl.dispose());

  test('initial status is idle', () {
    expect(ctrl.status, ReviewFormStatus.idle);
    expect(ctrl.draft, isNull);
    expect(ctrl.error, isNull);
  });

  test('loadEligibility → eligible sets status and creates draft', () async {
    when(() => repo.getEligibility('bk1'))
        .thenAnswer((_) async => makeEligible());

    await ctrl.loadEligibility('bk1');

    expect(ctrl.status, ReviewFormStatus.eligible);
    expect(ctrl.draft, isNotNull);
    expect(ctrl.draft!.bookingId, 'bk1');
    expect(ctrl.error, isNull);
  });

  test('loadEligibility → not eligible sets notEligible status', () async {
    when(() => repo.getEligibility('bk1'))
        .thenAnswer((_) async => makeNotEligible('REVIEW_WINDOW_EXPIRED'));

    await ctrl.loadEligibility('bk1');

    expect(ctrl.status, ReviewFormStatus.notEligible);
    expect(ctrl.draft, isNull);
  });

  test('loadEligibility → API error sets failed status', () async {
    when(() => repo.getEligibility('bk1'))
        .thenThrow(Exception('network error'));

    await ctrl.loadEligibility('bk1');

    expect(ctrl.status, ReviewFormStatus.failed);
    expect(ctrl.error, isNotNull);
  });

  test('setRating updates draft', () async {
    when(() => repo.getEligibility('bk1'))
        .thenAnswer((_) async => makeEligible());
    await ctrl.loadEligibility('bk1');

    ctrl.setRating(4);

    expect(ctrl.draft!.overallRating, 4);
    expect(ctrl.draft!.isRatingSet, isTrue);
  });

  test('setDimension updates draft dimensions', () async {
    when(() => repo.getEligibility('bk1'))
        .thenAnswer((_) async => makeEligible());
    await ctrl.loadEligibility('bk1');

    ctrl.setDimension('PUNCTUALITY', 5);

    expect(ctrl.draft!.dimensions['PUNCTUALITY'], 5);
  });

  test('setVisibility updates draft', () async {
    when(() => repo.getEligibility('bk1'))
        .thenAnswer((_) async => makeEligible());
    await ctrl.loadEligibility('bk1');

    ctrl.setVisibility(ReviewVisibility.anonymousPublic);

    expect(ctrl.draft!.visibility, ReviewVisibility.anonymousPublic);
  });

  test('submit fails when no rating is set', () async {
    when(() => repo.getEligibility('bk1'))
        .thenAnswer((_) async => makeEligible());
    await ctrl.loadEligibility('bk1');
    // draft has overallRating = 0

    final ok = await ctrl.submit();

    expect(ok, isFalse);
    expect(ctrl.error, isNotNull);
    verifyNever(() => repo.createReview(any()));
  });

  test('submit succeeds when rating is set', () async {
    when(() => repo.getEligibility('bk1'))
        .thenAnswer((_) async => makeEligible());
    when(() => repo.createReview(any()))
        .thenAnswer((_) async => makeReview());

    await ctrl.loadEligibility('bk1');
    ctrl.setRating(5);

    final ok = await ctrl.submit();

    expect(ok, isTrue);
    expect(ctrl.status, ReviewFormStatus.succeeded);
    expect(ctrl.submitted, isNotNull);
    expect(ctrl.submitted!.overallRating, 5);
  });

  test('submit sets failed on API error', () async {
    when(() => repo.getEligibility('bk1'))
        .thenAnswer((_) async => makeEligible());
    when(() => repo.createReview(any()))
        .thenThrow(Exception('server error'));

    await ctrl.loadEligibility('bk1');
    ctrl.setRating(3);

    final ok = await ctrl.submit();

    expect(ok, isFalse);
    expect(ctrl.status, ReviewFormStatus.failed);
    expect(ctrl.error, isNotNull);
  });

  test('reset clears all state', () async {
    when(() => repo.getEligibility('bk1'))
        .thenAnswer((_) async => makeEligible());
    await ctrl.loadEligibility('bk1');
    ctrl.setRating(4);

    ctrl.reset();

    expect(ctrl.status, ReviewFormStatus.idle);
    expect(ctrl.draft, isNull);
    expect(ctrl.error, isNull);
  });

  test('resetPrivateData delegates to reset', () async {
    when(() => repo.getEligibility('bk1'))
        .thenAnswer((_) async => makeEligible());
    await ctrl.loadEligibility('bk1');

    ctrl.resetPrivateData();

    expect(ctrl.status, ReviewFormStatus.idle);
    expect(ctrl.draft, isNull);
  });

  test('stale-generation discard: loadEligibility twice, only last wins', () async {
    var callCount = 0;
    when(() => repo.getEligibility('bk1')).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) {
        await Future.delayed(const Duration(milliseconds: 50));
        return makeNotEligible('BOOKING_NOT_COMPLETED');
      }
      return makeEligible();
    });

    // Both calls fire; the second finishes first (no delay).
    final f1 = ctrl.loadEligibility('bk1');
    final f2 = ctrl.loadEligibility('bk1');
    await Future.wait([f1, f2]);

    // Second call's result (eligible) wins because it incremented the generation.
    expect(ctrl.status, ReviewFormStatus.eligible);
  });

  test('review moderation status reflects not-required on fresh review', () {
    final r = makeReview();
    expect(r.moderationStatus, ReviewModerationStatus.notRequired);
    expect(r.isVisible, isTrue);
  });
}
