import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/modules/review/data/reviews_repository.dart';
import 'package:client/modules/review/domain/review_dimension.dart';
import 'package:client/modules/review/domain/review_draft.dart';
import 'package:client/modules/review/domain/review_eligibility.dart';
import 'package:client/modules/review/domain/review_visibility.dart';
import 'package:client/modules/review/domain/servana_review.dart';
import 'package:flutter/foundation.dart';

enum ReviewFormStatus { idle, loadingEligibility, eligible, notEligible, submitting, succeeded, failed }

class ReviewFormController extends ChangeNotifier {
  ReviewFormController({required ReviewsRepository repository}) : _repo = repository;

  final ReviewsRepository _repo;

  bool _disposed = false;
  int _generation = 0;

  ReviewFormStatus _status  = ReviewFormStatus.idle;
  ReviewEligibility? _eligibility;
  ReviewDraft? _draft;
  ServanaReview? _submitted;
  String? _error;
  List<String> _dimensionKeys = ReviewDimensionSet.general;

  ReviewFormStatus   get status       => _status;
  ReviewEligibility? get eligibility  => _eligibility;
  ReviewDraft?       get draft        => _draft;
  ServanaReview?     get submitted    => _submitted;
  String?            get error        => _error;
  List<String>       get dimensionKeys => _dimensionKeys;
  bool               get isSubmitting => _status == ReviewFormStatus.submitting;

  // ─── Eligibility check ────────────────────────────────────────────────────

  Future<void> loadEligibility(String bookingId, {String? serviceCategory}) async {
    _status = ReviewFormStatus.loadingEligibility;
    _error  = null;
    _eligibility = null;
    _submitted   = null;
    _notify();

    final gen = ++_generation;
    try {
      final eligibility = await _repo.getEligibility(bookingId);
      if (_disposed || gen != _generation) return;

      _eligibility = eligibility;
      _dimensionKeys = ReviewDimensionSet.forCategory(serviceCategory);

      if (eligibility.eligible) {
        _draft = ReviewDraft(
          bookingId:       bookingId,
          clientRequestId: await _buildClientRequestId(bookingId),
        );
        _status = ReviewFormStatus.eligible;
      } else {
        _status = ReviewFormStatus.notEligible;
      }
      _notify();
    } catch (e) {
      if (_disposed || gen != _generation) return;
      _status = ReviewFormStatus.failed;
      _error  = _sanitize(e);
      _notify();
    }
  }

  // ─── Draft mutation ───────────────────────────────────────────────────────

  void setRating(int rating) {
    assert(rating >= 1 && rating <= 5);
    _draft = _draft?.copyWith(overallRating: rating);
    _notify();
  }

  void setDimension(String key, int score) {
    _draft = _draft?.setDimension(key, score);
    _notify();
  }

  void setPublicComment(String v) {
    _draft = _draft?.copyWith(publicComment: v);
    _notify();
  }

  void setPrivateFeedback(String v) {
    _draft = _draft?.copyWith(privateFeedback: v);
    _notify();
  }

  void setVisibility(ReviewVisibility v) {
    _draft = _draft?.copyWith(visibility: v);
    _notify();
  }

  // ─── Submission ───────────────────────────────────────────────────────────

  Future<bool> submit() async {
    final d = _draft;
    if (d == null || !d.isSubmittable) {
      _error = 'Please select a rating before submitting.';
      _notify();
      return false;
    }

    _status = ReviewFormStatus.submitting;
    _error  = null;
    _notify();

    final gen = ++_generation;
    try {
      final review = await _repo.createReview(d);
      if (_disposed || gen != _generation) return false;
      _submitted = review;
      _status    = ReviewFormStatus.succeeded;
      _notify();
      return true;
    } catch (e) {
      if (_disposed || gen != _generation) return false;
      _status = ReviewFormStatus.failed;
      _error  = _sanitize(e);
      _notify();
      return false;
    }
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  void reset() {
    _status      = ReviewFormStatus.idle;
    _eligibility = null;
    _draft       = null;
    _submitted   = null;
    _error       = null;
    _notify();
  }

  void resetPrivateData() => reset();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<String?> _buildClientRequestId(String bookingId) async {
    try {
      final session = await SessionService.getSession();
      final uid = session?.customerID ?? '';
      final prefix = uid.length > 6 ? uid.substring(0, 6) : uid;
      return 'rv-$prefix-${bookingId.hashCode.abs()}';
    } catch (_) {
      return 'rv-${bookingId.hashCode.abs()}';
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _sanitize(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('session')) {
      return 'Session expired. Please sign in again.';
    }
    if (msg.contains('duplicate') || msg.contains('409') || msg.contains('already')) {
      return 'You\'ve already reviewed this booking.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'No internet connection. Please try again.';
    }
    if (msg.contains('window') || msg.contains('expired')) {
      return 'The review window for this booking has closed.';
    }
    return 'Could not submit your review. Please try again.';
  }
}
