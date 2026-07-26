import 'package:client/modules/notifications/data/notification_mapper.dart';
import 'package:client/modules/notifications/data/notifications_local_data_source.dart';
import 'package:client/modules/notifications/data/notifications_remote_data_source.dart';
import 'package:client/modules/notifications/domain/notification_target.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';

class NotificationsRepository {
  final NotificationsRemoteDataSource _remote;
  final NotificationsLocalDataSource _local;

  NotificationsRepository({
    required NotificationsRemoteDataSource remote,
    required NotificationsLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  Future<List<ServanaNotification>> fetchNotifications({
    required String uid,
    String? filter,
  }) async {
    final notifications = await _remote.listNotifications(filter: filter);
    // Cache only unfiltered results for offline use
    if (filter == null || filter.isEmpty) {
      final rawList = notifications
          .map((n) => _notificationToMap(n))
          .toList();
      _local.saveCached(uid, rawList).ignore();
    }
    return notifications;
  }

  Future<List<ServanaNotification>> loadCached(String uid) async {
    final raw = await _local.loadCached(uid);
    return raw.map(mapNotification).toList();
  }

  Future<int> fetchUnreadCount(String uid) async {
    final count = await _remote.getUnreadCount();
    _local.saveCachedUnreadCount(uid, count).ignore();
    return count;
  }

  Future<int> loadCachedUnreadCount(String uid) =>
      _local.loadCachedUnreadCount(uid);

  Future<void> markRead(String key) => _remote.markRead(key);

  Future<void> markAllRead() => _remote.markAllRead();

  Future<void> dismiss(String key) => _remote.dismiss(key);

  Future<void> registerFcmToken(String token) => _remote.registerFcmToken(token);

  Future<void> clearFcmToken() => _remote.clearFcmToken();

  Future<void> clearCacheForAccount(String uid) =>
      _local.clearForAccount(uid);

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
      BookingTarget t => {'routeKey': 'BOOKING_DETAILS', 'resourceId': t.bookingId},
      PaymentTarget t => {'routeKey': 'PAYMENT_DETAILS', 'resourceId': t.bookingId},
      ConversationTarget t => {'routeKey': 'CONVERSATION', 'resourceId': t.conversationId},
      CategoryTarget t => {'routeKey': 'CATEGORY', 'resourceId': t.categoryKey},
      SettingsTarget() => {'routeKey': 'NOTIFICATION_SETTINGS', 'resourceId': ''},
      UnknownTarget t => {'routeKey': t.routeKey, 'resourceId': ''},
    };
  }
}
