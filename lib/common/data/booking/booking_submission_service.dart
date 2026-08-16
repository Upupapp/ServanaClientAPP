/// The one booking-create ceremony, shared by every category flow.
///
/// ## The endpoint gap this sits on top of
///
/// There is **no `POST /api/v1/bookings`**. Verified against the backend
/// contract on 2026-08-16, not inherited from an earlier note: every v1
/// `bookings` entry is either a read (`listMine`, `get`, `timeline`,
/// `transitions`, `tracking`) or an action on an ALREADY EXISTING
/// `:bookingId` (cancel, reschedule, otp, additional-work, disputes,
/// support-cases, review, payment-intents, refunds). Booking creation is
/// classified `KEEP` with no canonical successor and none planned.
///
/// So this tab could not migrate the transport, and it does not pretend to.
/// It submits through the legacy `POST /api/bookings` that both flows already
/// used. What it removes is the *duplicate ceremony* around that call — two
/// near-identical hundred-line methods that had drifted apart in three places
/// and would have drifted further.
///
/// When a canonical create arrives, exactly one method changes.
///
/// ## What the ceremony is
///
///     resolve session  →  validate request  →  reuse idempotency key
///       →  journal BEFORE the call  →  submit  →  parse  →  resolve journal
///
/// The journal write comes before the network call on purpose: a process kill
/// mid-request must leave a reconcilable record, and a record written after the
/// response is a record that does not exist for exactly the failure it is meant
/// to survive.
///
/// ## Idempotency
///
/// The key is supplied by the caller, not generated here, because it must be
/// stable across retries of the SAME draft and this service is stateless. Each
/// store generates once with `??=` and never regenerates — regenerating on
/// retry is what turns one booking into two.
///
/// The legacy route carries it as `X-Idempotency-Key`. v1 has first-class
/// `Idempotency-Key` semantics with `IDEMPOTENCY_KEY_REUSED`, but only on the
/// actions that exist; create is not one of them.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/domain/booking/booking_create_request.dart';
import 'package:client/core/recovery/operation_journal.dart';
import 'package:client/common/domain/booking/booking_create_response_parser.dart';

/// What came of a submission.
sealed class BookingSubmissionOutcome {
  const BookingSubmissionOutcome();
}

/// The backend created the booking.
class BookingAccepted extends BookingSubmissionOutcome {
  const BookingAccepted({
    required this.bookingId,
    required this.workerCode,
    required this.raw,
  });

  /// Non-null: the parser refuses a create response with no authoritative id
  /// rather than letting a caller discard its recovery journal.
  final int bookingId;

  final String? workerCode;

  /// The undecoded body, which the confirmation screens still read.
  final Map<String, dynamic> raw;
}

/// The request never left the device — no session, or an incomplete draft.
///
/// Distinct from [BookingFailed] because nothing was attempted: there is
/// nothing to reconcile, nothing to retry differently, and no journal entry.
class BookingRefused extends BookingSubmissionOutcome {
  const BookingRefused({required this.reasons, this.unauthenticated = false});

  final List<BookingRequestInvalidity> reasons;
  final bool unauthenticated;
}

/// The request was attempted and did not succeed.
class BookingFailed extends BookingSubmissionOutcome {
  const BookingFailed(this.error);

  final Object error;
}

class BookingSubmissionService {
  const BookingSubmissionService({
    required ServanaApiClient api,
    required OperationJournal journal,
    required Future<String?> Function() customerId,
    String Function()? newOperationId,
  })  : _api = api,
        _journal = journal,
        _customerId = customerId,
        _newOperationId = newOperationId;

  final ServanaApiClient _api;
  final OperationJournal _journal;

  /// Resolved from the session, never from screen state. The legacy route still
  /// takes `?userId=`, so this remains a client-supplied identifier on the
  /// wire — a gap the endpoint owns, recorded rather than papered over.
  final Future<String?> Function() _customerId;

  final String Function()? _newOperationId;

  /// Submits [request].
  ///
  /// [idempotencyKey] is a FUNCTION, not a value, and it is called only after
  /// the session and the draft have both passed. A draft that never leaves the
  /// device must not mint a key: the key identifies a booking attempt, and
  /// there was no attempt. Callers implement it as `() => _key ??= _uuid()`, so
  /// the first real submission fixes the key and every retry of that same draft
  /// reuses it.
  Future<BookingSubmissionOutcome> submit({
    required BookingCreateRequest request,
    required String Function() idempotencyKey,
    String? operationId,
  }) async {
    final userId = (await _customerId())?.trim() ?? '';
    if (userId.isEmpty) {
      return const BookingRefused(reasons: [], unauthenticated: true);
    }

    final problems = request.validate();
    if (problems.isNotEmpty) {
      return BookingRefused(reasons: problems);
    }

    // Everything below is a real attempt, so now the key exists.
    final key = idempotencyKey();

    try {
      // Before the call, deliberately. See the library comment.
      final opId = operationId ?? _newOperationId?.call() ?? key;
      await _journal.record(JournaledOperation(
        id: opId,
        type: 'booking.create',
        customerUid: userId,
        payload: {
          'category': request.categoryLabel,
          'paymentMethod': request.paymentMethod,
        },
        startedAt: DateTime.now(),
        idempotencyKey: key,
      ));

      final raw = await _api.createBooking(
        userId: userId,
        payload: request.toPayload(),
        idempotencyKey: key,
      );

      final created = BookingCreateResponseParser.parse(raw);

      // Confirmed, so the pending entry is no longer pending.
      await _journal.resolveIdempotencyKey(
        userId,
        type: 'booking.create',
        idempotencyKey: key,
      );

      return BookingAccepted(
        bookingId: created.bookingId,
        workerCode: created.workerCode,
        raw: raw,
      );
    } catch (error) {
      // The journal entry is left standing on purpose: the request may have
      // been accepted and the response lost, and that is precisely the case
      // reconciliation exists for. Clearing it here would erase the only
      // evidence that a booking might exist.
      return BookingFailed(error);
    }
  }
}
