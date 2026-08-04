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
// **Why two keys.** A Google Cloud API key carries at most ONE application
// restriction: *Android apps* (package name + SHA-1) or *iOS apps* (bundle id)
// — never both. So a single key shared by both platforms can only be an
// unrestricted key, and an unrestricted Maps key extracted from a shipped APK
// bills to your account until someone notices. Each platform therefore gets
// its own restricted key. A single `GOOGLE_MAPS_API_KEY` still works as a
// fallback for both, because a repo that has not split them yet should render
// maps rather than fail.
//
// Usage:
//   dart run tool/inject_maps_key.dart              # warn if key absent
//   dart run tool/inject_maps_key.dart --require    # fail if key absent
//
// Environment, in precedence order per platform:
//   Android  GOOGLE_MAPS_API_KEY_ANDROID  then  GOOGLE_MAPS_API_KEY
//   iOS      GOOGLE_MAPS_API_KEY_IOS      then  GOOGLE_MAPS_API_KEY
//
// The placeholder stays in git and is replaced only in the build workspace, so
// no key is ever committed.

import 'dart:io';

/// The committed stand-in. Both native files must contain it verbatim, and
/// `test/common/maps_key_injection_test.dart` asserts they still do — so this
/// script can never silently find nothing to replace.
const String placeholder = 'REPLACE_WITH_GOOGLE_MAPS_API_KEY';

/// A native file that needs a Maps key, and where its key comes from.
class MapsTarget {
  const MapsTarget(this.path, this.setting, this.envVar);

  /// File to rewrite.
  final String path;

  /// The native key/resource being populated — used only for log output.
  final String setting;

  /// Platform-specific environment variable, preferred over the shared one.
  final String envVar;
}

const List<MapsTarget> targets = <MapsTarget>[
  MapsTarget(
    'android/app/src/main/res/values/strings.xml',
    'google_maps_key',
    'GOOGLE_MAPS_API_KEY_ANDROID',
  ),
  MapsTarget(
    'ios/Runner/Info.plist',
    'GMSApiKey',
    'GOOGLE_MAPS_API_KEY_IOS',
  ),
];

/// Shared fallback when a platform-specific key is not configured.
const String sharedEnvVar = 'GOOGLE_MAPS_API_KEY';

/// Returning an int from `main` does NOT set the process exit code in Dart —
/// the value is discarded. Written that way first, `--require` reported success
/// on a missing key and CI would have shipped a keyless build while printing an
/// error. The exit code is the only thing CI reads, so it is set explicitly.
void main(List<String> args) {
  exitCode = _run(args);
}

int _run(List<String> args) {
  final require = args.contains('--require');
  final shared = Platform.environment[sharedEnvVar]?.trim() ?? '';

  var patched = 0;

  for (final target in targets) {
    final specific = Platform.environment[target.envVar]?.trim() ?? '';
    final key = specific.isNotEmpty ? specific : shared;
    final source = specific.isNotEmpty ? target.envVar : sharedEnvVar;

    if (key.isEmpty) {
      final msg = 'Neither ${target.envVar} nor $sharedEnvVar is set. Maps '
          'will not render for ${target.path}. Set it in '
          'Settings > Secrets and variables > Actions.';
      if (require) {
        stderr.writeln('::error::$msg');
        return 1;
      }
      stdout.writeln('::warning::$msg');
      continue;
    }

    if (key.contains(placeholder)) {
      stderr.writeln('::error::$source is set to the placeholder value.');
      return 1;
    }

    final file = File(target.path);
    if (!file.existsSync()) {
      stderr.writeln('::error::missing ${target.path}');
      return 1;
    }

    final before = file.readAsStringSync();
    if (!before.contains(placeholder)) {
      // Either the key is already injected, or someone renamed the
      // placeholder — in which case this script would have silently produced a
      // keyless build, which is the failure mode worth being loud about.
      stderr.writeln(
        '::error::${target.path} does not contain "$placeholder". The Maps key '
        'for ${target.setting} cannot be injected.',
      );
      return 1;
    }

    file.writeAsStringSync(before.replaceAll(placeholder, key));
    // The key itself is never printed — only which variable supplied it.
    stdout.writeln('injected ${target.setting} <- $source  (${target.path})');
    patched++;
  }

  if (require && patched != targets.length) {
    stderr.writeln('::error::patched $patched of ${targets.length} targets');
    return 1;
  }

  stdout.writeln('Google Maps key injection complete '
      '($patched/${targets.length} platforms).');
  return 0;
}
