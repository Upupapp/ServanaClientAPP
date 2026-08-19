import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/modules/notifications/data/notification_mapper.dart';
import 'package:client/modules/notifications/data/notifications_data_source.dart';
import 'package:client/modules/notifications/data/notifications_local_data_source.dart';
import 'package:client/modules/notifications/data/notifications_remote_data_source.dart';
import 'package:client/modules/notifications/domain/notification_target.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';

/// Notifications feature repository — the TAB 02 compatibility pattern applied.
///
///     NotificationsRepository
///       → NotificationsCanonicalDataSource      when V1Capability.notifications
///       → NotificationsRemoteDataSource (legacy) otherwise
///       → List<ServanaNotification> either way
///
/// [canonical] and [router] are optional. Omitting either — which is what the
/// app does today, and what every existing test does — pins the repository to
/// the legacy source with no behaviour change at all. That is deliberate:
/// this tab adds a seam, it does not move traffic. `/api/v1` is not deployed.
///
/// One call escapes the pattern on purpose. [dismiss] has no canonical
/// successor, so it always goes to the compatibility source even when the rest
/// of the domain is canonical. The manifest tracks it as a remaining
/// compatibility endpoint rather than pretending the domain is done.
class NotificationsRepository {
  final NotificationsRemoteDataSource _remote;
  final NotificationsLocalDataSource _local;
  final NotificationsDataSource? _canonical;
  final CanonicalRouter? _router;

  NotificationsRepository({
    required NotificationsRemoteDataSource remote,
    required NotificationsLocalDataSource local,
    NotificationsDataSource? canonical,
    CanonicalRouter? router,
  })  : _remote = remote,
        _local = local,
        _canonical = canonical,
        _router = router;

  /// The source this repository reads from right now.
  ///
  /// Falls back to the compatibility source whenever the canonical one was not
  /// supplied, so a partially wired injector cannot route traffic at a
  /// transport that does not exist.
  NotificationsDataSource get _source {
    final canonical = _canonical;
    final router = _router;
    if (canonical == null || router == null) return _remote;
    return router.select<NotificationsDataSource>(
      V1Capability.notifications,
      canonical: canonical,
      compatibility: _remote,
    );
  }

  /// True when reads and writes are going to `/api/v1`. Diagnostics only.
  bool get isCanonical =>
      _canonical != null &&
      (_router?.isCanonical(V1Capability.notifications) ?? false);

  Future<List<ServanaNotification>> fetchNotifications({
    required String uid,
    String? filter,
  }) async {
    final notifications = await _source.listNotifications(filter: filter);
    // Cache only unfiltered results for offline use
    if (filter == null || filter.isEmpty) {
      final rawList = notifications.map((n) => _notificationToMap(n)).toList();
      _local.saveCached(uid, rawList).ignore();
    }
    return notifications;
  }

  Future<List<ServanaNotification>> loadCached(String uid) async {
    final raw = await _local.loadCached(uid);
    return raw.map(mapNotification).toList();
  }

  Future<int> fetchUnreadCount(String uid) async {
    final count = await _source.getUnreadCount();
    _local.saveCachedUnreadCount(uid, count).ignore();
    return count;
  }

  Future<int> loadCachedUnreadCount(String uid) =>
      _local.loadCachedUnreadCount(uid);

  /// Marks one read and returns the resulting unread count when the transport
  /// supplied it, else null.
  ///
  /// Null is "unknown, re-fetch if you need the badge" and must not be read as
  /// zero — the legacy route answers with no body, and treating that as zero
  /// would clear a badge that still has unread items behind it.
  Future<int?> markRead(String key) async {
    final count = await _source.markRead(key);
    return count;
  }

  Future<void> markAllRead() => _source.markAllRead();

  /// COMPATIBILITY-ONLY. `DELETE /api/user/notifications/:key` has no canonical
  /// successor, so this stays on the legacy source in every configuration.
  Future<void> dismiss(String key) => _remote.dismiss(key);

  Future<void> registerFcmToken(String token) =>
      _source.registerFcmToken(token);

  Future<void> clearFcmToken() => _source.clearFcmToken();

  Future<void> clearCacheForAccount(String uid) => _local.clearForAccount(uid);

  static Map<String, dynamic> _notificationToMap(ServanaNotification n) => {
        'notificationKey': n.notificationKey,
        'type': n.type.name,
        'status': n.isRead ? 'read' : 'unread',
        'severity': 'info',
        'title': n.title,
        'safeBody': n.safeBody,
        'safeContextLabel': n.safeContextLabel,
        'route': _targetToRoute(n.target),
        'canMarkRead': n.canMarkRead,
        'canDismiss': n.canDismiss,
        'canOpenDetail': n.canOpenDetail,
        'createdAt': n.createdAt.toIso8601String(),
        'expiresAt': n.expiresAt?.toIso8601String(),
        'readAt': n.readAt?.toIso8601String(),
      };

  static Map<String, dynamic>? _targetToRoute(NotificationTarget? target) {
    if (target == null) return null;
    return switch (target) {
      BookingTarget t => {
          'routeKey': 'BOOKING_DETAILS',
          'resourceId': t.bookingId
        },
      PaymentTarget t => {
          'routeKey': 'PAYMENT_DETAILS',
          'resourceId': t.bookingId
        },
      ConversationTarget t => {
          'routeKey': 'CONVERSATION',
          'resourceId': t.conversationId
        },
      CategoryTarget t => {'routeKey': 'CATEGORY', 'resourceId': t.categoryKey},
      SettingsTarget() => {
          'routeKey': 'NOTIFICATION_SETTINGS',
          'resourceId': ''
        },
      SupportTicketTarget t => {
          'routeKey': 'SUPPORT_TICKET',
          'resourceId': t.ticketKey
        },
      UnknownTarget t => {'routeKey': t.routeKey, 'resourceId': ''},
    };
  }
}
