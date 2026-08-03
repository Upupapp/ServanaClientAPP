// C21: This file is intentionally replaced.
// Screen tracking is now handled by ScreenAnalyticsObserver (GoRouter-compatible)
// registered in main.dart. The old NavigatorObserver approach was:
//   1. Never registered (dead code)
//   2. GoRouter-incompatible (route.settings.name always null)
//   3. Using deprecated setCurrentScreen() API
//   4. Not filtering modal sheets or dialog routes
//
// See: lib/core/analytics/application/screen_analytics_observer.dart
