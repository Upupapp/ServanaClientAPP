/// Change orders and disputes on a booking.
///
///     BookingExperiencesRepository
///       → canonical      per capability
///       → compatibility  otherwise
///
/// ## Two capabilities, routed independently
///
/// [V1Capability.bookingAdditionalWork] and [V1Capability.bookingDisputes] are
/// separate switches over one repository, which is a shape none of the earlier
/// tabs needed. The reason is that the two halves are not comparable:
///
///  - the change-order read has a live legacy relative doing the same work, so
///    flipping it changes a URL;
///  - disputes have no customer route at all, so flipping that one turns on a
///    feature.
///
/// Putting them behind one flag would mean an operator could not take the safe
/// half first, which is the argument that separated `bookingReads` from
/// `bookingLifecycle` in TAB 10.
///
/// ## What is absent, and why it is absent rather than flagged
///
/// There is no `raiseAdditionalWork`. `bookings.additionalWork.create` is
/// `auth: 'provider'` with `customerMobile: 'n/a'` — the customer is not the
/// party who raises a change order, they are the party who approves one. That
/// is an authorization fact, not a transport gap, so it gets no `supports…`
/// flag: a flag implies a capability that could one day be true here, and this
/// one never will be.
library;

import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/booking_experiences/data/booking_experiences_data_source.dart';
import 'package:client/modules/booking_experiences/domain/additional_work.dart';
import 'package:client/modules/booking_experiences/domain/booking_dispute.dart';

class BookingExperiencesRepository {
  const BookingExperiencesRepository({
    required BookingExperiencesDataSource compatibility,
    BookingExperiencesDataSource? canonical,
    CanonicalRouter? router,
  })  : _compatibility = compatibility,
        _canonical = canonical,
        _router = router;

  final BookingExperiencesDataSource _compatibility;
  final BookingExperiencesDataSource? _canonical;
  final CanonicalRouter? _router;

  BookingExperiencesDataSource _sourceFor(V1Capability capability) {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _compatibility;
    return router.select<BookingExperiencesDataSource>(
      capability,
      canonical: canonical,
      compatibility: _compatibility,
    );
  }

  bool _isCanonical(V1Capability capability) =>
      _canonical != null && (_router?.isCanonical(capability) ?? false);

  /// True when change orders are read from `/api/v1`. Diagnostics only.
  bool get additionalWorkIsCanonical =>
      _isCanonical(V1Capability.bookingAdditionalWork);

  /// True when disputes are served by `/api/v1`. Diagnostics only.
  bool get disputesAreCanonical => _isCanonical(V1Capability.bookingDisputes);

  /// Whether a customer can raise an escalation at all on this transport.
  ///
  /// A UI must consult this before offering the action. False today on every
  /// build: the only legacy dispute route is admin-only.
  bool get canOpenDispute =>
      _sourceFor(V1Capability.bookingDisputes).supportsDisputes;

  /// The change orders on [bookingId], newest first as the backend orders them.
  ///
  /// Available on BOTH transports — the legacy route exists and the app had
  /// simply never called it.
  Future<List<AdditionalWorkRequest>> additionalWork(String bookingId) =>
      _sourceFor(V1Capability.bookingAdditionalWork).additionalWork(bookingId);

  /// The disputes on [bookingId], with the categories the server will accept.
  ///
  /// Throws [UnsupportedExperienceAction] when [canOpenDispute] is false.
  Future<BookingDisputes> disputes(String bookingId) =>
      _sourceFor(V1Capability.bookingDisputes).disputes(bookingId);

  /// Opens a dispute.
  ///
  /// No eligibility is evaluated here. Whether the booking is in a disputable
  /// state, whether one is already open and whether the category is recognised
  /// are all the backend's decisions, and each has a code of its own —
  /// `BOOKING_DISPUTE_NOT_ACTIONABLE`, `BOOKING_DISPUTE_ALREADY_OPEN`,
  /// `BOOKING_DISPUTE_CATEGORY_INVALID`.
  ///
  /// Throws [UnsupportedExperienceAction] when [canOpenDispute] is false.
  Future<BookingDisputes> openDispute({
    required String bookingId,
    required DisputeDraft draft,
  }) =>
      _sourceFor(V1Capability.bookingDisputes)
          .openDispute(bookingId: bookingId, draft: draft);
}
