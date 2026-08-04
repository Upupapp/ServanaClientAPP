// Injects the Google Maps API key into both native configs at build time.
//
// Why this exists at all: `google_maps_flutter` does not read a `--dart-define`.
// Android reads `com.google.android.geo.API_KEY` from AndroidManifest (which
// resolves `@string/google_maps_key`), and iOS reads whatever the app passes to
// `GMSServices.provideAPIKey` — here, `GMSApiKey` from Info.plist. So the key
// has to reach two native files, and there is no Flutter-level alternative.
//
// Why it is a Dart script rather than two shell snippets: one implementation,
// one set of failure messages, and identical behaviour on the ubuntu and macOS
// runners. `sed -i` alone differs between GNU and BSD, which is exactly the
// kind of platform-specific build scripting that caused the iOS breakage this
// change is undoing.
//
// Usage:
//   dart run tool/inject_maps_key.dart              # warn if key absent
//   dart run tool/inject_maps_key.dart --require    # fail if key absent
//
// Reads GOOGLE_MAPS_API_KEY from the environment. The placeholder is left in
// git and replaced only in the build workspace — the key is never committed.

import 'dart:io';

/// The committed stand-in. Both native files must contain it verbatim, and
/// `test/common/maps_key_injection_test.dart` asserts they still do — so this
/// script can never silently find nothing to replace.
const String placeholder = 'REPLACE_WITH_GOOGLE_MAPS_API_KEY';

const Map<String, String> targets = <String, String>{
  'android/app/src/main/res/values/strings.xml': 'google_maps_key',
  'ios/Runner/Info.plist': 'GMSApiKey',
};

/// Returning an int from `main` does NOT set the process exit code in Dart —
/// the value is discarded. Written that way first, `--require` reported success
/// on a missing key and CI would have shipped a keyless build while printing an
/// error. The exit code is the only thing CI reads, so it is set explicitly.
void main(List<String> args) {
  exitCode = _run(args);
}

int _run(List<String> args) {
  final require = args.contains('--require');
  final key = Platform.environment['GOOGLE_MAPS_API_KEY'] ?? '';

  if (key.isEmpty) {
    const msg = 'GOOGLE_MAPS_API_KEY is not set. Maps will not render in this '
        'build. Set it in Settings > Secrets and variables > Actions.';
    if (require) {
      stderr.writeln('::error::$msg');
      return 1;
    }
    stdout.writeln('::warning::$msg');
    return 0;
  }

  if (key.contains(placeholder) || key.trim().isEmpty) {
    stderr.writeln('::error::GOOGLE_MAPS_API_KEY is set to the placeholder.');
    return 1;
  }

  var patched = 0;
  for (final entry in targets.entries) {
    final file = File(entry.key);
    if (!file.existsSync()) {
      stderr.writeln('::error::missing ${entry.key}');
      return 1;
    }

    final before = file.readAsStringSync();
    if (!before.contains(placeholder)) {
      // Either the key is already injected, or someone renamed the
      // placeholder — in which case this script would have silently produced a
      // keyless build, which is the failure mode worth being loud about.
      stderr.writeln(
        '::error::${entry.key} does not contain "$placeholder". The Maps key '
        'for ${entry.value} cannot be injected.',
      );
      return 1;
    }

    file.writeAsStringSync(before.replaceAll(placeholder, key));
    stdout.writeln('injected ${entry.value} -> ${entry.key}');
    patched++;
  }

  if (patched != targets.length) {
    stderr.writeln('::error::patched $patched of ${targets.length} targets');
    return 1;
  }
  stdout.writeln('Google Maps key injected for both platforms.');
  return 0;
}
