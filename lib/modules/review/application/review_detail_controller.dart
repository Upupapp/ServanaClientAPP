import 'package:client/modules/review/data/reviews_repository.dart';
import 'package:client/modules/review/domain/servana_review.dart';
import 'package:flutter/foundation.dart';

enum ReviewDetailStatus { idle, loading, loaded, reporting, error }

class ReviewDetailController extends ChangeNotifier {
  ReviewDetailController({required ReviewsRepository repository})
      : _repo = repository;

  final ReviewsRepository _repo;

  bool _disposed = false;
  int _generation = 0;

  ReviewDetailStatus _status = ReviewDetailStatus.idle;
  ServanaReview? _review;
  String? _error;
  bool _reportSubmitted = false;

  ReviewDetailStatus get status => _status;
  ServanaReview? get review => _review;
  String? get error => _error;
  bool get reportSubmitted => _reportSubmitted;
  bool get isLoading => _status == ReviewDetailStatus.loading;

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadByBooking(String bookingId) async {
    _begin();
    final gen = ++_generation;
    try {
      final r = await _repo.getByBooking(bookingId);
      if (_disposed || gen != _generation) return;
      _review = r;
      _status = ReviewDetailStatus.loaded;
      _notify();
    } catch (e) {
      if (_disposed || gen != _generation) return;
      _status = ReviewDetailStatus.error;
      _error = _sanitize(e);
      _notify();
    }
  }

  Future<void> loadById(String reviewId) async {
    _begin();
    final gen = ++_generation;
    try {
      final r = await _repo.getById(reviewId);
      if (_disposed || gen != _generation) return;
      _review = r;
      _status = ReviewDetailStatus.loaded;
      _notify();
    } catch (e) {
      if (_disposed || gen != _generation) return;
      _status = ReviewDetailStatus.error;
      _error = _sanitize(e);
      _notify();
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<bool> deleteReview() async {
    final r = _review;
    if (r == null) return false;
    try {
      await _repo.deleteReview(r.reviewId);
      _review = null;
      _notify();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Report ───────────────────────────────────────────────────────────────

  Future<bool> reportReview({required String reason, String? details}) async {
    final r = _review;
    if (r == null) return false;
    _status = ReviewDetailStatus.reporting;
    _notify();

    final gen = ++_generation;
    try {
      await _repo.reportReview(
          reviewId: r.reviewId, reason: reason, details: details);
      if (_disposed || gen != _generation) return false;
      _reportSubmitted = true;
      _status = ReviewDetailStatus.loaded;
      _notify();
      return true;
    } catch (e) {
      if (_disposed || gen != _generation) return false;
      _status = ReviewDetailStatus.loaded;
      _error = 'Could not submit report. Please try again.';
      _notify();
      return false;
    }
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  void resetPrivateData() {
    ++_generation;
    _status = ReviewDetailStatus.idle;
    _review = null;
    _error = null;
    _reportSubmitted = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _begin() {
    _status = ReviewDetailStatus.loading;
    _error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _sanitize(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401')) return 'Session expired. Please sign in again.';
    if (msg.contains('network') || msg.contains('socket')) {
      return 'No internet connection.';
    }
    return 'Could not load review. Please try again.';
  }
}
