import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:client/common/domain/version_gate/version_gate.dart';
import 'package:client/common/domain/version_gate/version_gate_coordinator.dart';

/// Wraps the app and replaces it entirely when this build is no longer
/// supported (TAB 15).
///
/// Mounted as the OUTERMOST wrapper in `MaterialApp.builder`, so a blocked
/// build cannot reach a route, a banner or an authenticated request. The gate
/// must run before the first authenticated call, and the only way to guarantee
/// that from the widget tree is to sit above everything that could make one.
///
/// ## It fails open, loudly and by default
///
/// Every failure path — no config, unreadable build number, a throw anywhere in
/// evaluation — resolves to showing the app. The gate may block the app; it may
/// never break it. Until the first evaluation completes the child renders
/// normally, because a splash screen gating on a network call is the same
/// outage in a nicer costume.
///
/// ## Its own lifecycle observer
///
/// `AppLifecycleCoordinator` already exists and already fans out `onResume`,
/// but its callback is wired in `main.dart` to the messaging store. Registering
/// a second observer here keeps the gate self-contained and removes any
/// ordering question between the two — Flutter supports multiple observers, and
/// a build can become unsupported while it sits in the background, so resume is
/// not optional.
class VersionGateBarrier extends StatefulWidget {
  const VersionGateBarrier({
    super.key,
    required this.child,
    this.coordinator,
  });

  final Widget child;

  /// Injectable for tests.
  final VersionGateCoordinator? coordinator;

  @override
  State<VersionGateBarrier> createState() => _VersionGateBarrierState();
}

class _VersionGateBarrierState extends State<VersionGateBarrier>
    with WidgetsBindingObserver {
  late final VersionGateCoordinator _coordinator;
  VersionGateDecision _decision = VersionGateDecision.allowed;
  bool _promptDismissed = false;

  @override
  void initState() {
    super.initState();
    _coordinator = widget.coordinator ?? VersionGateCoordinator();
    WidgetsBinding.instance.addObserver(this);
    _evaluate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _evaluate();
  }

  Future<void> _evaluate() async {
    final decision = await _coordinator.evaluate();
    if (!mounted) return;
    setState(() {
      _decision = decision;
      // A fresh evaluation re-arms the prompt; the frequency cap in the
      // coordinator is what stops that becoming a nag.
      if (decision != VersionGateDecision.recommendUpdate) {
        _promptDismissed = false;
      }
    });
    if (decision == VersionGateDecision.recommendUpdate) {
      await _coordinator.recordSoftPromptShown();
    }
  }

  Future<void> _openStore() async {
    // Android first: Play's immediate in-app update keeps the customer in the
    // app. The store link is the fallback, and the only path on iOS.
    if (await _coordinator.tryAndroidImmediateUpdate()) return;
    final url = _coordinator.storeUrl();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // A dead store link must not crash the blocking screen — the customer
      // would then have neither the app nor a way out of it.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_decision == VersionGateDecision.blocked) {
      return _UpdateRequiredScreen(
        message: _coordinator.config?.message ?? '',
        onUpdate: _openStore,
      );
    }

    if (_decision == VersionGateDecision.recommendUpdate && !_promptDismissed) {
      return Stack(
        children: [
          widget.child,
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _UpdateAvailableBanner(
              onUpdate: _openStore,
              onDismiss: () => setState(() => _promptDismissed = true),
            ),
          ),
        ],
      );
    }

    return widget.child;
  }
}

/// The hard block. No dismissal, and it must say why.
///
/// A dead end with no explanation generates one-star reviews that outlive the
/// incident, so the copy states the reason and offers the store.
class _UpdateRequiredScreen extends StatelessWidget {
  const _UpdateRequiredScreen({required this.message, required this.onUpdate});

  final String message;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            // Scrollable: this screen must survive the largest supported text
            // scale on the smallest supported viewport. A clipped "Update"
            // button here is a customer with no way forward at all.
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.system_update,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      'Update required',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.isEmpty
                        ? 'This version of Servana is no longer supported. '
                            'Please update to continue booking services.'
                        : message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onUpdate,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Update now'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The soft prompt. Dismissible, and frequency-capped by the coordinator.
class _UpdateAvailableBanner extends StatelessWidget {
  const _UpdateAvailableBanner({
    required this.onUpdate,
    required this.onDismiss,
  });

  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'A newer version of Servana is available.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(onPressed: onUpdate, child: const Text('Update')),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
