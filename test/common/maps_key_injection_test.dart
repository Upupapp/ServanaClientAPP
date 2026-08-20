/// The Google Maps key must be injectable on BOTH platforms, and must never be
/// committed to either.
///
/// `tool/inject_maps_key.dart` finds the key by string-replacing a placeholder.
/// If either native file loses that placeholder, the script has nothing to
/// replace — and a build with no Maps key does not fail, it just renders a grey
/// rectangle where the map should be. That is precisely the kind of defect that
/// reaches a store before anyone notices, so the contract between the script
/// and the two files is asserted here instead.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kept in sync with `placeholder` in tool/inject_maps_key.dart.
const String kPlaceholder = 'REPLACE_WITH_GOOGLE_MAPS_API_KEY';

/// The only automated release path this repository still has. The GitHub
/// workflow that used to hold it was deleted on 2026-08-20.
const String kReleaseScript = 'scripts/release-android.sh';

String _read(String p) {
  final file = File(p);
  // A missing file must say WHICH file is missing, not throw
  // PathNotFoundException out of the middle of an expectation. Three tests
  // here read a workflow that was deleted, and the failure they produced
  // named an errno rather than the fact that the thing under test is gone.
  if (!file.existsSync()) {
    fail('\$p does not exist — this test asserts against a file that is no '
        'longer in the repository.');
  }
  return file.readAsStringSync();
}

void main() {
  group('maps key injection contract', () {
    test('the injector and this test agree on the placeholder', () {
      // Otherwise the tests below pass while the script replaces nothing.
      expect(
        _read('tool/inject_maps_key.dart'),
        contains("placeholder = '$kPlaceholder'"),
      );
    });

    test('android strings.xml still carries the placeholder', () {
      final xml = _read('android/app/src/main/res/values/strings.xml');
      expect(xml, contains('name="google_maps_key"'));
      expect(xml, contains(kPlaceholder));
    });

    test('ios Info.plist still carries the placeholder', () {
      final plist = _read('ios/Runner/Info.plist');
      expect(plist, contains('<key>GMSApiKey</key>'));
      expect(plist, contains(kPlaceholder));
    });

    test('the android manifest resolves the string resource', () {
      // A key in strings.xml that the manifest never references is inert.
      final manifest = _read('android/app/src/main/AndroidManifest.xml');
      expect(manifest, contains('com.google.android.geo.API_KEY'));
      expect(manifest, contains('@string/google_maps_key'));
    });

    test('AppDelegate reads GMSApiKey from Info.plist', () {
      // The iOS half of the same wiring. google_maps_flutter never reads
      // Info.plist itself — the app must hand the key to GMSServices.
      final appDelegate = _read('ios/Runner/AppDelegate.swift');
      expect(appDelegate, contains('GMSApiKey'));
      expect(appDelegate, contains('GMSServices.provideAPIKey'));
    });

    test('each platform has its own key variable', () {
      // A Google Cloud API key carries at most ONE application restriction —
      // Android apps OR iOS apps, never both. Sharing one key across platforms
      // is therefore only possible with an UNRESTRICTED key, which is
      // extractable from any shipped binary and bills to us until noticed.
      final tool = _read('tool/inject_maps_key.dart');
      expect(tool, contains('GOOGLE_MAPS_API_KEY_ANDROID'));
      expect(tool, contains('GOOGLE_MAPS_API_KEY_IOS'));
      expect(tool, contains("sharedEnvVar = 'GOOGLE_MAPS_API_KEY'"),
          reason: 'the shared fallback must remain, so a repo that has not '
              'split its keys yet still renders maps');
    });

    // ── The release path ─────────────────────────────────────────────────────
    //
    // These used to read `.github/workflows/flutter-ci.yml`. That file was
    // DELETED on 2026-08-20 — "no CI on any repository; absent beats disabled,
    // because a setting can be flipped back by accident and a deleted file
    // cannot" — and its `release-android` job moved to
    // `scripts/release-android.sh` with its reasoning intact.
    //
    // Left pointing at the old path they did not become lenient, they became
    // BROKEN: each threw PathNotFoundException, which turned the pre-push hook
    // red for everyone. Retargeted at the script, they assert the same
    // properties about the thing that now does the releasing.

    test('the release script wires the Android key, or the shared fallback',
        () {
      // A key wired into the injector but not into the release path is a key
      // that silently never arrives — the build goes green with no maps.
      final release = _read(kReleaseScript);

      expect(release, contains('GOOGLE_MAPS_API_KEY_ANDROID'));
      expect(release, contains('GOOGLE_MAPS_API_KEY'));
    });

    test('the release preflight accepts either Android variable', () {
      // The preflight used to demand GOOGLE_MAPS_API_KEY by name. After the
      // split, setting only GOOGLE_MAPS_API_KEY_ANDROID — the correct,
      // restricted key for the one platform this script builds — would have
      // failed the release before it started.
      final release = _read(kReleaseScript);
      expect(
        release,
        contains(r'[ -z "${GOOGLE_MAPS_API_KEY_ANDROID:-}" ] && '
            r'[ -z "${GOOGLE_MAPS_API_KEY:-}" ]'),
        reason: 'the preflight must pass when EITHER variable is set',
      );
    });

    test('the release path requires a key rather than warning', () {
      // The original inline `sed` substituted an EMPTY key when the secret was
      // unset and shipped a release with grey rectangles where maps should be,
      // reporting success throughout.
      final release = _read(kReleaseScript);
      expect(release, contains('dart run tool/inject_maps_key.dart --require'));
    });

    test('the deleted workflow has not quietly come back', () {
      // A property, not an instance. If the file returns, the three assertions
      // above are describing a release path that is no longer the only one —
      // and a test naming a path nothing executes passes while proving nothing.
      expect(File('.github/workflows/flutter-ci.yml').existsSync(), isFalse,
          reason: 'the standing rule is that this file stays absent');
    });

    test('no real Google API key is committed to either native file', () {
      // Google browser/Android/iOS keys are 39 chars starting "AIza". The two
      // files below are the ones the injector writes to, so a real key here
      // means somebody committed a build workspace.
      final leaked = RegExp(r'AIza[0-9A-Za-z_\-]{35}');
      for (final path in const [
        'android/app/src/main/res/values/strings.xml',
        'ios/Runner/Info.plist',
      ]) {
        expect(leaked.hasMatch(_read(path)), isFalse,
            reason: '$path contains what looks like a real Google API key');
      }
    });
  });
}
