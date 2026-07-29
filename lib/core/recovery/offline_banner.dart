import 'package:client/core/recovery/connectivity_monitor.dart';
import 'package:client/core/recovery/network_state.dart';
import 'package:flutter/material.dart';

/// Wraps [child] and inserts a non-intrusive offline strip at the top whenever
/// [ConnectivityMonitor] reports [NetworkState.offline].
///
/// Animates in/out with a vertical slide. Announces the state change to
/// screen-readers via [Semantics].
///
/// Usage:
/// ```dart
/// OfflineBanner(
///   monitor: dpLocator<ConnectivityMonitor>(),
///   child: child,
/// )
/// ```
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({
    super.key,
    required this.monitor,
    required this.child,
  });

  final ConnectivityMonitor monitor;
  final Widget child;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _slide;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    widget.monitor.addListener(_onStateChange);
    _applyState(widget.monitor.state, animate: false);
  }

  void _onStateChange() => _applyState(widget.monitor.state);

  void _applyState(NetworkState s, {bool animate = true}) {
    final nowOffline = s == NetworkState.offline;
    if (nowOffline == _offline) return;
    setState(() => _offline = nowOffline);
    if (animate) {
      if (nowOffline) {
        _anim.forward();
      } else {
        _anim.reverse();
      }
    } else {
      _anim.value = nowOffline ? 1.0 : 0.0;
    }
  }

  @override
  void dispose() {
    widget.monitor.removeListener(_onStateChange);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizeTransition(
          sizeFactor: _slide,
          axisAlignment: -1.0,
          child: Semantics(
            liveRegion: true,
            label: _offline
                ? 'No internet connection. Some features may be unavailable.'
                : 'Internet connection restored.',
            child: _OfflineStrip(offline: _offline),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip({required this.offline});
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Colors.transparent,
      child: ColoredBox(
        color: Color(0xFFB71C1C),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 15, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No internet connection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
