/// The contract both change-order and dispute transports satisfy.
///
///     BookingExperiencesRepository
///       → BookingExperiencesCanonicalDataSource      per capability
///       → BookingExperiencesCompatibilityDataSource  otherwise
///
/// ## Two gaps, and they are different KINDS of gap
///
/// Earlier tabs met one shape of absence: the legacy transport lacks something
/// the canonical one has. Reschedule (TAB 10) and customer refunds (TAB 11)
/// were both that, and both are reported through a `supports…` flag.
/// [supportsDisputes] is a third instance — the only legacy way to open a
/// dispute is `POST /api/admin/bookings/:id/escalate`, admin-only.
///
/// **Raising a change order is not that shape.** There is nothing missing.
/// `bookings.additionalWork.create` is `implemented`, has a live legacy alias,
/// and works — for a **provider**. Its contract says `auth: 'provider'` and
/// `customerMobile: 'n/a'`, and the write *"requires an IN_PROGRESS assignment
/// row held under FOR UPDATE"*, which a customer does not have.
///
/// So it is absent from this interface entirely, with no flag and no method.
/// A flag would imply a capability that could one day be true for this client
/// and it never will be — the customer is not a party to raising a change
/// order against their own booking, they are the party who approves one. An
/// endpoint this actor may never call is not a gap to report; it is a method
/// that should not exist here, in the same way `NotificationsDataSource` has
/// no `dismiss` and for a stronger reason.
library;

import 'package:client/modules/booking_experiences/domain/additional_work.dart';
import 'package:client/modules/booking_experiences/domain/booking_dispute.dart';

/// Thrown when a caller invokes an operation the active transport does not
/// have. An `Error`: no request was made and nothing was refused.
class UnsupportedExperienceAction extends UnsupportedError {
  UnsupportedExperienceAction(String action)
      : super('$action is not available on the legacy transport. '
            'Check the supports flag before offering it.');
}

abstract interface class BookingExperiencesDataSource {
  /// Whether a customer can open a dispute on this transport.
  bool get supportsDisputes;

  /// The change orders on this booking.
  ///
  /// A read, and the only additional-work operation a customer client has.
  Future<List<AdditionalWorkRequest>> additionalWork(String bookingId);

  /// The disputes on this booking, together with the categories the server
  /// will accept for a new one.
  ///
  /// The categories travel with the list deliberately: one call both renders
  /// the existing escalations and supplies the vocabulary for opening another,
  /// so no client holds its own copy of `DISPUTE_CATEGORIES`.
  ///
  /// Throws [UnsupportedExperienceAction] when [supportsDisputes] is false.
  Future<BookingDisputes> disputes(String bookingId);

  /// Opens a dispute.
  ///
  /// At most one unresolved escalation exists per booking, enforced by a
  /// partial unique index as well as by policy — so a duplicate is refused
  /// with `BOOKING_DISPUTE_ALREADY_OPEN` rather than producing a second record.
  ///
  /// Throws [UnsupportedExperienceAction] when [supportsDisputes] is false.
  Future<BookingDisputes> openDispute({
    required String bookingId,
    required DisputeDraft draft,
  });
}
