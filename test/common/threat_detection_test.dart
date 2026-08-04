/// SC-166 / SC-167 / SC-179 — the freeRASP signal, its expected certificates,
/// and the permissions its detectors need.
///
/// The defect these guard against is not a crash. It is an SDK that detects
/// root, hooks, debuggers and tampering, and reports to nothing — which looks
/// perfectly healthy from the outside and cost nothing to notice for months.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/common/services/threat_detection/free_rasp_service.dart';
import 'package:client/common/services/threat_detection/provider/threat_detection_provider.dart';

String _read(String p) => File(p).readAsStringSync();

void main() {
  group('SC-166 the threat signal is observable', () {
    test('a fresh provider reports nothing', () {
      final p = ThreatDetectionProvider();
      expect(p.isUnderThreat, isFalse);
      expect(p.detected, isEmpty);
      expect(p.indicatesTampering, isFalse);
    });

    test('a reported threat is recorded and notifies once', () {
      final p = ThreatDetectionProvider();
      var notifications = 0;
      p.addListener(() => notifications++);

      p.report(ServanaThreat.hooks);
      expect(p.isUnderThreat, isTrue);
      expect(p.detected, contains(ServanaThreat.hooks));
      expect(notifications, 1);
    });

    test('repeats are idempotent and do not re-notify', () {
      // Screenshot detection fires on every screenshot; re-notifying each time
      // would rebuild listeners for no new information.
      final p = ThreatDetectionProvider();
      var notifications = 0;
      p.addListener(() => notifications++);

      p.report(ServanaThreat.screenshot);
      p.report(ServanaThreat.screenshot);
      p.report(ServanaThreat.screenshot);
      expect(notifications, 1);
      expect(p.detected.length, 1);
    });

    test('distinct threats accumulate', () {
      final p = ThreatDetectionProvider();
      p.report(ServanaThreat.systemVpn);
      p.report(ServanaThreat.devMode);
      expect(p.detected.length, 2);
    });

    test('tampering is distinguished from an unusual device state', () {
      // A rooted phone is a risk judgement; a modified APK is a different
      // category of problem. Collapsing them is why one flag was useless.
      final tampering = ThreatDetectionProvider()..report(ServanaThreat.hooks);
      expect(tampering.indicatesTampering, isTrue);

      final environmental = ThreatDetectionProvider()
        ..report(ServanaThreat.unsecureWifi);
      expect(environmental.isUnderThreat, isTrue);
      expect(environmental.indicatesTampering, isFalse,
          reason: 'an unsecured network does not imply a modified binary');
    });

    test('reset clears state so threats do not cross customers', () {
      final p = ThreatDetectionProvider()..report(ServanaThreat.malware);
      p.reset();
      expect(p.isUnderThreat, isFalse);
      expect(p.detected, isEmpty);
    });

    test('the detected set cannot be mutated by callers', () {
      final p = ThreatDetectionProvider()..report(ServanaThreat.debug);
      expect(() => p.detected.add(ServanaThreat.hooks), throwsUnsupportedError);
    });
  });

  group('SC-167 expected signing certificates', () {
    final src =
        _read('lib/common/services/threat_detection/free_rasp_service.dart');

    test('the two hashes of unknown provenance are gone', () {
      // Neither matched the upload keystore nor the debug keystore, and nothing
      // recorded where they came from.
      expect(
          src, isNot(contains('ssaQxyc3v5MGw1TAFt/hRaX72HO0/7kHNDRiEKMPiTc=')));
      expect(
          src, isNot(contains('Jvoir3o8k9PewO8IzTOaFfM0rEtY1OuvxRbl5TtKs6M=')));
    });

    test('the pinned hash is the real upload certificate', () {
      // SHA-256 of upload-keystore.jks (alias `upload`), base64-encoded:
      //   70:28:36:3C:6E:8D:...:68:29
      const expected = 'cCg2PG6Nv6NgZHnkPOyST2M/z/OO1qDWavjF36bfaCk=';
      expect(src, contains(expected));

      // Confirm the constant really is that fingerprint, rather than a string
      // that merely looks plausible.
      final bytes = base64Decode(expected);
      expect(bytes.length, 32, reason: 'SHA-256 is 32 bytes');
      final hex = bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(':')
          .toUpperCase();
      expect(hex.startsWith('70:28:36:3C:6E:8D'), isTrue);
      expect(hex.endsWith('68:29'), isTrue);
    });

    test('the debug keystore hash is NOT trusted in the shipped config', () {
      // Debug keys are trivially obtainable; trusting one would make the
      // integrity check meaningless.
      const debugHash = 'rJfat06wyGBytYV4AD0PPSrbSJ/N7QMXB6YeLSwDDaU=';
      expect(src, isNot(contains(debugHash)));
    });

    test('the Play app-signing certificate is trusted too', () {
      // Google re-signs the bundle, so a Play install presents ITS certificate,
      // not the upload key. Trusting only the upload key would flag every Play
      // customer as tampered.
      const play = 'edkdY6UscFjH0pf2nd2b18P8nuq9bYK6S1fJQpgpHbE=';
      expect(src, contains(play));

      final bytes = base64Decode(play);
      expect(bytes.length, 32);
      final hex = bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(':')
          .toUpperCase();
      expect(hex.startsWith('79:D9:1D:63'), isTrue);
      expect(hex.endsWith('1D:B1'), isTrue);
    });

    test('both delivery channels are covered', () {
      // Play installs present the app-signing cert; Firebase App Distribution
      // builds never pass through Play and present the upload cert. Dropping
      // either breaks that channel.
      expect(src, contains('edkdY6UscFjH0pf2nd2b18P8nuq9bYK6S1fJQpgpHbE='));
      expect(src, contains('cCg2PG6Nv6NgZHnkPOyST2M/z/OO1qDWavjF36bfaCk='));
    });
  });

  group('freeRASP 8 callback coverage', () {
    final src =
        _read('lib/common/services/threat_detection/free_rasp_service.dart');

    test('every callback freeRASP 8.0.0 exposes is wired', () {
      // The 6.x integration wired 9 of 21; the 8.0.0 bump did not revisit the
      // list, leaving the app blind to malware, screen recording, automation,
      // ADB, VPN and spoofing.
      const callbacks = [
        'onAppIntegrity',
        'onObfuscationIssues',
        'onHooks',
        'onDeviceBinding',
        'onPrivilegedAccess',
        'onSecureHardwareNotAvailable',
        'onPasscode',
        'onDeviceID',
        'onMalware',
        'onMultiInstance',
        'onSystemVPN',
        'onUnsecureWiFi',
        'onTimeSpoofing',
        'onLocationSpoofing',
        'onAutomation',
        'onScreenshot',
        'onScreenRecording',
        'onDebug',
        'onSimulator',
        'onDevMode',
        'onADBEnabled',
        'onUnofficialStore',
      ];
      final missing = callbacks.where((c) => !src.contains('$c:')).toList();
      expect(missing, isEmpty, reason: 'unwired freeRASP callbacks: $missing');
    });

    test('detections are reported somewhere a human will see them', () {
      // The whole point of SC-166: a signal nobody receives is not protection.
      expect(src, contains('FirebaseCrashlytics'));
      expect(src, contains('fatal: false'),
          reason: 'a working app must not inflate the crash rate');
    });

    test('the malware payload is not collected', () {
      // onMalware carries the list of suspicious packages on the device. That
      // describes other apps the customer installed and is not ours to gather.
      expect(src, contains('onMalware: (_) =>'),
          reason: 'the payload must be discarded at the callback boundary');
    });
  });

  group('SC-179 screen-capture permissions', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');

    test('both detectors have the permission they need', () {
      // Without these, freeRASP logs TalsecScreenProtector registration
      // failures at every launch and the callbacks never fire — so the
      // protection is silently inactive.
      expect(manifest, contains('android.permission.DETECT_SCREEN_CAPTURE'));
      expect(manifest, contains('android.permission.DETECT_SCREEN_RECORDING'));
    });

    test('no runtime-dangerous permission was added alongside them', () {
      // These are install-time permissions with no prompt. If a future edit
      // pulls in something that needs a runtime grant, that is a product
      // decision and should not ride in on a security fix.
      for (final dangerous in const [
        'READ_MEDIA_IMAGES',
        'READ_EXTERNAL_STORAGE',
        'RECORD_AUDIO',
        'SYSTEM_ALERT_WINDOW',
      ]) {
        expect(manifest, isNot(contains(dangerous)), reason: dangerous);
      }
    });
  });

  group('freeRASP starts or declines — it never throws on launch', () {
    // The iOS regression: `iosConfig` was absent, so IOSConfig's verifier threw
    // ConfigurationException on every iOS launch. main.dart caught it and filed
    // a non-fatal, so the app looked healthy while carrying no protection at
    // all. Declining to start is a legitimate outcome; throwing is not.
    //
    // flutter_test reports TargetPlatform.android, so this exercises the
    // Android branch directly and the others by construction.

    test('android is always configured', () {
      expect(defaultTargetPlatform, TargetPlatform.android,
          reason: 'flutter_test defaults to android; if this changes, the '
              'expectation below is testing something else');
      expect(FreeRasp.isConfiguredForCurrentPlatform, isTrue);
    });

    test('iOS is configured by default, without needing a build flag', () {
      // The team id defaults to the real one rather than coming only from
      // --dart-define. Sourcing it exclusively from the flag meant forgetting
      // the flag shipped iOS with no protection and nothing said so.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(FreeRasp.isConfiguredForCurrentPlatform, isTrue,
          reason: 'iOS must be protected out of the box');
    });

    test('the default team id is the one that owns the App ID', () {
      // UPUP TECHNOLOGIES PTE. LTD — the team holding com.servana.client.
      // A wrong team id makes freeRASP report every legitimate install as
      // tampered, so it is pinned rather than left to a comment.
      final src =
          _read('lib/common/services/threat_detection/free_rasp_service.dart');
      expect(src, contains("defaultValue: '2K2SF7NRQP'"));

      final teamId =
          RegExp(r"defaultValue: '([^']+)'").firstMatch(src)!.group(1)!;
      expect(teamId.length, 10,
          reason: 'an Apple Team ID is 10 characters; "$teamId" is not');
      expect(RegExp(r'^[A-Z0-9]{10}$').hasMatch(teamId), isTrue);
    });

    test('desktop platforms decline rather than throw', () {
      for (final p in const [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        debugDefaultTargetPlatformOverride = p;
        expect(FreeRasp.isConfiguredForCurrentPlatform, isFalse, reason: '$p');
      }
      debugDefaultTargetPlatformOverride = null;
    });

    test('the iOS bundle id it would register matches the Xcode target', () {
      // A freeRASP bundle id that does not match what Xcode builds reports
      // every legitimate install as tampered.
      final src =
          _read('lib/common/services/threat_detection/free_rasp_service.dart');
      final pbx = _read('ios/Runner.xcodeproj/project.pbxproj');
      final declared =
          RegExp(r"_iosBundleId = '([^']+)'").firstMatch(src)?.group(1);

      expect(declared, isNotNull, reason: '_iosBundleId not found');
      expect(pbx, contains('PRODUCT_BUNDLE_IDENTIFIER = $declared;'));
    });
  });
}
