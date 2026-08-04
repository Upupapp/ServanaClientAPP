/// One Firebase project, and iOS/Android config that agrees with it.
///
/// Two separate failures motivate this file, and both were invisible to every
/// other test because neither is reachable from Dart at runtime.
///
/// **The dead project.** `ios/firebase_app_id_file.json` still named
/// `servana-1d13b` (sender `306195353425`) long after everything else moved to
/// `servana-59bee`. Nothing in Dart reads that file — the Firebase Xcode build
/// phase and `upload-symbols` do — so iOS dSYMs and crash reports were being
/// uploaded to a project nobody watches, and no build ever failed over it.
///
/// **The platform asymmetry.** Android config had four separate consistency
/// tests. iOS had none, so the same class of mismatch could sit in
/// `GoogleService-Info.plist` indefinitely.
///
/// These assertions are deliberately file-level rather than runtime-level:
/// they run under `flutter test` on any machine, with no Xcode, no simulator
/// and no platform channel. That is the whole point — the standing rule is
/// that validation stops at `flutter analyze` + `flutter test`, so the check
/// that guards a native config file has to live here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one and only Firebase project. See the standing rule: never a second
/// project, never one per environment. The SMS quota, the phone-auth test
/// numbers and the SMS region policy are all project-wide and shared with the
/// worker app, which is exactly why a second project is not a neutral choice.
const String kProjectId = 'servana-59bee';
const String kSenderId = '320379709991';

/// Every source/config file worth scanning, from a fixed set of roots.
///
/// The first version of this walked `Directory('.')` recursively and blew up in
/// a clean clone with `PathNotFoundException` on
/// `windows/flutter/ephemeral/.plugin_symlinks/...` — symlinks that
/// `flutter pub get` creates into the pub cache, some of which do not resolve
/// on Windows. It passed on a developer machine whose tree happened to be in a
/// different state, which is the same shape of failure as the config drift this
/// file exists to catch.
///
/// So: explicit roots, no symlink following, generated directories skipped.
/// Deterministic on any checkout, and it covers every place a Firebase
/// identifier can legitimately live.
List<File> _sourceFiles() {
  const roots = <String>['lib', 'android', 'ios', 'test', 'tool', '.github'];
  final ext = RegExp(r'\.(json|plist|dart|gradle|xml|ya?ml|md)$');
  final skip = RegExp(r'/(build|\.dart_tool|\.git|Pods|ephemeral|'
      r'\.plugin_symlinks|\.symlinks)/');

  final out = <File>[];

  // Root-level files (pubspec.yaml, RELEASE_MANIFEST.json, the MOBILE_* docs —
  // which is exactly where the stale project id was hiding).
  for (final e in Directory('.').listSync(followLinks: false)) {
    if (e is File && ext.hasMatch(e.path.replaceAll(r'\', '/'))) out.add(e);
  }

  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final e in dir.listSync(recursive: true, followLinks: false)) {
      if (e is! File) continue;
      final p = '/${e.path.replaceAll(r'\', '/')}';
      if (skip.hasMatch(p) || !ext.hasMatch(p)) continue;
      out.add(e);
    }
  }
  return out;
}

/// Reads a flat `<key>k</key><string>v</string>` plist. Both plists in this
/// repo are flat except for `CFBundleURLTypes`, which is handled separately.
Map<String, String> readFlatPlist(String path) {
  final src = File(path).readAsStringSync();
  final out = <String, String>{};
  final re = RegExp(
    r'<key>([^<]+)</key>\s*<string>([^<]*)</string>',
    multiLine: true,
  );
  for (final m in re.allMatches(src)) {
    out[m.group(1)!] = m.group(2)!;
  }
  return out;
}

void main() {
  group('exactly one Firebase project', () {
    test('no tracked file names any project other than $kProjectId', () {
      // A regex for "a Firebase project id that is not ours" would be brittle.
      // The concrete, verified failure is the one that actually happened, so
      // that is what is asserted — plus its sender id, which is the value that
      // survives a careless copy of a plist between apps.
      const dead = <String>['servana-1d13b', '306195353425'];
      final offenders = <String>[];

      for (final file in _sourceFiles()) {
        final p = file.path.replaceAll(r'\', '/');
        // This test file names the dead project in its own documentation.
        if (p.endsWith('firebase_single_project_test.dart')) continue;

        final String text;
        try {
          text = file.readAsStringSync();
        } on FileSystemException {
          continue; // binary or unreadable — not a config file
        }
        for (final d in dead) {
          if (text.contains(d)) offenders.add('$p -> $d');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'These files still point at a retired Firebase project. There '
            'is exactly one project, $kProjectId.\n${offenders.join('\n')}',
      );
    });

    test('android google-services.json is $kProjectId', () {
      final gs = jsonDecode(
        File('android/app/google-services.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final info = gs['project_info'] as Map<String, dynamic>;
      expect(info['project_id'], kProjectId);
      expect(info['project_number'], kSenderId);
    });

    test('ios GoogleService-Info.plist is $kProjectId', () {
      final plist = readFlatPlist('ios/Runner/GoogleService-Info.plist');
      expect(plist['PROJECT_ID'], kProjectId);
      expect(plist['GCM_SENDER_ID'], kSenderId);
    });

    test('firebase_options.dart names $kProjectId on both platforms', () {
      final src = File('lib/firebase_options.dart').readAsStringSync();
      expect(
        RegExp("projectId: '$kProjectId'").allMatches(src).length,
        greaterThanOrEqualTo(2),
        reason: 'both the android and ios FirebaseOptions blocks must name '
            'the one project',
      );
    });
  });

  group('ios firebase config is internally consistent', () {
    late final Map<String, String> plist;
    late final Map<String, dynamic> appIdFile;
    late final String optionsSrc;

    setUpAll(() {
      plist = readFlatPlist('ios/Runner/GoogleService-Info.plist');
      appIdFile = jsonDecode(
        File('ios/firebase_app_id_file.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      optionsSrc = File('lib/firebase_options.dart').readAsStringSync();
    });

    /// The `ios` FirebaseOptions block, isolated so Android values cannot
    /// accidentally satisfy an assertion. Mirrors `androidBlock()` in
    /// firebase_options_consistency_test.dart.
    String iosBlock() {
      final start = optionsSrc.indexOf('static const FirebaseOptions ios');
      expect(start, greaterThan(-1), reason: 'ios options block missing');
      final end = optionsSrc.indexOf(');', start);
      return optionsSrc.substring(start, end);
    }

    test('firebase_app_id_file.json matches GoogleService-Info.plist', () {
      // The exact bug: this file lagged behind the plist by an entire project.
      // Nothing in Dart reads it, so only a file-level check catches it.
      expect(appIdFile['FIREBASE_PROJECT_ID'], plist['PROJECT_ID']);
      expect(appIdFile['GOOGLE_APP_ID'], plist['GOOGLE_APP_ID']);
      expect(appIdFile['GCM_SENDER_ID'], plist['GCM_SENDER_ID']);
    });

    test('firebase_options.dart ios block matches the plist', () {
      final block = iosBlock();
      for (final entry in <String, String?>{
        'API_KEY': plist['API_KEY'],
        'GOOGLE_APP_ID': plist['GOOGLE_APP_ID'],
        'GCM_SENDER_ID': plist['GCM_SENDER_ID'],
        'BUNDLE_ID': plist['BUNDLE_ID'],
      }.entries) {
        expect(entry.value, isNotNull, reason: '${entry.key} missing in plist');
        expect(block, contains(entry.value!), reason: entry.key);
      }
    });

    test('every ios field is present', () {
      for (final field in const [
        'apiKey',
        'appId',
        'messagingSenderId',
        'projectId',
        'storageBucket',
        'iosBundleId',
      ]) {
        expect(iosBlock(), contains('$field:'), reason: field);
      }
    });

    test('GoogleService-Info.plist is copied into the app bundle', () {
      // Existing on disk is not enough: unless the file is in the RUNNER
      // target's Resources build phase, Xcode never copies it into Runner.app,
      // and anything that reads it at runtime finds nothing. It sat unreferenced
      // here for months while ServanaWorker had it wired correctly.
      //
      // Resolved through the target graph rather than by hard-coded UUID, so
      // this cannot be satisfied by the RunnerTests phase — which is a separate,
      // empty Resources phase and the easy thing to patch by mistake.
      final pbx =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

      final fileRef = RegExp(
        r'([0-9A-F]{24}) /\* GoogleService-Info\.plist \*/ = \{isa = PBXFileReference',
      ).firstMatch(pbx);
      expect(fileRef, isNotNull, reason: 'no PBXFileReference for the plist');

      final refId = fileRef!.group(1)!;
      final buildFile = RegExp(
        r'([0-9A-F]{24}) /\* GoogleService-Info\.plist in Resources \*/ = '
        r'\{isa = PBXBuildFile; fileRef = '
        '$refId',
      ).firstMatch(pbx);
      expect(buildFile, isNotNull,
          reason: 'no PBXBuildFile linking the plist to a build phase');

      // Find the Runner native target and the Resources phase it owns.
      final target = RegExp(
        r'[0-9A-F]{24} /\* Runner \*/ = \{\s*isa = PBXNativeTarget;'
        r'[\s\S]*?buildPhases = \(([\s\S]*?)\);',
      ).firstMatch(pbx);
      expect(target, isNotNull, reason: 'Runner native target not found');

      final resourcesPhaseId = RegExp(r'([0-9A-F]{24}) /\* Resources \*/')
          .firstMatch(target!.group(1)!)
          ?.group(1);
      expect(resourcesPhaseId, isNotNull,
          reason: 'Runner target has no Resources build phase');

      final phase = RegExp(
        '$resourcesPhaseId /\\* Resources \\*/ = \\{[\\s\\S]*?files = \\(([\\s\\S]*?)\\);',
      ).firstMatch(pbx);
      expect(phase, isNotNull);
      expect(
        phase!.group(1),
        contains(buildFile!.group(1)!),
        reason: 'the plist is declared but is NOT in the Runner target\'s '
            'Resources phase, so it never reaches Runner.app',
      );
    });

    test('bundle id matches the Xcode target', () {
      final pbx =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      final bundleId = plist['BUNDLE_ID'];
      expect(bundleId, isNotNull);
      expect(
        pbx,
        contains('PRODUCT_BUNDLE_IDENTIFIER = $bundleId;'),
        reason: 'GoogleService-Info.plist is registered for $bundleId but no '
            'Xcode target builds that bundle id. Firebase would refuse to '
            'initialise on device.',
      );
    });
  });

  group('social sign-in config has iOS/Android parity', () {
    // Google Sign-In and Facebook Login are wired through Flutter plugins, but
    // each still needs a native URL scheme. A scheme present on one platform
    // and absent on the other is an integration that works in exactly one
    // store build — and it cannot be caught by any widget test.
    late final String infoPlist;
    late final String stringsXml;

    setUpAll(() {
      infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
      stringsXml = File('android/app/src/main/res/values/strings.xml')
          .readAsStringSync();
    });

    test('ios carries the REVERSED_CLIENT_ID url scheme', () {
      final reversed = readFlatPlist(
          'ios/Runner/GoogleService-Info.plist')['REVERSED_CLIENT_ID'];
      expect(reversed, isNotNull,
          reason: 'GoogleService-Info.plist has no REVERSED_CLIENT_ID, so '
              'Google Sign-In cannot return to the app');
      expect(
        infoPlist,
        contains('<string>$reversed</string>'),
        reason: 'Info.plist must register REVERSED_CLIENT_ID as a URL scheme '
            'or Google Sign-In hangs on the callback',
      );
    });

    test('ios declares GIDClientID matching the Firebase CLIENT_ID', () {
      // google_sign_in_ios resolves the client id from GIDClientID in
      // Info.plist, or from a GoogleService-Info.plist inside the app BUNDLE.
      // The plist is on disk but not referenced by Runner.xcodeproj, so it
      // never reaches the bundle and the fallback never fires — without
      // GIDClientID, Google Sign-In fails on device with nothing failing at
      // build time.
      final clientId =
          readFlatPlist('ios/Runner/GoogleService-Info.plist')['CLIENT_ID'];
      expect(clientId, isNotNull);

      final gid = readFlatPlist('ios/Runner/Info.plist')['GIDClientID'];
      expect(gid, isNotNull,
          reason: 'Info.plist has no GIDClientID, so Google Sign-In cannot '
              'resolve a client id on iOS');
      expect(gid, clientId,
          reason: 'GIDClientID must equal CLIENT_ID from GoogleService-Info');
    });

    test('android has the matching oauth client for its package', () {
      // The Android half of the same integration: Google Sign-In needs an
      // oauth client registered against com.servana.serviceclient, not just
      // the iOS one.
      final gs = jsonDecode(
        File('android/app/google-services.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final client =
          (gs['client'] as List).cast<Map<String, dynamic>>().firstWhere(
                (c) =>
                    c['client_info']['android_client_info']['package_name'] ==
                    'com.servana.serviceclient',
              );
      final oauth =
          (client['oauth_client'] as List).cast<Map<String, dynamic>>();
      expect(oauth, isNotEmpty,
          reason: 'no oauth_client for com.servana.serviceclient — Google '
              'Sign-In cannot work on Android');
    });

    test('facebook app id is identical on both platforms', () {
      final fbAndroid =
          RegExp(r'<string name="facebook_app_id">([^<]+)</string>')
              .firstMatch(stringsXml)
              ?.group(1);
      final fbIos = readFlatPlist('ios/Runner/Info.plist')['FacebookAppID'];
      expect(fbAndroid, isNotNull,
          reason: 'facebook_app_id missing on Android');
      expect(fbIos, isNotNull, reason: 'FacebookAppID missing on iOS');
      expect(fbIos, fbAndroid);
    });

    test('facebook login url scheme is fb<appId> on both platforms', () {
      final fbId = readFlatPlist('ios/Runner/Info.plist')['FacebookAppID'];
      expect(infoPlist, contains('<string>fb$fbId</string>'));

      final scheme = RegExp(r'<string name="fb_login_protocol_scheme">([^<]+)<')
          .firstMatch(stringsXml)
          ?.group(1);
      expect(scheme, 'fb$fbId',
          reason: 'the Android login redirect scheme must be "fb" followed by '
              'the numeric app id');
    });
  });

  group('ios push notifications are actually enabled', () {
    // firebase_messaging is a Flutter plugin, but APNs delivery depends on two
    // native declarations, and only one of them was present. UIBackgroundModes
    // needs no signing so it was there; the aps-environment entitlement does,
    // so it was not — and the app looked push-capable while being unable to
    // receive a notification.

    test('the entitlements file exists and requests aps-environment', () {
      final f = File('ios/Runner/Runner.entitlements');
      expect(f.existsSync(), isTrue,
          reason: 'ios/Runner/Runner.entitlements is missing; firebase_'
              'messaging delivers nothing on iOS without aps-environment');
      final entitlements = readFlatPlist('ios/Runner/Runner.entitlements');
      expect(entitlements['aps-environment'], isNotNull);
      expect(
        entitlements['aps-environment'],
        anyOf('development', 'production'),
      );
    });

    test('the Runner target is wired to the entitlements file', () {
      // An entitlements file the Xcode target never references is inert — the
      // same failure as not having one, minus the visibility.
      final pbx =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
      expect(
        pbx,
        contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'),
        reason: 'CODE_SIGN_ENTITLEMENTS is not set on the Runner target',
      );
      // Debug, Release and Profile — a release-only wiring would ship push
      // that works in TestFlight and not in development, or the reverse.
      expect(
        'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'
            .allMatches(pbx)
            .length,
        3,
        reason: 'all three Runner configurations must carry the entitlement',
      );
    });

    test('Info.plist declares the remote-notification background mode', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('UIBackgroundModes'));
      expect(plist, contains('remote-notification'));
    });
  });

  group('ios permission strings exist for every capability used', () {
    // A missing NS*UsageDescription is not a warning on iOS: the app is
    // rejected at review, or crashes the moment the API is touched. Android
    // has no equivalent failure, so this is genuinely iOS-only — but it is
    // still checkable from `flutter test`.
    test('all required usage descriptions are present and non-empty', () {
      final plist = readFlatPlist('ios/Runner/Info.plist');
      for (final key in const [
        'NSCameraUsageDescription', // image_picker
        'NSPhotoLibraryUsageDescription', // image_picker / file_picker
        'NSLocationWhenInUseUsageDescription', // geolocator / location
        'NSLocationAlwaysAndWhenInUseUsageDescription',
      ]) {
        expect(plist[key], isNotNull, reason: '$key missing from Info.plist');
        expect(plist[key], isNotEmpty, reason: '$key is empty');
      }
    });
  });
}
