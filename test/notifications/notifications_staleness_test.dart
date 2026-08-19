/// A stale list must say it is stale, and the icon must not invent a cause.
///
/// Two defects sat here together. `NotificationsLoadState.offline` was set by
/// the controller whenever a background refresh failed while a list was
/// already on screen — and the screen never referenced it. So that failure
/// rendered a stale list with nothing at all to say it was stale, while the
/// banner literally named "offline" was shown for a different state.
///
/// The second was the icon. Both the error view and the banner drew
/// `Icons.wifi_off_rounded` for every failure, so a 500 from a healthy
/// connection told the customer to check their wifi. On 2026-08-19 that was
/// not hypothetical: production was answering 500 on every database-backed
/// route.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/notifications/application/notifications_controller.dart';
import 'package:client/modules/notifications/application/notifications_state.dart';
import 'package:client/modules/notifications/data/notifications_repository.dart';
import 'package:client/modules/notifications/domain/notification_type.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements NotificationsRepository {}

void main() {
  late _MockRepo repo;
  late NotificationsController ctrl;

  ServanaNotification notif(String key) => ServanaNotification(
        notificationKey: key,
        type: ServanaNotificationType.bookingCreated,
        title: 'Title $key',
        safeBody: 'Body $key',
        isRead: false,
        canMarkRead: true,
        canDismiss: true,
        canOpenDetail: false,
        createdAt: DateTime(2025, 1, 15, 10),
      );

  setUp(() {
    repo = _MockRepo();
    ctrl = NotificationsController(repository: repo);
    when(() => repo.loadCached(any())).thenAnswer((_) async => []);
    when(() => repo.loadCachedUnreadCount(any())).thenAnswer((_) async => 0);
    when(() => repo.clearCacheForAccount(any())).thenAnswer((_) async {});
  });

  tearDown(() => ctrl.dispose());

  group('isStaleState is total over the enum', () {
    test('every state has an explicit answer', () {
      // If this list stops matching the enum the switch will not compile,
      // which is the point of writing it without a default arm.
      const all = NotificationsLoadState.values;
      expect(all.length, 6,
          reason: 'a state was added — decide what it means in isStaleState');
      for (final s in all) {
        expect(() => isStaleState(s), returnsNormally);
      }
    });

    test('the two failure states are stale', () {
      expect(isStaleState(NotificationsLoadState.error), isTrue);
      expect(isStaleState(NotificationsLoadState.offline), isTrue,
          reason: 'this is the one the screen used to ignore');
    });

    test('the healthy states are not', () {
      expect(isStaleState(NotificationsLoadState.initial), isFalse);
      expect(isStaleState(NotificationsLoadState.loading), isFalse);
      expect(isStaleState(NotificationsLoadState.ready), isFalse);
      expect(isStaleState(NotificationsLoadState.refreshing), isFalse);
    });
  });

  group('a failed load with a cached list is stale, not silent', () {
    test('reaches the offline state and that state reads as stale', () async {
      when(() => repo.loadCached(any())).thenAnswer((_) async => [notif('n1')]);
      when(() => repo.loadCachedUnreadCount(any())).thenAnswer((_) async => 1);
      when(() => repo.fetchNotifications(uid: any(named: 'uid')))
          .thenThrow(const ServanaApiException(statusCode: 500, body: 'boom'));
      when(() => repo.fetchUnreadCount(any())).thenAnswer((_) async => 1);

      await ctrl.init('uid-1');

      expect(ctrl.state, NotificationsLoadState.offline);
      expect(ctrl.notifications, isNotEmpty,
          reason: 'the cached list is deliberately kept');
      expect(isStaleState(ctrl.state), isTrue,
          reason: 'the screen must draw a staleness banner for this');
    });

    test('with no cached list it is the error state instead', () async {
      when(() => repo.fetchNotifications(uid: any(named: 'uid')))
          .thenThrow(const ServanaApiException(statusCode: 500, body: 'boom'));
      when(() => repo.fetchUnreadCount(any())).thenAnswer((_) async => 0);

      await ctrl.init('uid-1');

      expect(ctrl.state, NotificationsLoadState.error);
      expect(isStaleState(ctrl.state), isTrue);
    });
  });

  group('the failure knows whether the server answered', () {
    test('a status-carrying failure means the server answered', () async {
      when(() => repo.fetchNotifications(uid: any(named: 'uid')))
          .thenThrow(const ServanaApiException(statusCode: 500, body: 'boom'));
      when(() => repo.fetchUnreadCount(any())).thenAnswer((_) async => 0);

      await ctrl.init('uid-1');

      expect(ctrl.didReachServer, isTrue,
          reason: 'a 500 is a server fault — the icon must not claim wifi');
    });

    test('any other failure means it never got there', () async {
      when(() => repo.fetchNotifications(uid: any(named: 'uid')))
          .thenThrow(Exception('SocketException: failed host lookup'));
      when(() => repo.fetchUnreadCount(any())).thenAnswer((_) async => 0);

      await ctrl.init('uid-1');

      expect(ctrl.didReachServer, isFalse,
          reason: 'this one genuinely is a connection problem');
    });
  });
}
