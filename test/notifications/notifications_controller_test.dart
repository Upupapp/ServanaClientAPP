import 'package:client/modules/notifications/application/notifications_controller.dart';
import 'package:client/modules/notifications/application/notifications_state.dart';
import 'package:client/modules/notifications/data/notifications_repository.dart';
import 'package:client/modules/notifications/domain/notification_type.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements NotificationsRepository {}

void main() {
  late _MockRepo mockRepo;
  late NotificationsController ctrl;

  final ts = DateTime(2025, 1, 15, 10);

  ServanaNotification notif(String key, {bool isRead = false}) =>
      ServanaNotification(
        notificationKey: key,
        type: ServanaNotificationType.bookingCreated,
        title: 'Title $key',
        safeBody: 'Body $key',
        isRead: isRead,
        canMarkRead: !isRead,
        canDismiss: true,
        canOpenDetail: false,
        createdAt: ts,
      );

  setUp(() {
    mockRepo = _MockRepo();
    ctrl = NotificationsController(repository: mockRepo);

    when(() => mockRepo.loadCached(any())).thenAnswer((_) async => []);
    when(() => mockRepo.loadCachedUnreadCount(any()))
        .thenAnswer((_) async => 0);
    when(() => mockRepo.clearCacheForAccount(any())).thenAnswer((_) async {});
  });

  tearDown(() => ctrl.dispose());

  group('init', () {
    test('transitions to ready with notifications from backend', () async {
      final notifs = [notif('n1'), notif('n2', isRead: true)];
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenAnswer((_) async => notifs);
      when(() => mockRepo.fetchUnreadCount(any())).thenAnswer((_) async => 1);

      await ctrl.init('uid-123');

      expect(ctrl.state, NotificationsLoadState.ready);
      expect(ctrl.notifications.length, 2);
      expect(ctrl.unreadCount, 1);
    });

    test('shows error state when backend call fails and cache is empty',
        () async {
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenThrow(Exception('Network error'));
      when(() => mockRepo.fetchUnreadCount(any()))
          .thenThrow(Exception('Network error'));

      await ctrl.init('uid-123');

      expect(ctrl.state, NotificationsLoadState.error);
      expect(ctrl.error, isNotNull);
    });
  });

  group('markRead', () {
    test('optimistically marks a notification read', () async {
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenAnswer((_) async => [notif('n1'), notif('n2')]);
      when(() => mockRepo.fetchUnreadCount(any())).thenAnswer((_) async => 2);
      // Null is what the legacy route reports: it answers with no body, so
      // there is no reconciled unread count and the optimistic decrement
      // stands. See NotificationsDataSource.markRead.
      when(() => mockRepo.markRead('n1')).thenAnswer((_) async => null);

      await ctrl.init('uid-123');
      await ctrl.markRead('n1');

      expect(
        ctrl.notifications.firstWhere((n) => n.notificationKey == 'n1').isRead,
        isTrue,
      );
      expect(ctrl.unreadCount, 1);
    });

    test('rolls back on backend failure', () async {
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenAnswer((_) async => [notif('n1')]);
      when(() => mockRepo.fetchUnreadCount(any())).thenAnswer((_) async => 1);
      when(() => mockRepo.markRead('n1')).thenThrow(Exception('fail'));

      await ctrl.init('uid-123');
      await ctrl.markRead('n1');

      expect(
        ctrl.notifications.firstWhere((n) => n.notificationKey == 'n1').isRead,
        isFalse,
      );
      expect(ctrl.unreadCount, 1);
    });
  });

  group('dismiss', () {
    test('optimistically removes a notification', () async {
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenAnswer((_) async => [notif('n1'), notif('n2')]);
      when(() => mockRepo.fetchUnreadCount(any())).thenAnswer((_) async => 2);
      when(() => mockRepo.dismiss('n1')).thenAnswer((_) async {});

      await ctrl.init('uid-123');
      await ctrl.dismiss('n1');

      expect(ctrl.notifications.length, 1);
      expect(ctrl.notifications.first.notificationKey, 'n2');
      expect(ctrl.unreadCount, 1);
    });
  });

  group('onForegroundMessage', () {
    test('prepends and increments unread count', () async {
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenAnswer((_) async => []);
      when(() => mockRepo.fetchUnreadCount(any())).thenAnswer((_) async => 0);

      await ctrl.init('uid-123');
      ctrl.onForegroundMessage(notif('fcm-1'));

      expect(ctrl.notifications.first.notificationKey, 'fcm-1');
      expect(ctrl.unreadCount, 1);
    });

    test('deduplicates: second call with same key is ignored', () async {
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenAnswer((_) async => []);
      when(() => mockRepo.fetchUnreadCount(any())).thenAnswer((_) async => 0);

      await ctrl.init('uid-123');
      ctrl.onForegroundMessage(notif('fcm-1'));
      ctrl.onForegroundMessage(notif('fcm-1')); // duplicate

      expect(ctrl.notifications.length, 1);
      expect(ctrl.unreadCount, 1);
    });
  });

  group('markAllRead', () {
    test('rolls back on backend failure', () async {
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenAnswer((_) async => [notif('n1'), notif('n2')]);
      when(() => mockRepo.fetchUnreadCount(any())).thenAnswer((_) async => 2);
      when(() => mockRepo.markAllRead()).thenThrow(Exception('fail'));

      await ctrl.init('uid-123');
      await ctrl.markAllRead();

      expect(ctrl.notifications.every((n) => !n.isRead), isTrue);
      expect(ctrl.unreadCount, 2);
    });
  });

  group('refresh', () {
    test('transitions back to ready on success', () async {
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenAnswer((_) async => [notif('n1')]);
      when(() => mockRepo.fetchUnreadCount(any())).thenAnswer((_) async => 1);

      await ctrl.init('uid-123');
      await ctrl.refresh();

      expect(ctrl.state, NotificationsLoadState.ready);
      expect(ctrl.notifications.length, 1);
    });

    test(
        'shows offline state when init backend fetch fails but cache was loaded',
        () async {
      when(() => mockRepo.loadCached(any()))
          .thenAnswer((_) async => [notif('n1')]);
      when(() => mockRepo.loadCachedUnreadCount(any()))
          .thenAnswer((_) async => 1);
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenThrow(Exception('Network'));
      when(() => mockRepo.fetchUnreadCount(any()))
          .thenThrow(Exception('Network'));

      await ctrl.init('uid-123');

      expect(ctrl.state, NotificationsLoadState.offline);
      expect(ctrl.notifications.length, 1);
    });
  });

  group('clearOnLogout', () {
    test('resets all state', () async {
      when(() => mockRepo.fetchNotifications(uid: any(named: 'uid')))
          .thenAnswer((_) async => [notif('n1')]);
      when(() => mockRepo.fetchUnreadCount(any())).thenAnswer((_) async => 1);

      await ctrl.init('uid-123');
      ctrl.clearOnLogout();

      expect(ctrl.state, NotificationsLoadState.initial);
      expect(ctrl.notifications, isEmpty);
      expect(ctrl.unreadCount, 0);
    });
  });
}
