import 'dart:convert';

import 'package:client/core/network/canonical_availability.dart';
import 'package:client/core/network/compat/canonical_router.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/modules/notifications/data/notification_mapper.dart';
import 'package:client/modules/notifications/data/notifications_canonical_data_source.dart';
import 'package:client/modules/notifications/data/notifications_data_source.dart';
import 'package:client/modules/notifications/data/notifications_local_data_source.dart';
import 'package:client/modules/notifications/data/notifications_remote_data_source.dart';
import 'package:client/modules/notifications/data/notifications_repository.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One inbox row, in the projection BOTH transports serve. The v1 handler
/// returns the same inbox rows the legacy route does, which is what lets one
/// mapper read both.
const Map<String, dynamic> _row = <String, dynamic>{
  'notificationKey': 'ntf_1',
  'type': 'BOOKING_CONFIRMED',
  'status': 'unread',
  'title': 'Your booking is confirmed',
  'safeBody': 'A provider is on the way.',
  'route': <String, dynamic>{'routeKey': 'BOOKING_DETAILS', 'resourceId': '42'},
  'canMarkRead': true,
  'canDismiss': true,
  'canOpenDetail': true,
  'createdAt': '2026-08-14T10:00:00.000Z',
};

/// Stands in for the legacy [NotificationsRemoteDataSource] without needing a
/// real [ServanaApiClient]. Records what was called so a test can assert which
/// transport answered.
class _FakeLegacySource extends Fake implements NotificationsRemoteDataSource {
  final List<String> calls = <String>[];

  @override
  Future<List<ServanaNotification>> listNotifications({String? filter}) async {
    calls.add('list');
    return <ServanaNotification>[mapRow()];
  }

  @override
  Future<int> getUnreadCount() async {
    calls.add('unreadCount');
    return 3;
  }

  @override
  Future<int?> markRead(String key) async {
    calls.add('markRead');
    return null; // the legacy route answers with no body
  }

  @override
  Future<void> markAllRead() async => calls.add('markAllRead');

  @override
  Future<void> dismiss(String key) async => calls.add('dismiss');

  @override
  Future<void> registerFcmToken(String token) async => calls.add('register');

  @override
  Future<void> clearFcmToken() async => calls.add('clear');

  /// The legacy source runs the SAME production mapper over the SAME row the
  /// canonical source receives — which is the property under test.
  static ServanaNotification mapRow() =>
      mapNotification(<String, dynamic>{..._row});
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  V1ApiClient canonicalClientReturning(Object body, {int status = 200}) =>
      V1ApiClient(
        baseUrl: 'https://api.example.test',
        httpClient: MockClient((_) async => http.Response(
              jsonEncode(body),
              status,
              headers: {'content-type': 'application/json'},
            )),
      );

  group('both transports normalise to one domain model', () {
    test('canonical and legacy produce an equivalent ServanaNotification',
        () async {
      final canonical = NotificationsCanonicalDataSource(
        canonicalClientReturning(<String, dynamic>{
          'data': {
            'notifications': [_row]
          },
          'meta': {
            'page': {'limit': 100, 'offset': 0, 'total': 1, 'hasMore': false},
            'unreadCount': 3,
          },
        }),
      );

      final fromCanonical = (await canonical.listNotifications()).single;
      final fromLegacy = (await _FakeLegacySource().listNotifications()).single;

      // The two transports must be indistinguishable above the data source.
      expect(fromCanonical.notificationKey, fromLegacy.notificationKey);
      expect(fromCanonical.type, fromLegacy.type);
      expect(fromCanonical.title, fromLegacy.title);
      expect(fromCanonical.safeBody, fromLegacy.safeBody);
      expect(fromCanonical.isRead, fromLegacy.isRead);
      expect(fromCanonical.canDismiss, fromLegacy.canDismiss);
      expect(fromCanonical.createdAt, fromLegacy.createdAt);
      expect(fromCanonical.target.runtimeType, fromLegacy.target.runtimeType);

      expect(fromCanonical.notificationKey, 'ntf_1');
      expect(fromCanonical.isRead, isFalse);
      expect(fromCanonical.title, 'Your booking is confirmed');
    });

    test('canonical markRead reports the reconciled count, legacy reports null',
        () async {
      final canonical = NotificationsCanonicalDataSource(
        canonicalClientReturning(<String, dynamic>{
          'data': {'count': 7}
        }),
      );
      expect(await canonical.markRead('ntf_1'), 7);

      final legacy = _FakeLegacySource();
      expect(await legacy.markRead('ntf_1'), isNull,
          reason: 'null is "unknown", never zero');
    });

    test('a missing count is null rather than zero', () async {
      // Zero would clear a badge that still has unread items behind it.
      final canonical =
          NotificationsCanonicalDataSource(canonicalClientReturning(
        <String, dynamic>{'data': <String, dynamic>{}},
      ));
      expect(await canonical.markRead('ntf_1'), isNull);
    });
  });

  group('repository routing', () {
    NotificationsRepository repositoryWith({
      required _FakeLegacySource legacy,
      NotificationsDataSource? canonical,
      CanonicalRouter? router,
    }) =>
        NotificationsRepository(
          remote: legacy,
          local: NotificationsLocalDataSource(),
          canonical: canonical,
          router: router,
        );

    test('defaults to the compatibility source when nothing is wired', () async {
      final legacy = _FakeLegacySource();
      final repo = repositoryWith(legacy: legacy);
      await repo.fetchNotifications(uid: 'u1');
      expect(legacy.calls, contains('list'));
      expect(repo.isCanonical, isFalse);
    });

    test('stays on the compatibility source while the gate is closed', () async {
      // This is the state of every shipped build: /api/v1 is not deployed.
      final legacy = _FakeLegacySource();
      final repo = repositoryWith(
        legacy: legacy,
        canonical: NotificationsCanonicalDataSource(
            canonicalClientReturning(<String, dynamic>{'data': {}})),
        router: const CanonicalRouter(availability: CanonicalAvailability()),
      );
      await repo.fetchNotifications(uid: 'u1');
      expect(legacy.calls, contains('list'),
          reason: 'the canonical source must not be reached');
      expect(repo.isCanonical, isFalse);
    });

    test('uses the canonical source once the capability is enabled', () async {
      final legacy = _FakeLegacySource();
      final repo = repositoryWith(
        legacy: legacy,
        canonical: NotificationsCanonicalDataSource(
          canonicalClientReturning(<String, dynamic>{
            'data': {
              'notifications': [_row]
            }
          }),
        ),
        router: const CanonicalRouter(
          availability: CanonicalAvailability(
            enabled: true,
            capabilities: <V1Capability>{V1Capability.notifications},
          ),
        ),
      );
      final result = await repo.fetchNotifications(uid: 'u1');
      expect(result.single.notificationKey, 'ntf_1');
      expect(legacy.calls, isEmpty,
          reason: 'the legacy source must not be reached');
      expect(repo.isCanonical, isTrue);
    });

    test('dismiss stays on the compatibility source even when canonical',
        () async {
      // DELETE /api/user/notifications/:key has no canonical successor, so a
      // "migrated" domain still routes this one call to legacy.
      final legacy = _FakeLegacySource();
      final repo = repositoryWith(
        legacy: legacy,
        canonical: NotificationsCanonicalDataSource(
            canonicalClientReturning(<String, dynamic>{'data': {}})),
        router: const CanonicalRouter(
          availability: CanonicalAvailability(
            enabled: true,
            capabilities: <V1Capability>{V1Capability.notifications},
          ),
        ),
      );
      await repo.dismiss('ntf_1');
      expect(legacy.calls, <String>['dismiss']);
      expect(repo.isCanonical, isTrue,
          reason: 'the domain is canonical and this call still is not');
    });

    test('a canonical source without a router cannot take traffic', () async {
      // A half-wired injector must fail toward legacy, never toward a
      // transport that may not exist.
      final legacy = _FakeLegacySource();
      final repo = repositoryWith(
        legacy: legacy,
        canonical: NotificationsCanonicalDataSource(
            canonicalClientReturning(<String, dynamic>{'data': {}})),
      );
      await repo.fetchNotifications(uid: 'u1');
      expect(legacy.calls, contains('list'));
    });
  });
}
