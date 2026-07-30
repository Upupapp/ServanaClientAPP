import 'dart:convert';
import 'dart:math';

import 'package:client/common/domain/booking/booking_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Context required to resume a PayMongo checkout after process termination
/// or the user exiting the browser and returning to the app.
///
/// C20 hard rules:
/// - NEVER persist OTP, passwords, auth tokens, or raw card credentials.
/// - Treat as expired after 2 h — stale checkout URLs are rejected by PayMongo.
class PendingPaymentContext {
  const PendingPaymentContext({
    required this.bookingId,
    required this.checkoutUrl,
    required this.customerUid,
    required this.savedAt,
  });

  final int bookingId;
  final String checkoutUrl;
  final String customerUid;
  final DateTime savedAt;

  static const Duration _maxAge = Duration(hours: 2);
  bool get isExpired =>
      DateTime.now().difference(savedAt).abs() > _maxAge;

  Map<String, dynamic> toJson() => {
        'bookingId': bookingId,
        'checkoutUrl': checkoutUrl,
        'customerUid': customerUid,
        'savedAt': savedAt.toIso8601String(),
      };

  factory PendingPaymentContext.fromJson(Map<String, dynamic> j) =>
      PendingPaymentContext(
        bookingId: j['bookingId'] as int,
        checkoutUrl: j['checkoutUrl'] as String,
        customerUid: j['customerUid'] as String,
        savedAt: DateTime.parse(j['savedAt'] as String),
      );
}

/// Persists booking drafts, idempotency keys, and payment context across
/// process kills.
///
/// All storage keys are scoped by customer UID so Customer A's state can
/// never surface for Customer B. Call [clearAllForAccount] on logout.
class DraftRepository {
  static const String _kDraftPrefix = 'booking_draft_v1_';
  static const String _kIdemPrefix = 'booking_idem_v1_';
  static const String _kPaymentPrefix = 'pending_payment_v1_';

  // ── Booking Draft ─────────────────────────────────────────────────────────

  Future<BookingDraft?> loadDraft(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kDraftPrefix$uid');
    if (raw == null || raw.isEmpty) return null;
    try {
      final draft = _draftFromJson(
          jsonDecode(raw) as Map<dynamic, dynamic>);
      return draft.isExpired ? null : draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDraft(String uid, BookingDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_kDraftPrefix$uid', jsonEncode(_draftToJson(draft)));
  }

  Future<void> clearDraft(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kDraftPrefix$uid');
  }

  // ── Idempotency Key ───────────────────────────────────────────────────────

  /// Returns a stable idempotency key for [draftId], generating one on first
  /// call. Reuse is guaranteed across retries within the same booking session.
  /// Call [clearIdempotencyKey] only after the booking is confirmed by the backend.
  Future<String> getOrCreateIdempotencyKey(
      String uid, String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final k = '$_kIdemPrefix${uid}_$draftId';
    final existing = prefs.getString(k);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _uuidV4();
    await prefs.setString(k, generated);
    return generated;
  }

  Future<void> clearIdempotencyKey(String uid, String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kIdemPrefix${uid}_$draftId');
  }

  // ── Pending Payment Context ───────────────────────────────────────────────

  Future<PendingPaymentContext?> loadPaymentContext(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kPaymentPrefix$uid');
    if (raw == null || raw.isEmpty) return null;
    try {
      final ctx = PendingPaymentContext.fromJson(
          (jsonDecode(raw) as Map<dynamic, dynamic>).cast<String, dynamic>());
      return ctx.isExpired ? null : ctx;
    } catch (_) {
      return null;
    }
  }

  Future<void> savePaymentContext(PendingPaymentContext ctx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_kPaymentPrefix${ctx.customerUid}', jsonEncode(ctx.toJson()));
  }

  Future<void> clearPaymentContext(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kPaymentPrefix$uid');
  }

  // ── Account Isolation ─────────────────────────────────────────────────────

  /// Removes all draft, idempotency, and payment context for [uid].
  /// Call during logout to prevent cross-account state leakage.
  Future<void> clearAllForAccount(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final toRemove = prefs.getKeys().where((k) =>
        k.startsWith('$_kDraftPrefix$uid') ||
        k.startsWith('$_kIdemPrefix$uid') ||
        k.startsWith('$_kPaymentPrefix$uid'));
    for (final k in toRemove) {
      await prefs.remove(k);
    }
  }

  /// Clears ALL draft, idempotency, and payment context entries regardless of UID.
  /// Used as a fallback during logout when the UID cannot be determined (LEAK M-1).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final toRemove = prefs.getKeys().where((k) =>
        k.startsWith(_kDraftPrefix) ||
        k.startsWith(_kIdemPrefix) ||
        k.startsWith(_kPaymentPrefix));
    for (final k in toRemove) {
      await prefs.remove(k);
    }
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  static Map<String, dynamic> _draftToJson(BookingDraft d) => {
        'id': d.id,
        'createdAt': d.createdAt.toIso8601String(),
        'updatedAt': d.updatedAt?.toIso8601String(),
        'status': d.status.name,
        'serviceId': d.serviceId,
        'merchantId': d.merchantId,
        'merchantName': d.merchantName,
        'categoryName': d.categoryName,
        'flowType': d.flowType?.name,
        'selectedServiceJson': d.selectedServiceJson,
        'selectedOptions': d.selectedOptions,
        'selectedAddons': d.selectedAddons,
        'quantity': d.quantity,
        'notes': d.notes,
        'addressLine': d.addressLine,
        'lat': d.lat,
        'lon': d.lon,
        'selectedBranchId': d.selectedBranchId,
        'selectedDate': d.selectedDate?.toIso8601String(),
        'selectedSlot': d.selectedSlot,
        'pricingSnapshot': d.pricingSnapshot,
        'sourceRouteName': d.sourceRouteName,
        'returnRouteName': d.returnRouteName,
      };

  static BookingDraft _draftFromJson(Map<dynamic, dynamic> raw) {
    final j = raw.cast<String, dynamic>();
    BookingDraftStatus status = BookingDraftStatus.editing;
    try {
      status = BookingDraftStatus.values.byName(j['status'] as String? ?? '');
    } catch (_) {}

    BookingFlowType? flowType;
    try {
      final ft = j['flowType'] as String?;
      if (ft != null) flowType = BookingFlowType.values.byName(ft);
    } catch (_) {}

    return BookingDraft(
      id: j['id'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      updatedAt:
          j['updatedAt'] != null ? DateTime.parse(j['updatedAt'] as String) : null,
      status: status,
      serviceId: j['serviceId'] as String?,
      merchantId: j['merchantId'] as String?,
      merchantName: j['merchantName'] as String?,
      categoryName: j['categoryName'] as String?,
      flowType: flowType,
      selectedServiceJson: j['selectedServiceJson'] as String?,
      selectedOptions:
          (j['selectedOptions'] as List<dynamic>?)?.cast<String>() ?? [],
      selectedAddons:
          (j['selectedAddons'] as List<dynamic>?)?.cast<String>() ?? [],
      quantity: j['quantity'] as int?,
      notes: j['notes'] as String?,
      addressLine: j['addressLine'] as String?,
      lat: (j['lat'] as num?)?.toDouble(),
      lon: (j['lon'] as num?)?.toDouble(),
      selectedBranchId: j['selectedBranchId'] as String?,
      selectedDate: j['selectedDate'] != null
          ? DateTime.parse(j['selectedDate'] as String)
          : null,
      selectedSlot: j['selectedSlot'] as String?,
      pricingSnapshot: (j['pricingSnapshot'] as num?)?.toDouble(),
      sourceRouteName: j['sourceRouteName'] as String?,
      returnRouteName: j['returnRouteName'] as String?,
    );
  }

  // ── UUID v4 (no external dependency) ─────────────────────────────────────

  static String _uuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
