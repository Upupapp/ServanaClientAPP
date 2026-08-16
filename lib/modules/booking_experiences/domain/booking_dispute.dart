/// Escalations raised against a booking.
///
/// ## The vocabulary comes FROM the server, and that is the point
///
/// TAB 10 mirrored `RESCHEDULE_REASONS` and TAB 11 mirrored the customer subset
/// of `REFUND_TRIGGERS`, both under the same justification: a reason has to be
/// pickable before a request exists, and there is no endpoint that hands the
/// list over first.
///
/// Disputes are different, and better. `GET /bookings/:id/disputes` returns
/// `categories: DISPUTE_CATEGORIES` **unconditionally** — including when the
/// booking has no disputes at all — so the one call a screen makes to show
/// existing escalations also hands it the vocabulary for opening a new one.
/// There is nothing to mirror, so [DisputeCategory] is a *value*, not an enum:
/// a closed enum here would be a client copy that could fall behind the
/// server's list and quietly stop offering a category.
///
/// That asymmetry is worth naming rather than smoothing over. Where the backend
/// serves its own vocabulary, the client must consume it; where it does not,
/// mirroring is the least-bad option and is documented as such.
///
/// ## What is never projected, to anyone
///
/// `reason`, `assigned_team` and `actor_uid` are withheld from every caller —
/// *"free text one party typed about another, internal routing, and a person."*
/// The customer WRITES `reason` when opening a dispute and can never read it
/// back, not even their own. This file therefore has no `reason` field on
/// [BookingDispute], only on [DisputeDraft]. A model that carried one would be
/// a parser waiting for a disclosure bug.
///
/// `openedByYou` is the only caller-dependent field in the whole projection.
library;

import 'package:client/common/domain/time/iso_timestamp.dart';

/// A dispute category, as named by the server.
///
/// Deliberately a wrapper around a string rather than an enum. The authoritative
/// list arrives on every disputes read, and the backend documents its own list
/// as *"a superset of the provider-facing categories, which must remain a
/// subset"* — a set that is expected to grow. A client enum would turn each
/// addition into a release.
extension type const DisputeCategory(String wireName) {
  /// Customer-facing copy for the categories known at build time.
  ///
  /// A fallback for presentation ONLY. An unrecognised category still renders
  /// — humanised from its wire name — rather than being dropped, because
  /// dropping it would hide an option the server is offering.
  String get label => switch (wireName) {
        'SCOPE_DISAGREEMENT' => 'The work done was not what we agreed',
        'PAYMENT_ISSUE' => 'A problem with payment',
        'CUSTOMER_CONDUCT' => 'Conduct concern',
        'PROVIDER_SAFETY' => 'A safety concern',
        'CANCELLATION_DISAGREEMENT' => 'A disagreement about a cancellation',
        'COMPLETION_DISAGREEMENT' => 'The job was marked done and was not',
        'DAMAGE_CLAIM' => 'Something was damaged',
        'SERVICE_QUALITY' => 'The quality of the work',
        'NO_SHOW' => 'Nobody arrived',
        _ => _humanise(wireName),
      };

  static String _humanise(String raw) {
    if (raw.isEmpty) return 'Something else';
    final words = raw.toLowerCase().split('_').where((w) => w.isNotEmpty);
    if (words.isEmpty) return 'Something else';
    final first = words.first;
    return [
      first[0].toUpperCase() + first.substring(1),
      ...words.skip(1),
    ].join(' ');
  }
}

enum DisputeSeverity {
  low('low'),
  normal('normal'),
  high('high');

  const DisputeSeverity(this.wireName);

  final String wireName;

  static DisputeSeverity fromWire(Object? raw) {
    final name = '${raw ?? ''}'.toLowerCase().trim();
    for (final s in DisputeSeverity.values) {
      if (s.wireName == name) return s;
    }
    return DisputeSeverity.normal;
  }
}

enum DisputeState {
  open('OPEN'),
  resolved('RESOLVED'),
  unknown('UNKNOWN');

  const DisputeState(this.wireName);

  final String wireName;

  static DisputeState fromWire(Object? raw) {
    final name = '${raw ?? ''}'.toUpperCase().trim();
    for (final s in DisputeState.values) {
      if (s.wireName == name) return s;
    }
    return DisputeState.unknown;
  }
}

/// What the booking looked like when the dispute was opened.
///
/// *"The service and financial state AT OPENING — canonical state, raw
/// statuses, schedule, payment status and method. No amounts, no references,
/// no payer."* Held as an opaque map: it is evidence for an investigation, not
/// a view model, and typing it would invite a screen to render fields the
/// backend deliberately kept coarse.
typedef DisputeStateSnapshot = Map<String, dynamic>;

class BookingDispute {
  const BookingDispute({
    required this.id,
    required this.bookingId,
    required this.state,
    this.category,
    this.severity = DisputeSeverity.normal,
    this.openedByRole,
    this.openedByYou = false,
    this.openedAt,
    this.resolvedAt,
    this.stateSnapshot,
  });

  final int id;
  final String bookingId;
  final DisputeState state;
  final DisputeCategory? category;
  final DisputeSeverity severity;

  /// The seat that opened it. The uid is not projected.
  final String? openedByRole;

  /// The only caller-dependent field in the projection.
  final bool openedByYou;

  final DateTime? openedAt;
  final DateTime? resolvedAt;
  final DisputeStateSnapshot? stateSnapshot;

  bool get isOpen => state == DisputeState.open;

  static BookingDispute fromApiMap(Map<String, dynamic> json,
      {required String bookingId}) {
    final snapshot = json['stateSnapshot'];
    final rawCategory = json['category']?.toString();

    return BookingDispute(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse('${json['id'] ?? ''}') ?? 0,
      bookingId: '${json['bookingId'] ?? bookingId}',
      state: DisputeState.fromWire(json['state']),
      category: rawCategory == null || rawCategory.isEmpty
          ? null
          : DisputeCategory(rawCategory),
      severity: DisputeSeverity.fromWire(json['severity']),
      openedByRole: json['openedByRole']?.toString(),
      openedByYou: json['openedByYou'] == true,
      openedAt: parseBackendTimestamp(json['openedAt']),
      resolvedAt: parseBackendTimestamp(json['resolvedAt']),
      stateSnapshot:
          snapshot is Map ? Map<String, dynamic>.from(snapshot) : null,
    );
  }
}

/// The disputes on a booking, plus the vocabulary for opening another.
///
/// One object because the endpoint returns one payload. Splitting them would
/// invite a caller to fetch the categories separately, which is the habit this
/// design removes.
class BookingDisputes {
  const BookingDisputes({
    required this.bookingId,
    this.disputes = const <BookingDispute>[],
    this.categories = const <DisputeCategory>[],
  });

  final String bookingId;
  final List<BookingDispute> disputes;

  /// Server-supplied, and empty on the compatibility transport — which is how
  /// a caller knows it cannot offer a category picker rather than offering a
  /// stale one.
  final List<DisputeCategory> categories;

  /// At most one unresolved escalation per booking, enforced by a partial
  /// unique index as well as by policy. So this is a single, not a list.
  BookingDispute? get openDispute {
    for (final d in disputes) {
      if (d.isOpen) return d;
    }
    return null;
  }

  bool get hasOpenDispute => openDispute != null;

  static BookingDisputes fromApiMap(
    Map<String, dynamic> json, {
    required String bookingId,
  }) {
    final rawDisputes = json['disputes'];
    final rawCategories = json['categories'];

    return BookingDisputes(
      bookingId: '${json['bookingId'] ?? bookingId}',
      disputes: rawDisputes is List
          ? rawDisputes
              .whereType<Map>()
              .map((e) => BookingDispute.fromApiMap(
                  Map<String, dynamic>.from(e),
                  bookingId: bookingId))
              .toList(growable: false)
          : const <BookingDispute>[],
      categories: rawCategories is List
          ? rawCategories
              .map((e) => e?.toString())
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .map(DisputeCategory.new)
              .toList(growable: false)
          : const <DisputeCategory>[],
    );
  }
}

/// What the customer is about to raise.
class DisputeDraft {
  const DisputeDraft({
    required this.category,
    required this.reason,
    this.severity,
    this.evidence,
  });

  final DisputeCategory category;

  /// What went wrong.
  ///
  /// Written to the admin record and **not projected back to the other party**
  /// — nor to the author. A screen that shows this after submission is showing
  /// its own local copy, and must not present it as something the platform will
  /// echo back.
  final String reason;

  final DisputeSeverity? severity;

  /// *"Ids, never file contents."* Typed as strings so a caller cannot pass a
  /// byte array by accident.
  final List<String>? evidence;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'category': category.wireName,
        'reason': reason.trim(),
        if (severity != null) 'severity': severity!.wireName,
        if (evidence != null && evidence!.isNotEmpty) 'evidence': evidence,
      };
}
