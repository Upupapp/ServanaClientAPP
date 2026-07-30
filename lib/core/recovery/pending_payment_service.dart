import 'package:client/core/recovery/draft_repository.dart';
import 'package:flutter/foundation.dart';

/// Holds a pending payment context loaded at session restore (STITCH B2).
///
/// Set by [AuthenticationBloc._onCheckSession] when a non-expired
/// [PendingPaymentContext] is found for the authenticated user.
/// Consumed once by the UI so the resume prompt fires exactly once per session.
class PendingPaymentService extends ChangeNotifier {
  PendingPaymentContext? _pending;

  PendingPaymentContext? get pending => _pending;
  bool get hasPending => _pending != null;

  void setPending(PendingPaymentContext ctx) {
    _pending = ctx;
    notifyListeners();
  }

  /// Returns and clears the pending context.
  /// Call once from the UI — subsequent calls return null.
  PendingPaymentContext? consume() {
    final ctx = _pending;
    _pending = null;
    notifyListeners();
    return ctx;
  }

  void clear() {
    if (_pending == null) return;
    _pending = null;
    notifyListeners();
  }
}
