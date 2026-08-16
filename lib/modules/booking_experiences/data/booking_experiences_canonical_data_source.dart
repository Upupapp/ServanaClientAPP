/// Change orders and disputes over `/api/v1/bookings/:id/*`.
///
/// ## Not reachable in any shipped build
///
/// Selected per capability — `bookingAdditionalWork` for the change-order read,
/// `bookingDisputes` for the escalations — each requiring
/// `--dart-define=CANONICAL_V1_ENABLED=true` plus its own name in
/// `CANONICAL_V1_CAPABILITIES`. No production build passes either.
///
/// ## What moving here buys
///
/// For **change orders**, only the path: the legacy route is already
/// booking-scoped and already the same service, and the contract says the
/// canonical one *"differs only in living under the booking it belongs to."*
/// That is a small win and it is honestly small.
///
/// For **disputes**, everything. There is no customer dispute route today at
/// all; the legacy predecessor is admin-only and *"does not record a category,
/// the opening role or the state snapshot"*. So a canonical build gains an
/// escalation path the app has never had, with a state snapshot captured at
/// opening.
///
/// ## No idempotency key on `openDispute`
///
/// Its replay guard is a partial unique index — *"two simultaneous reports
/// produce one record and one `BOOKING_DISPUTE_ALREADY_OPEN`, not two
/// disputes"* — and the contract lists neither idempotency error code. The
/// uniqueness constraint is stronger than a client key and operates whether or
/// not one is sent.
library;

import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/booking_experiences/data/booking_experiences_data_source.dart';
import 'package:client/modules/booking_experiences/domain/additional_work.dart';
import 'package:client/modules/booking_experiences/domain/booking_dispute.dart';

class BookingExperiencesCanonicalDataSource
    implements BookingExperiencesDataSource {
  const BookingExperiencesCanonicalDataSource(this._api);

  final V1ApiClient _api;

  @override
  bool get supportsDisputes => true;

  @override
  Future<List<AdditionalWorkRequest>> additionalWork(String bookingId) async {
    final envelope = await _api.get(V1Endpoints.bookingAdditionalWork(bookingId));
    return envelope
        .listAt('requests')
        .map((row) =>
            AdditionalWorkRequest.fromApiMap(row, bookingId: bookingId))
        .toList(growable: false);
  }

  @override
  Future<BookingDisputes> disputes(String bookingId) async {
    final envelope = await _api.get(V1Endpoints.bookingDisputes(bookingId));
    return BookingDisputes.fromApiMap(envelope.asMap, bookingId: bookingId);
  }

  @override
  Future<BookingDisputes> openDispute({
    required String bookingId,
    required DisputeDraft draft,
  }) async {
    final envelope = await _api.post(
      V1Endpoints.bookingDisputes(bookingId),
      body: draft.toJson(),
    );

    // The open response is `{dispute, categories}` — one record, not a list —
    // while the read is `{disputes: [...], categories}`. Normalised to the
    // same type here rather than at the call site, so a caller that opens a
    // dispute and a caller that reads them handle one shape.
    final data = envelope.asMap;
    final raw = data['dispute'];
    return BookingDisputes(
      bookingId: bookingId,
      disputes: raw is Map
          ? <BookingDispute>[
              BookingDispute.fromApiMap(Map<String, dynamic>.from(raw),
                  bookingId: bookingId)
            ]
          : const <BookingDispute>[],
      categories: BookingDisputes.fromApiMap(data, bookingId: bookingId)
          .categories,
    );
  }
}
