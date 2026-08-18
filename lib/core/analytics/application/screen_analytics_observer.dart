import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../domain/analytics_event.dart';
import 'analytics_coordinator.dart';

// GoRouter-compatible screen analytics observer.
// Listens to route changes via GoRouter.routerDelegate and emits canonical
// screen_view events. Does NOT fire on widget rebuilds, only on route changes.
//
// Screen names are mapped from route paths using _canonicalScreenName() which
// strips dynamic path parameters (prevents booking IDs etc. entering analytics).
class ScreenAnalyticsObserver {
  ScreenAnalyticsObserver({
    required GoRouter router,
    required AnalyticsCoordinator coordinator,
  })  : _router = router,
        _coordinator = coordinator;

  final GoRouter _router;
  final AnalyticsCoordinator _coordinator;
  String? _lastScreen;

  void attach() {
    _router.routerDelegate.addListener(_onRouteChange);
  }

  void detach() {
    _router.routerDelegate.removeListener(_onRouteChange);
  }

  void _onRouteChange() {
    try {
      final uri = _router.routerDelegate.currentConfiguration.uri;
      final screenName = _canonicalScreenName(uri.path);
      if (screenName == null) return;
      if (screenName == _lastScreen) return; // no duplicate on same screen
      final prev = _lastScreen;
      _lastScreen = screenName;
      _coordinator.track(ScreenViewEvent(
        screenName: screenName,
        previousScreen: prev,
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('[ScreenObserver] error: $e');
    }
  }

  // Maps dynamic GoRouter paths to stable canonical screen names.
  // Dynamic segments (numeric IDs, UUIDs, ticket keys) are replaced with
  // a canonical placeholder so they never enter analytics as high-cardinality
  // or potentially identifying values.
  static String? _canonicalScreenName(String path) {
    // Normalise trailing slash
    final p = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;

    // Exact matches first
    const exact = <String, String>{
      '/': 'home',
      '/home': 'home',
      '/splash': 'splash',
      '/welcome': 'welcome',
      '/auth': 'auth',
      '/auth/login': 'sign_in',
      '/auth/register': 'registration',
      '/bookings': 'bookings',
      '/messages': 'messages',
      '/profile': 'profile',
      '/profile/edit': 'profile_edit',
      '/profile/email-verify': 'email_verification',
      '/search': 'search',
      '/categories': 'categories',
      '/notifications': 'notifications',
      '/settings': 'settings',
      '/settings/appearance': 'settings_appearance',
      '/settings/language': 'settings_language',
      '/settings/permissions': 'settings_permissions',
      '/settings/security': 'settings_security',
      '/settings/privacy': 'settings_privacy',
      '/settings/about': 'settings_about',
      '/support': 'support',
      '/support/tickets': 'support_tickets',
      '/support/new': 'support_create',
      '/support/safety': 'support_safety',
      '/support/help': 'support_help',
    };

    if (exact.containsKey(p)) return exact[p];

    // Pattern matches — strip dynamic segments
    if (_matchesPattern(p, r'^/bookings/[^/]+$')) return 'booking_detail';
    if (_matchesPattern(p, r'^/bookings/[^/]+/payment$')) {
      return 'payment_webview';
    }
    if (_matchesPattern(p, r'^/bookings/[^/]+/otp$')) return 'booking_otp';
    if (_matchesPattern(p, r'^/bookings/[^/]+/confirm$')) {
      return 'booking_confirmation';
    }
    if (_matchesPattern(p, r'^/bookings/[^/]+/track$')) return 'tracking';
    if (_matchesPattern(p, r'^/bookings/[^/]+/chat$')) return 'conversation';
    if (_matchesPattern(p, r'^/messages/[^/]+$')) return 'conversation';
    if (_matchesPattern(p, r'^/support/tickets/[^/]+$')) {
      return 'support_ticket_detail';
    }
    if (_matchesPattern(p, r'^/review/new$')) return 'review_form';
    if (_matchesPattern(p, r'^/review/detail$')) return 'review_detail';
    if (_matchesPattern(p, r'^/categories/[^/]+$')) return 'category_detail';
    if (_matchesPattern(p, r'^/services/[^/]+$')) return 'service_detail';

    // Aircon / Beauty booking sub-screens
    if (_matchesPattern(p, r'^/book/aircon')) return 'booking_aircon';
    if (_matchesPattern(p, r'^/book/beauty')) return 'booking_beauty';

    // Unknown route — return null to skip (don't log dynamic noise)
    if (kDebugMode) debugPrint('[ScreenObserver] unmapped route: $p');
    return null;
  }

  static bool _matchesPattern(String path, String pattern) =>
      RegExp(pattern).hasMatch(path);
}
