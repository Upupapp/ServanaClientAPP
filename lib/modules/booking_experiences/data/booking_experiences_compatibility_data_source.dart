/// Change orders and disputes on the legacy transport.
///
/// ## Change orders: the route exists and the app never called it
///
/// `GET /api/additional/booking/:bookingId` has been live throughout, is
/// already booking-scoped, and is served by the same `additionalService` the
/// canonical path uses. The customer app simply had no surface for change
/// orders — the only "additional" screen in the codebase,
/// `AddAdditionalItemMenuScreen`, belongs to the MerchantMenu subtree and picks
/// store items, which is an unrelated model.
///
/// So this is not a migration of an existing call. It is a call the app should
/// have been making, added on the transport that already had it, so the feature
/// does not have to wait for a v1 deploy it does not need.
///
/// ## Disputes: nothing to call
///
/// The only legacy way to open one is `POST /api/admin/bookings/:id/escalate`,
/// admin-only, which a customer token cannot use. The other legacy entry is a
/// provider-facing eligibility read. Neither is reachable from here, so
/// [supportsDisputes] is false and both dispute methods throw a programming
/// error rather than a customer-facing one.
///
/// Reporting an empty category list would be worse than throwing: a screen
/// would render a picker with no options and no explanation.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/booking_experiences/data/booking_experiences_data_source.dart';
import 'package:client/modules/booking_experiences/domain/additional_work.dart';
import 'package:client/modules/booking_experiences/domain/booking_dispute.dart';

class BookingExperiencesCompatibilityDataSource
    implements BookingExperiencesDataSource {
  const BookingExperiencesCompatibilityDataSource(this._api);

  final ServanaApiClient _api;

  @override
  bool get supportsDisputes => false;

  @override
  Future<List<AdditionalWorkRequest>> additionalWork(String bookingId) async {
    final result = await _api.getBookingAdditionalWork(int.parse(bookingId));

    // `data` or `requests` or the root. The same tolerance every other
    // compatibility source in this repo carries, and for the same reason: a
    // released binary outlives a deploy in both directions, and a booking with
    // no change orders must render as empty rather than throw.
    final raw = result['data'] ?? result['requests'] ?? result['additional'];
    if (raw is! List) return const <AdditionalWorkRequest>[];

    return raw
        .whereType<Map>()
        .map((e) => AdditionalWorkRequest.fromApiMap(
            Map<String, dynamic>.from(e),
            bookingId: bookingId))
        .toList(growable: false);
  }

  @override
  Future<BookingDisputes> disputes(String bookingId) async =>
      throw UnsupportedExperienceAction('reading disputes');

  @override
  Future<BookingDisputes> openDispute({
    required String bookingId,
    required DisputeDraft draft,
  }) async =>
      throw UnsupportedExperienceAction('opening a dispute');
}
