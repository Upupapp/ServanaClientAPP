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
