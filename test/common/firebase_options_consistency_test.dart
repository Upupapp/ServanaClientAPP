/// SC-180 / SC-176 — firebase_options.dart must agree with google-services.json.
///
/// The regression this guards against hung the app before Flutter drew a single
/// frame. `Firebase.initializeApp(options: DefaultFirebaseOptions...)` was
/// called with an apiKey that no longer matched the one the native
/// FirebaseInitProvider had already used to create the [DEFAULT] app, and
/// re-initialising [DEFAULT] with different options never returned.
///
/// Nothing about it looked like a Firebase problem. The native SDK logged
/// "FirebaseApp initialization successful", Crashlytics started, analytics
/// sent a session event — and the app sat on the Android launch screen
/// forever, because Dart never got past its await.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android Firebase config is internally consistent', () {
    late final Map<String, dynamic> client;
    late final String optionsSrc;

    setUpAll(() {
      final gs = jsonDecode(
        File('android/app/google-services.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      client = (gs['client'] as List).cast<Map<String, dynamic>>().firstWhere(
          (c) =>
              c['client_info']['android_client_info']['package_name'] ==
              'com.servana.serviceclient');
      optionsSrc = File('lib/firebase_options.dart').readAsStringSync();
    });

    /// The `android` FirebaseOptions block, isolated so iOS values cannot
    /// accidentally satisfy an assertion.
    String androidBlock() {
      final start = optionsSrc.indexOf('static const FirebaseOptions android');
      expect(start, greaterThan(-1), reason: 'android options block missing');
      final end = optionsSrc.indexOf(');', start);
      return optionsSrc.substring(start, end);
    }

    test('apiKey matches — the mismatch that hung startup', () {
      final native = (client['api_key'] as List).first['current_key'] as String;
      expect(androidBlock(), contains(native),
          reason: 'firebase_options.dart carries a different Android apiKey '
              'than google-services.json. Re-initialising the DEFAULT app with '
              'different options hangs before the first frame.');
    });

    test('appId matches', () {
      final id = client['client_info']['mobilesdk_app_id'] as String;
      expect(androidBlock(), contains(id));
    });

    test('the superseded key is gone', () {
      // Left behind when google-services.json was regenerated and Firebase
      // handed out the newer of the project's two Android keys.
      expect(optionsSrc,
          isNot(contains('AIzaSyA5lwcYygv01agpuZBpilWHr932qzVuY8s')));
    });

    test('every android field is present', () {
      // A missing field would make Dart-side options differ from native just
      // as effectively as a wrong one.
      for (final field in const [
        'apiKey',
        'appId',
        'messagingSenderId',
        'projectId',
        'storageBucket',
      ]) {
        expect(androidBlock(), contains('$field:'), reason: field);
      }
    });
  });
}
