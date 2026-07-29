import 'package:client/core/recovery/connectivity_monitor.dart';
import 'package:flutter/widgets.dart';

/// Bridges Flutter's AppLifecycle events to recovery subsystems.
///
/// Wire once in [main.dart] by calling [attach] after the first frame.
/// Inject only what's needed — no service-locator calls inside this class.
///
/// On resume:
///   1. Forces a connectivity probe so the [ConnectivityMonitor] reflects
///      current network state before any API calls fire.
///   2. Calls [onResume] so callers can trigger socket reconnect checks,
///      pending-payment reconciliation, etc.
class AppLifecycleCoordinator with WidgetsBindingObserver {
  AppLifecycleCoordinator({
    required ConnectivityMonitor connectivity,
    this.onResume,
    this.onBackground,
    this.onDetach,
  }) : _connectivity = connectivity;

  final ConnectivityMonitor _connectivity;

  /// Called when the app returns to the foreground (after [ConnectivityMonitor]
  /// has been triggered to probe). Wire socket reconnect, payment poll, etc.
  final VoidCallback? onResume;

  /// Called when the app moves to background / becomes inactive.
  final VoidCallback? onBackground;

  /// Called on Android's detach (process-kill signal, best-effort).
  final VoidCallback? onDetach;

  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    if (!_attached) return;
    WidgetsBinding.instance.removeObserver(this);
    _attached = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _connectivity.checkNow();
        onResume?.call();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        onBackground?.call();
      case AppLifecycleState.detached:
        onDetach?.call();
      case AppLifecycleState.hidden:
        break;
    }
  }
}
