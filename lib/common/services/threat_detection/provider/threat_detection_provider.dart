import 'package:flutter/widgets.dart';

/// A runtime threat reported by freeRASP.
///
/// Typed rather than a bare bool so the signal can be acted on proportionally.
/// "The device is rooted" and "a screenshot was taken" are both threats and
/// warrant completely different responses; collapsing them into one flag makes
/// that impossible, which is part of why the old flag was never consumed.
enum ServanaThreat {
  appIntegrity,
  obfuscationIssues,
  hooks,
  debug,
  passcode,
  deviceId,
  simulator,
  deviceBinding,
  unofficialStore,
  privilegedAccess,
  secureHardwareNotAvailable,
  systemVpn,
  devMode,
  adbEnabled,
  malware,
  screenshot,
  screenRecording,
  multiInstance,
  unsecureWifi,
  timeSpoofing,
  locationSpoofing,
  automation;

  /// Stable, low-cardinality identifier for logging and crash reports.
  String get id => name;

  /// Whether this indicates the app itself may have been tampered with, as
  /// opposed to the device merely being in an unusual state.
  ///
  /// The distinction matters: a customer on a rooted phone is a risk judgement,
  /// but a modified APK is a different category of problem.
  bool get indicatesTampering => switch (this) {
        ServanaThreat.appIntegrity ||
        ServanaThreat.hooks ||
        ServanaThreat.malware ||
        ServanaThreat.obfuscationIssues =>
          true,
        _ => false,
      };
}

/// Holds what freeRASP has reported this session.
///
/// This was previously a single bool that nothing anywhere read — the app
/// shipped an SDK detecting root, hooks, debuggers, emulators and tampering,
/// and discarded every finding. It now records what was seen and notifies
/// listeners, so the signal can be observed, reported and acted on.
///
/// It deliberately does NOT block the app. Blocking on an integrity signal
/// whose expected certificate hashes cannot yet be verified against Play would
/// risk locking out legitimate customers — a worse failure than the one it
/// prevents. Making the signal real and visible is the prerequisite; what
/// policy to enforce on top is a separate, deliberate decision.
class ThreatDetectionProvider extends ChangeNotifier {
  final Set<ServanaThreat> _detected = <ServanaThreat>{};

  /// Every distinct threat seen since launch.
  Set<ServanaThreat> get detected => Set.unmodifiable(_detected);

  /// True once anything at all has been reported.
  bool get isUnderThreat => _detected.isNotEmpty;

  /// True when something suggests the app binary itself was modified.
  bool get indicatesTampering => _detected.any((t) => t.indicatesTampering);

  /// Records a threat. Repeats are idempotent and do not re-notify.
  ///
  /// freeRASP fires some callbacks repeatedly — screenshot detection fires on
  /// every screenshot — and re-notifying each time would rebuild listeners for
  /// no new information.
  void report(ServanaThreat threat) {
    if (_detected.add(threat)) {
      notifyListeners();
    }
  }

  /// Clears state, so one customer's session does not carry a threat flag into
  /// the next. Called on logout.
  void reset() {
    if (_detected.isEmpty) return;
    _detected.clear();
    notifyListeners();
  }
}
