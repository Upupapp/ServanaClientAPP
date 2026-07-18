import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

class AnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: route.settings.name);
  }
}
