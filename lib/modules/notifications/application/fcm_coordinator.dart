import 'dart:async';
import 'dart:math';

import 'package:client/modules/notifications/application/notifications_controller.dart';
import 'package:client/modules/notifications/data/notification_mapper.dart';
import 'package:client/modules/notifications/data/notifications_repository.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kInstallationIdKey = 'servana_installation_id_v1';

/// Manages FCM token lifecycle: registration, refresh, and logout deactivation.
/// Does NOT perform navigation; that is delegated to NotificationNavigationCoordinator.
class FcmCoordinator {
  final NotificationsRepository _repository;
  final NotificationsController _notificationsCtrl;
  final FlutterSecureStorage _secureStorage;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;

  // Stream broadcast to the foreground banner
  final _foregroundStreamCtrl =
      StreamController<ServanaNotification>.broadcast();
  Stream<ServanaNotification> get foregroundStream =>
      _foregroundStreamCtrl.stream;

  // For deduplication of foreground messages
  final Set<String> _recentKeys = {};

  String? _activeUid;

  FcmCoordinator({
    required NotificationsRepository repository,
    required NotificationsController notificationsController,
    required FlutterSecureStorage secureStorage,
  })  : _repository = repository,
        _notificationsCtrl = notificationsController,
        _secureStorage = secureStorage;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Call once after Firebase.initializeApp(), before runApp.
  /// Registers the top-level background handler reference.
  static void initHandlers() {
    // The @pragma('vm:entry-point') background handler is registered in main.dart.
    // iOS foreground presentation: suppress OS banner (handled in-app via toastification).
    FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: false,
        )
        .ignore();
  }

  /// Call after the customer successfully logs in. Registers the FCM token
  /// with the Servana backend for this account.
  Future<void> registerForAccount(String uid) async {
    _activeUid = uid;
    try {
      await _awaitApnsTokenOnIos();

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _repository.registerFcmToken(token);
      }
      _subscribeToRefresh(uid);
      _subscribeToForeground();
    } catch (e) {
      debugPrint(
          '[FcmCoordinator] registerForAccount failed: ${e.runtimeType}');
    }
  }

  /// On iOS, FCM cannot mint a token until APNs has delivered one to the
  /// device. Calling `getToken()` first throws `apns-token-not-set`.
  ///
  /// This was the shape of the bug: `getToken()` was called directly, the
  /// throw was caught by the handler above, and the failure became a single
  /// `debugPrint`. So on a cold start the device would simply never register
  /// for push — no crash, no log in production, and every investigation would
  /// point at the APNs key or the Firebase upload rather than at a race.
  ///
  /// APNs registration is asynchronous and usually completes in well under a
  /// second, but it is not instant and it is not guaranteed: in the Simulator,
  /// with no network, or when the customer denies the permission prompt, it
  /// never arrives. So this polls briefly and then gives up rather than
  /// blocking login. Giving up is fine — `onTokenRefresh` fires once APNs
  /// does arrive, and [_subscribeToRefresh] registers the token then.
  Future<void> _awaitApnsTokenOnIos() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    const attempts = 10;
    const gap = Duration(milliseconds: 300);

    for (var i = 0; i < attempts; i++) {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns != null) return;
      if (i < attempts - 1) await Future<void>.delayed(gap);
    }

    debugPrint(
      '[FcmCoordinator] no APNS token after ${attempts * gap.inMilliseconds}ms. '
      'Push permission may be denied, or this is the Simulator. Registration '
      'will be retried by onTokenRefresh.',
    );
  }

  /// Call on logout. Deactivates the device token in the backend so no
  /// notifications are sent to a signed-out device.
  Future<void> deactivateOnLogout() async {
    _foregroundSub?.cancel();
    _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _tokenRefreshSub = null;
    _activeUid = null;
    _recentKeys.clear();
    try {
      await _repository.clearFcmToken();
    } catch (_) {}
    // LEAK L-2: invalidate the FCM token on Firebase's side so the device
    // cannot receive push notifications while signed out.
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  /// Returns the stable installation ID, generating one on first call.
  Future<String> getInstallationId() async {
    final stored = await _secureStorage.read(key: _kInstallationIdKey);
    if (stored != null && stored.isNotEmpty) return stored;
    final generated = _generateUuidV4();
    await _secureStorage.write(key: _kInstallationIdKey, value: generated);
    return generated;
  }

  void dispose() {
    _foregroundSub?.cancel();
    _tokenRefreshSub?.cancel();
    _foregroundStreamCtrl.close();
  }

  // ─── Internal ──────────────────────────────────────────────────────────────

  void _subscribeToForeground() {
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      _handleForeground(message);
    });
  }

  void _subscribeToRefresh(String uid) {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (_activeUid != uid) return; // account switch guard
      _repository.registerFcmToken(newToken).ignore();
    });
  }

  void _handleForeground(RemoteMessage message) {
    final data = message.data;
    final key = data['notificationKey'] as String?;
    if (key == null || key.isEmpty) return;
    if (_recentKeys.contains(key)) return; // deduplicate

    _recentKeys.add(key);
    if (_recentKeys.length > 50) {
      // Trim oldest entries to prevent unbounded growth
      _recentKeys.remove(_recentKeys.first);
    }

    // Build a minimal notification for the foreground banner.
    // The notification list is refreshed from the backend on next init/refresh.
    final title = message.notification?.title ?? data['title'] as String? ?? '';
    final body = message.notification?.body ?? data['body'] as String? ?? '';
    final mapped = mapFcmDataToNotification({
      ...data,
      'title': title,
      'body': body,
    });
    if (mapped == null) return;

    _notificationsCtrl.onForegroundMessage(mapped);
    _foregroundStreamCtrl.add(mapped);
  }

  // ─── UUID v4 generation (no external dependency) ───────────────────────────

  String _generateUuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}'
        '-${hex.substring(12, 16)}-${hex.substring(16, 20)}'
        '-${hex.substring(20, 32)}';
  }
}
