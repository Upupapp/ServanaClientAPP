import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/notifications/application/notification_navigation_coordinator.dart';
import 'package:client/modules/notifications/application/notifications_controller.dart';
import 'package:client/modules/notifications/application/notifications_state.dart';
import 'package:client/modules/notifications/presentation/notification_card.dart';
import 'package:client/modules/notifications/presentation/notification_empty_state.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  static String routeName = "Notifications";
  static String route = "/Notifications";
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsController _ctrl;
  late final NotificationNavigationCoordinator _navCoord;

  @override
  void initState() {
    super.initState();
    _ctrl = dpLocator<NotificationsController>();
    _navCoord = dpLocator<NotificationNavigationCoordinator>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: _ctrl,
            builder: (_, __) {
              if (_ctrl.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: _ctrl.markAllRead,
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final state = _ctrl.state;

    if (state == NotificationsLoadState.loading &&
        _ctrl.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    if (state == NotificationsLoadState.error && _ctrl.notifications.isEmpty) {
      return _ErrorView(
        message: _ctrl.error ?? 'Unable to load notifications.',
        onRetry: _ctrl.refresh,
      );
    }

    if (_ctrl.isEmpty) {
      return const NotificationEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _ctrl.refresh,
      color: ColorPalette.primaryColorDark,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _ctrl.notifications.length +
            (state == NotificationsLoadState.error ? 1 : 0),
        itemBuilder: (context, i) {
          if (state == NotificationsLoadState.error &&
              i == _ctrl.notifications.length) {
            return _OfflineBanner(onRetry: _ctrl.refresh);
          }
          final notif = _ctrl.notifications[i];
          return NotificationCard(
            key: ValueKey(notif.notificationKey),
            notification: notif,
            onTap: () {
              if (notif.canMarkRead && !notif.isRead) {
                _ctrl.markRead(notif.notificationKey);
              }
              if (notif.canOpenDetail) {
                _navCoord.navigateTo(context, notif);
              }
            },
            onMarkRead: notif.canMarkRead
                ? () => _ctrl.markRead(notif.notificationKey)
                : null,
            onDismiss: notif.canDismiss
                ? () => _ctrl.dismiss(notif.notificationKey)
                : null,
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48, color: ColorPalette.accentText.withOpacity(0.35)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 13,
                color: ColorPalette.accentText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.primaryColorDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 16, color: ColorPalette.accentText.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing cached notifications',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 12,
                color: ColorPalette.accentText,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorPalette.primaryColorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
