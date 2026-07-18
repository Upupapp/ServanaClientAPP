import 'package:client/common/domain/booking/booking_draft.dart';

/// In-memory singleton that holds the active booking draft across the auth
/// gate flow. Not persisted — survives only within the current process.
///
/// Lifecycle:
///   1. Booking flow sets draft via [save].
///   2. Guest hits a protected action → auth gate opens.
///   3. Auth succeeds → caller calls [consume] to get the draft back.
///   4. On successful booking, call [clear].
///   5. On account switch, [clear] is called during logout to prevent
///      cross-account draft leakage.
class BookingDraftService {
  BookingDraft? _draft;

  BookingDraft? get current => _draft?.isExpired == true ? null : _draft;

  bool get hasDraft => current != null;

  void save(BookingDraft draft) {
    _draft = draft.copyWith(status: BookingDraftStatus.authenticationRequired);
  }

  /// Returns and retains the draft (marking it restored), or null if expired.
  BookingDraft? restore() {
    if (_draft == null) return null;
    if (_draft!.isExpired) {
      _draft = null;
      return null;
    }
    _draft = _draft!.copyWith(status: BookingDraftStatus.restored);
    return _draft;
  }

  /// Fully consumes the draft. Call after booking is submitted.
  void clear() => _draft = null;
}
