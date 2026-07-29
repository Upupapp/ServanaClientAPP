import 'dart:async';
import 'dart:io';

import 'package:client/core/recovery/network_state.dart';
import 'package:flutter/foundation.dart';

/// Monitors TCP reachability and broadcasts [NetworkState] changes.
///
/// Implementation: Opens a TCP socket to a well-known IP (no DNS involved)
/// using [dart:io] — no additional packages required.
///
/// Probe rate:
///   • Online  → every 30 s (low overhead).
///   • Offline → every 5 s (fast recovery detection).
///
/// Call [checkNow] after app resume (from [AppLifecycleCoordinator]) to force
/// an immediate probe without waiting for the next scheduled tick.
class ConnectivityMonitor extends ChangeNotifier {
  ConnectivityMonitor() {
    _scheduleNext();
  }

  NetworkState _state = NetworkState.unknown;
  NetworkState get state => _state;

  bool get isOnline => _state == NetworkState.online;
  bool get isOffline => _state == NetworkState.offline;

  final _ctrl = StreamController<NetworkState>.broadcast();

  /// Emits on every state transition (not on unchanged re-checks).
  Stream<NetworkState> get onStateChange => _ctrl.stream;

  Timer? _timer;
  bool _disposed = false;
  bool _checking = false;

  // Google's public DNS IP — chosen because it's globally routable, stable,
  // and doesn't require DNS resolution itself.
  static const String _probeHost = '8.8.8.8';
  static const int _probePort = 53;
  static const Duration _probeTimeout = Duration(seconds: 5);
  static const Duration _onlineInterval = Duration(seconds: 30);
  static const Duration _offlineInterval = Duration(seconds: 5);

  // ── Public ───────────────────────────────────────────────────────────────

  /// Force an immediate reachability check (e.g. called by [AppLifecycleCoordinator]
  /// on app resume). Safe to call concurrently — concurrent calls are no-ops.
  Future<void> checkNow() => _probe();

  // ── Internal ─────────────────────────────────────────────────────────────

  void _scheduleNext() {
    _timer?.cancel();
    if (_disposed) return;
    final interval =
        _state == NetworkState.offline ? _offlineInterval : _onlineInterval;
    _timer = Timer(interval, _probe);
  }

  Future<void> _probe() async {
    if (_disposed || _checking) return;
    _checking = true;
    try {
      final reachable = await _isReachable();
      if (_disposed) return;
      _setState(reachable ? NetworkState.online : NetworkState.offline);
    } finally {
      _checking = false;
      _scheduleNext();
    }
  }

  void _setState(NetworkState next) {
    if (_state == next) return;
    _state = next;
    if (!_ctrl.isClosed) _ctrl.add(next);
    notifyListeners();
  }

  static Future<bool> _isReachable() async {
    try {
      final socket = await Socket.connect(
        _probeHost,
        _probePort,
        timeout: _probeTimeout,
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    if (!_ctrl.isClosed) _ctrl.close();
    super.dispose();
  }
}
