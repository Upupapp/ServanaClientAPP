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

String _read(String p) => File(p).readAsStringSync();

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

    test('every CI job that injects passes all three variables', () {
      // A key wired into the script but not into the workflow is a key that
      // silently never arrives — the injector would fall back or warn, and the
      // build would still go green with no maps.
      final ci = _read('.github/workflows/flutter-ci.yml');

      int wired(String v) =>
          RegExp('$v: \\\$\\{\\{ secrets\\.$v \\}\\}').allMatches(ci).length;

      // Three jobs inject: build-android, build-ios, release-android.
      expect(wired('GOOGLE_MAPS_API_KEY_ANDROID'), greaterThanOrEqualTo(3));
      expect(wired('GOOGLE_MAPS_API_KEY_IOS'), 3);
      // The shared fallback is also read by release-android's preflight check,
      // so it legitimately appears more often than the injection steps.
      expect(wired('GOOGLE_MAPS_API_KEY'), greaterThanOrEqualTo(3));
    });

    test('the release preflight accepts either Android variable', () {
      // The preflight used to demand GOOGLE_MAPS_API_KEY by name. After the
      // split, setting only GOOGLE_MAPS_API_KEY_ANDROID — the correct,
      // restricted key for the one platform this job builds — would have
      // failed the release before it started.
      final ci = _read('.github/workflows/flutter-ci.yml');
      expect(
        ci,
        contains(r'if [ -z "$GOOGLE_MAPS_API_KEY_ANDROID" ] && '
            r'[ -z "$GOOGLE_MAPS_API_KEY" ]; then'),
        reason: 'the preflight must pass when EITHER variable is set',
      );
    });

    test('the release job requires a key rather than warning', () {
      // The original inline `sed` substituted an EMPTY key when the secret was
      // unset and shipped a release with grey rectangles where maps should be,
      // reporting success throughout.
      final ci = _read('.github/workflows/flutter-ci.yml');
      expect(ci, contains('dart run tool/inject_maps_key.dart --require'));
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
