import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/notifications/application/fcm_coordinator.dart';
import 'package:client/modules/notifications/application/notification_navigation_coordinator.dart';
import 'package:client/modules/notifications/domain/servana_notification.dart';
import 'package:flutter/material.dart';

/// Wraps [child] and overlays an in-app banner whenever a foreground FCM
/// message arrives. Place this high in the widget tree (e.g. wrapping the
/// root navigator) so it appears on all screens.
class ForegroundNotificationBanner extends StatefulWidget {
  final FcmCoordinator fcmCoordinator;
  final NotificationNavigationCoordinator navigationCoordinator;
  final Widget child;

  const ForegroundNotificationBanner({
    super.key,
    required this.fcmCoordinator,
    required this.navigationCoordinator,
    required this.child,
  });

  @override
  State<ForegroundNotificationBanner> createState() =>
      _ForegroundNotificationBannerState();
}

class _ForegroundNotificationBannerState
    extends State<ForegroundNotificationBanner>
    with SingleTickerProviderStateMixin {
  StreamSubscription<ServanaNotification>? _sub;
  ServanaNotification? _current;
  Timer? _dismissTimer;

  late final AnimationController _anim;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _sub = widget.fcmCoordinator.foregroundStream.listen(_onNotification);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dismissTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _onNotification(ServanaNotification notification) {
    if (!mounted) return;
    setState(() => _current = notification);
    _anim.forward(from: 0);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _anim.reverse().then((_) {
      if (mounted) setState(() => _current = null);
    });
  }

  void _onTap() {
    _dismiss();
    final notif = _current;
    if (notif != null && context.mounted) {
      widget.navigationCoordinator.navigateTo(context, notif);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slide,
              child: _Banner(
                notification: _current!,
                onTap: _onTap,
                onDismiss: _dismiss,
              ),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final ServanaNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _Banner({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // [a11y] The banner is restructured as a Stack so the "dismiss" button
    // lives outside the banner's own Semantics(excludeSemantics: true) node.
    // This lets TalkBack / VoiceOver reach both independently:
    //   1. Banner tap → navigates to notification detail.
    //   2. Dismiss button → closes the banner (44×44 touch target).
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // ── Tappable banner body ──────────────────────────────────────────
          Semantics(
            label: '${notification.title}: ${notification.safeBody}',
            button: true,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                // Right padding reserves space for the 44 px dismiss button.
                padding: const EdgeInsets.fromLTRB(14, 12, 58, 12),
                decoration: BoxDecoration(
                  color: ColorPalette.secondaryText,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        size: 17,
                        color: ColorPalette.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            notification.safeBody,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Dismiss button overlay (44×44 touch target) ──────────────────
          Semantics(
            label: 'Dismiss notification',
            button: true,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onDismiss,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
