/// App Store submission requirements that nothing else enforces.
///
/// Each of these is a rejection or a stalled upload, and none of them is
/// visible from `flutter analyze`, a widget test, or even a successful iOS
/// build — the app compiles perfectly well while failing every one of them.
/// They are checked here because file-level assertions under `flutter test`
/// are the only validation layer this project has for native config.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String p) => File(p).readAsStringSync();

Map<String, String> _plistStrings(String path) {
  final src = _read(path);
  final out = <String, String>{};
  for (final m in RegExp(r'<key>([^<]+)</key>\s*<string>([^<]*)</string>')
      .allMatches(src)) {
    out[m.group(1)!] = m.group(2)!;
  }
  return out;
}

void main() {
  group('device family', () {
    test('the app ships iPhone-only', () {
      // Was "1,2". Claiming iPad means Apple reviews on an iPad and requires
      // iPad screenshots — for a layout that has never been run on one. Ship
      // iPhone-only until iPad is actually supported and tested.
      final pbx = _read('ios/Runner.xcodeproj/project.pbxproj');
      expect(pbx, isNot(contains('TARGETED_DEVICE_FAMILY = "1,2"')),
          reason: 'iPad support is claimed but untested');
      expect(pbx, contains('TARGETED_DEVICE_FAMILY = "1"'));
    });

    test('Info.plist does not describe iPad orientations', () {
      // A leftover ~ipad key contradicts an iPhone-only target.
      expect(_read('ios/Runner/Info.plist'),
          isNot(contains('UISupportedInterfaceOrientations~ipad')));
    });
  });

  group('export compliance', () {
    test('ITSAppUsesNonExemptEncryption is declared', () {
      // Undeclared, App Store Connect asks on EVERY upload and holds the build
      // out of TestFlight until somebody answers.
      final src = _read('ios/Runner/Info.plist');
      expect(src, contains('<key>ITSAppUsesNonExemptEncryption</key>'),
          reason: 'declare it once here instead of answering per upload');
    });
  });

  group('privacy manifest', () {
    late final String manifest;

    setUpAll(() => manifest = _read('ios/Runner/PrivacyInfo.xcprivacy'));

    test('the file exists', () {
      expect(File('ios/Runner/PrivacyInfo.xcprivacy').existsSync(), isTrue,
          reason: 'required by Apple since May 2024');
    });

    test('it is copied into the app bundle', () {
      // The same failure mode GoogleService-Info.plist had: present on disk,
      // absent from the Runner target, so never in Runner.app. A manifest that
      // does not ship is a manifest Apple never sees.
      //
      // Resolved through the target graph so it cannot be satisfied by the
      // RunnerTests Resources phase.
      final pbx = _read('ios/Runner.xcodeproj/project.pbxproj');

      final fileRef = RegExp(
        r'([0-9A-F]{24}) /\* PrivacyInfo\.xcprivacy \*/ = \{isa = PBXFileReference',
      ).firstMatch(pbx);
      expect(fileRef, isNotNull,
          reason: 'no PBXFileReference for the manifest');

      final buildFile = RegExp(
        r'([0-9A-F]{24}) /\* PrivacyInfo\.xcprivacy in Resources \*/ = '
        r'\{isa = PBXBuildFile; fileRef = '
        '${fileRef!.group(1)}',
      ).firstMatch(pbx);
      expect(buildFile, isNotNull);

      final target = RegExp(
        r'[0-9A-F]{24} /\* Runner \*/ = \{\s*isa = PBXNativeTarget;'
        r'[\s\S]*?buildPhases = \(([\s\S]*?)\);',
      ).firstMatch(pbx);
      final phaseId = RegExp(r'([0-9A-F]{24}) /\* Resources \*/')
          .firstMatch(target!.group(1)!)!
          .group(1);
      final phase = RegExp(
        '$phaseId /\\* Resources \\*/ = \\{[\\s\\S]*?files = \\(([\\s\\S]*?)\\);',
      ).firstMatch(pbx);

      expect(phase!.group(1), contains(buildFile!.group(1)!),
          reason: 'PrivacyInfo.xcprivacy is not in the Runner target\'s '
              'Resources phase, so it never reaches Runner.app');
    });

    test('tracking is declared false and no tracking domains are listed', () {
      // The app shows no App Tracking Transparency prompt, so it cannot read
      // the advertising identifier. If an ATT prompt is ever added, this
      // declaration and the App Store Connect answers must change together.
      expect(manifest, contains('<key>NSPrivacyTracking</key>'));
      expect(
        RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>').hasMatch(manifest),
        isTrue,
      );
    });

    test('every data type the code actually collects is declared', () {
      // Verified against the source, not assumed. Under-declaring is a
      // compliance problem; over-declaring is a different one.
      for (final type in const [
        'NSPrivacyCollectedDataTypeName',
        'NSPrivacyCollectedDataTypeEmailAddress',
        'NSPrivacyCollectedDataTypePhoneNumber',
        'NSPrivacyCollectedDataTypePreciseLocation',
        'NSPrivacyCollectedDataTypePhotosorVideos',
        'NSPrivacyCollectedDataTypeProductInteraction',
        'NSPrivacyCollectedDataTypeCrashData',
      ]) {
        expect(manifest, contains(type), reason: '$type not declared');
      }
    });

    test('location is declared because the app really does send coordinates',
        () {
      // Ties the declaration to the code that justifies it, so removing the
      // feature and leaving the declaration (or the reverse) is visible.
      final tracking =
          _read('lib/modules/tracking/data/tracking_repository.dart');
      expect(tracking, contains('latitude'));
      expect(manifest, contains('NSPrivacyCollectedDataTypePreciseLocation'));
    });
  });

  group('purpose strings', () {
    late final Map<String, String> plist;

    setUpAll(() => plist = _plistStrings('ios/Runner/Info.plist'));

    test('each names the product and gives a specific reason', () {
      // App Review reads these verbatim. They previously said "Service app will
      // use you photos" — a typo, the wrong product name, and a photo
      // justification on the CAMERA key.
      for (final key in const [
        'NSCameraUsageDescription',
        'NSPhotoLibraryUsageDescription',
        'NSLocationWhenInUseUsageDescription',
        'NSLocationAlwaysAndWhenInUseUsageDescription',
      ]) {
        final v = plist[key];
        expect(v, isNotNull, reason: '$key missing');
        expect(v, contains('Servana'), reason: '$key must name the app');
        expect(v!.length, greaterThan(40),
            reason: '$key is too vague to survive review');
        expect(v, isNot(contains('Service app')),
            reason: '$key still uses the old wrong product name');
      }
    });

    test('the camera string is about the camera, not the photo library', () {
      expect(plist['NSCameraUsageDescription'], contains('camera'));
    });
  });

  group('payment data is not collected, and the manifest agrees', () {
    // All payments run through PayMongo hosted checkout in a WebView, so the
    // customer types their card on PayMongo's page and this app never sees it.
    // That is why NSPrivacyCollectedDataTypePaymentInfo is absent.
    //
    // These two tests are a pair: if card-entry UI ever comes back, the first
    // fails and forces whoever added it to also update the manifest and the
    // App Store Connect questionnaire. A declaration that quietly goes stale
    // is worse than one that was never made.

    test('no card-entry UI exists anywhere in lib/', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final src = entity.readAsStringSync();
        // Controllers/fields that would mean the app itself takes card input.
        if (RegExp(r'\b(cardNumber|cardCvv|cvv)\s*=\s*TextEditingController')
            .hasMatch(src)) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'card input found — the app would then COLLECT payment '
              'info, and PrivacyInfo.xcprivacy plus the App Store Connect '
              'questionnaire must declare it:\n${offenders.join('\n')}');
    });

    test('the manifest declares no payment info', () {
      final manifest = _read('ios/Runner/PrivacyInfo.xcprivacy');
      // Present in the explanatory comment, absent as a declaration.
      expect(
        RegExp(r'<string>NSPrivacyCollectedDataTypePaymentInfo</string>')
            .hasMatch(manifest),
        isFalse,
        reason: 'payments are handled off-device by PayMongo hosted checkout',
      );
    });

    test('PayMongo checkout is host-restricted', () {
      // The allowlist is what keeps checkout — and therefore card entry — on
      // PayMongo's own domain instead of anywhere a redirect points.
      final src =
          _read('lib/common/presentation/screens/payment_webview_screen.dart');
      expect(src, contains('checkout.paymongo.com'));
      expect(src, contains('_approvedHosts'));
    });
  });

  group('the native plists are valid XML', () {
    // Info.plist carried `--dart-define` inside an XML comment. A double hyphen
    // is illegal there, so the file was not well-formed XML. Xcode's parser is
    // lenient and the iOS build passed anyway, which is precisely why it went
    // unnoticed — but strict parsers reject the whole document, and App Store
    // submission runs one.
    for (final path in const [
      'ios/Runner/Info.plist',
      'ios/Runner/PrivacyInfo.xcprivacy',
      'ios/Runner/Runner.entitlements',
    ]) {
      test('$path has no double hyphen inside a comment', () {
        final src = _read(path);
        final offenders = <String>[];
        for (final c in RegExp(r'<!--(.*?)-->', dotAll: true).allMatches(src)) {
          if (c.group(1)!.contains('--')) {
            offenders.add(c.group(1)!.trim().split('\n').first);
          }
        }
        expect(offenders, isEmpty,
            reason: 'illegal "--" in an XML comment makes $path malformed:\n'
                '${offenders.join('\n')}');
      });

      test('$path opens and closes a plist dict', () {
        // A cheap structural check. Full XML parsing is not available to
        // `flutter test`, but an unbalanced document fails this.
        final src = _read(path);
        expect(src, contains('<plist version="1.0">'));
        expect(src.trimRight(), endsWith('</plist>'));
        expect(RegExp(r'<dict>').allMatches(src).length,
            RegExp(r'</dict>').allMatches(src).length,
            reason: 'unbalanced <dict> in $path');
        expect(RegExp(r'<array>').allMatches(src).length,
            RegExp(r'</array>').allMatches(src).length,
            reason: 'unbalanced <array> in $path');
      });
    }
  });

  group('build number', () {
    test('is ahead of the code already live on Play', () {
      // App Store Connect rejects a duplicate CFBundleVersion, and shipping a
      // tester build labelled identically to production makes triage guesswork.
      final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
          .firstMatch(_read('pubspec.yaml'))!
          .group(1)!;
      final build = int.parse(version.split('+').last);
      expect(build, greaterThan(36),
          reason: '36 is live on Play; bump before submitting');
    });
  });
}
