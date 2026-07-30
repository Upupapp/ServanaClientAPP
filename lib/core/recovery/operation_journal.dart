import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A mutation that was dispatched but whose result is unknown
/// (network timeout, process kill before response arrived).
class JournaledOperation {
  const JournaledOperation({
    required this.id,
    required this.type,
    required this.customerUid,
    required this.payload,
    required this.startedAt,
    this.idempotencyKey,
  });

  /// Unique ID for this journal entry (not the booking/resource ID).
  final String id;

  /// Operation type string, e.g. 'booking.create', 'review.create'.
  final String type;

  /// UID of the customer who initiated the operation — used to scope reads.
  final String customerUid;

  /// Serializable payload snapshot (no tokens, no credentials).
  final Map<String, dynamic> payload;

  /// When the operation was dispatched.
  final DateTime startedAt;

  /// Stable idempotency key sent with the original request. If non-null, the
  /// operation is safe to reconcile by querying the backend with the same key.
  final String? idempotencyKey;

  static const Duration _maxAge = Duration(hours: 24);

  /// Operations older than 24 h are too stale to reconcile safely.
  bool get isExpired =>
      DateTime.now().difference(startedAt).abs() > _maxAge;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'customerUid': customerUid,
        'payload': payload,
        'startedAt': startedAt.toIso8601String(),
        'idempotencyKey': idempotencyKey,
      };

  factory JournaledOperation.fromJson(Map<String, dynamic> j) =>
      JournaledOperation(
        id: j['id'] as String,
        type: j['type'] as String,
        customerUid: j['customerUid'] as String,
        payload:
            (j['payload'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
                {},
        startedAt: DateTime.parse(j['startedAt'] as String),
        idempotencyKey: j['idempotencyKey'] as String?,
      );
}

/// Persists pending mutations across process kills using [FlutterSecureStorage]
/// so journal entries (which may contain booking payloads) are encrypted at rest.
///
/// All keys are scoped by customer UID to prevent cross-account state leakage.
/// Operations older than 24 h are pruned automatically on [load].
class OperationJournal {
  OperationJournal({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _kPrefix = 'op_journal_v1_';

  String _key(String uid) => '$_kPrefix$uid';

  // ── Public API ────────────────────────────────────────────────────────────

  Future<List<JournaledOperation>> load(String uid) async {
    final raw = await _storage.read(key: _key(uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final ops = list
          .whereType<Map<dynamic, dynamic>>()
          .map((m) =>
              JournaledOperation.fromJson(m.cast<String, dynamic>()))
          .where((op) => !op.isExpired)
          .toList();
      return ops;
    } catch (_) {
      return [];
    }
  }

  /// Adds or replaces an operation in the journal. Idempotent by [op.id].
  Future<void> record(JournaledOperation op) async {
    final existing = await load(op.customerUid);
    final updated = [
      ...existing.where((e) => e.id != op.id),
      op,
    ];
    await _persist(op.customerUid, updated);
  }

  /// Removes a specific operation — call after the backend confirms the result.
  Future<void> resolve(String uid, String operationId) async {
    final existing = await load(uid);
    await _persist(uid, existing.where((op) => op.id != operationId).toList());
  }

  /// Removes ALL journaled operations for [uid] — call on logout.
  Future<void> clearForAccount(String uid) async {
    await _storage.delete(key: _key(uid));
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<void> _persist(String uid, List<JournaledOperation> ops) async {
    await _storage.write(
      key: _key(uid),
      value: jsonEncode(ops.map((o) => o.toJson()).toList()),
    );
  }
}
