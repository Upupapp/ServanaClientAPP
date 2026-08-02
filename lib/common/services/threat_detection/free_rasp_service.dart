import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';

import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/threat_detection/provider/threat_detection_provider.dart';

/// freeRASP runtime protection.
///
/// Two things about this file are worth knowing before changing it.
///
/// **The signal is now consumed.** Every callback previously funnelled into a
/// single bool that no code anywhere read, so the app shipped an SDK that
/// detects root, hooks, debuggers, emulators and tampering and then discarded
/// every finding. Each threat is now recorded by type and reported to
/// Crashlytics as a non-fatal, so the detections actually reach somebody.
///
/// **Nothing is blocked.** Refusing to run on a threat signal is only safe once
/// the expected signing certificates are known to be correct, and the Play
/// app-signing certificate has not yet been confirmed — see [_signingCertHashes].
/// Locking out legitimate customers is a worse failure than the one blocking
/// would prevent, so enforcement is left as a deliberate, separate decision.
class FreeRasp {
  const FreeRasp._();

  /// Expected signing certificates, base64 SHA-256, as freeRASP expects them.
  ///
  /// This previously contained two hashes of unknown provenance —
  /// `ssaQxyc3v5...` and `Jvoir3o8k9...` — which matched neither the upload
  /// keystore nor the debug keystore. Nothing recorded where they came from.
  /// With a bare `onAppIntegrity` that set an unread flag, a mismatch had no
  /// consequence and so nobody noticed.
  ///
  /// The upload certificate below is verified: it is the SHA-256 of
  /// `upload-keystore.jks` (alias `upload`), base64-encoded.
  ///
  /// **Incomplete for Play.** With Play App Signing, Google re-signs the bundle
  /// with the APP SIGNING key, so a Play-installed build presents a different
  /// certificate from the one below. That hash must be taken from
  /// Play Console → App integrity → App signing key certificate and added here
  /// BEFORE any enforcement is switched on, or every Play customer would be
  /// flagged as tampered.
  ///
  /// The debug keystore hash is deliberately absent. Debug keys are trivially
  /// obtainable, so trusting one in a production build would make the check
  /// meaningless. Debug builds run with `isProd: false`, where freeRASP relaxes
  /// these checks anyway.
  static const List<String> _signingCertHashes = <String>[
    // upload-keystore.jks, alias `upload`
    'cCg2PG6Nv6NgZHnkPOyST2M/z/OO1qDWavjF36bfaCk=',
    // TODO(SC-167): add the Play app-signing certificate hash after the first
    // upload. Until then a Play-distributed build reports appIntegrity.
  ];

  static Future<void> initThreatDetection() async {
    final trigger = dpLocator<ThreatDetectionProvider>();

    final config = TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: 'com.servana.serviceclient',
        supportedStores: ['com.android.vending'],
        signingCertHashes: _signingCertHashes,
      ),
      // iosConfig is still unset, so freeRASP throws ConfigurationException on
      // iOS. main.dart now reports that instead of discarding it, which is how
      // it stayed invisible. Setting it needs the bundle id and team id.
      watcherMail: 'hcalmerin+freerasp@gmail.com',
      isProd: !kDebugMode,
    );

    // All 21 callbacks freeRASP 8.0.0 exposes. The 6.x integration wired 9,
    // and the 8.0.0 bump did not revisit the list — so the app was blind to
    // malware, screen recording, automation, ADB, VPN and spoofing.
    final callback = ThreatCallback(
      onAppIntegrity: () => _report(trigger, ServanaThreat.appIntegrity),
      onObfuscationIssues: () =>
          _report(trigger, ServanaThreat.obfuscationIssues),
      onHooks: () => _report(trigger, ServanaThreat.hooks),
      onDeviceBinding: () => _report(trigger, ServanaThreat.deviceBinding),
      onPrivilegedAccess: () =>
          _report(trigger, ServanaThreat.privilegedAccess),
      onSecureHardwareNotAvailable: () =>
          _report(trigger, ServanaThreat.secureHardwareNotAvailable),
      onPasscode: () => _report(trigger, ServanaThreat.passcode),
      onDeviceID: () => _report(trigger, ServanaThreat.deviceId),
      // Uniquely, onMalware carries a payload: the suspicious packages found.
      // The package list is NOT forwarded anywhere — it describes other apps on
      // the customer's device, which is not ours to collect. Only the count is
      // useful for triage, and even that stays local.
      onMalware: (_) => _report(trigger, ServanaThreat.malware),
      onMultiInstance: () => _report(trigger, ServanaThreat.multiInstance),
      onSystemVPN: () => _report(trigger, ServanaThreat.systemVpn),
      onUnsecureWiFi: () => _report(trigger, ServanaThreat.unsecureWifi),
      onTimeSpoofing: () => _report(trigger, ServanaThreat.timeSpoofing),
      onLocationSpoofing: () =>
          _report(trigger, ServanaThreat.locationSpoofing),
      onAutomation: () => _report(trigger, ServanaThreat.automation),
      // Screen capture needs DETECT_SCREEN_CAPTURE / DETECT_SCREEN_RECORDING
      // in AndroidManifest.xml, or freeRASP logs a registration failure at
      // launch and these never fire.
      onScreenshot: () => _report(trigger, ServanaThreat.screenshot),
      onScreenRecording: () => _report(trigger, ServanaThreat.screenRecording),
      // The next three are normal during development and would otherwise fire
      // on every developer's machine, drowning real signals in noise.
      onDebug: () => _reportUnlessDebugBuild(trigger, ServanaThreat.debug),
      onSimulator: () =>
          _reportUnlessDebugBuild(trigger, ServanaThreat.simulator),
      onDevMode: () => _reportUnlessDebugBuild(trigger, ServanaThreat.devMode),
      onADBEnabled: () =>
          _reportUnlessDebugBuild(trigger, ServanaThreat.adbEnabled),
      onUnofficialStore: () =>
          _reportUnlessDebugBuild(trigger, ServanaThreat.unofficialStore),
    );

    // Must be awaited on 8.x: it returns Future<void> and internally awaits
    // detachListener() before subscribing. Unawaited, start() below can hand
    // control to the native SDK before the Dart listener exists.
    await Talsec.instance.attachListener(callback);
    await Talsec.instance.start(config);
  }

  static void _report(ThreatDetectionProvider trigger, ServanaThreat threat) {
    trigger.report(threat);
    _sendToCrashlytics(threat);
  }

  static void _reportUnlessDebugBuild(
      ThreatDetectionProvider trigger, ServanaThreat threat) {
    if (kDebugMode) return;
    _report(trigger, threat);
  }

  /// Reports a detection as a non-fatal.
  ///
  /// Non-fatal because the app keeps working: recording these as crashes would
  /// misstate the crash rate, and a crash-rate metric nobody trusts is a metric
  /// nobody reads.
  ///
  /// Only the threat's name is sent. Nothing here identifies the customer or
  /// the device.
  static void _sendToCrashlytics(ServanaThreat threat) {
    try {
      FirebaseCrashlytics.instance.recordError(
        'freerasp_threat:${threat.id}',
        StackTrace.current,
        reason: 'freeRASP runtime threat detected',
        fatal: false,
      );
    } catch (_) {
      // Reporting must never be the thing that breaks the app.
    }
  }
}
