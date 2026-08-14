import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Acceptance gate for TAB 02: **no screen contains a raw endpoint string.**
///
/// This is the one property of the whole tab that decays silently. Everything
/// else — the failure model, the router, the envelope — is exercised by tests
/// that fail loudly if they regress. "A widget quietly grew a URL" produces no
/// test failure anywhere, ships, and is discovered the next time the backend
/// renames a route.
///
/// So the rule is enforced by scanning the source. The presentation layer must
/// contain no string literal naming an HTTP path or host; paths belong in
/// `V1Endpoints` (canonical) or `ServanaApiClient` (legacy), and the origin
/// belongs to `AppConfig.baseUrl`.
///
/// Doc comments are exempt. Several screens legitimately explain which route
/// backs them — `payment_webview_screen.dart` documents that payment status is
/// confirmed via a booking read — and that prose is documentation, not a call.
void main() {
  group('acceptance gate', () {
    test('presentation code contains no raw endpoint or host literals', () {
      final offenders = <String>[];

      for (final file in _presentationDartFiles()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (_isComment(line)) continue;
          for (final literal in _stringLiterals(line)) {
            if (_looksLikeEndpoint(literal)) {
              offenders.add('${_relative(file)}:${i + 1}  →  "$literal"');
            }
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'A screen must not name an endpoint or a host directly.\n'
            'Canonical paths belong in V1Endpoints, legacy calls in\n'
            'ServanaApiClient, and the origin in AppConfig.baseUrl.\n'
            'Found:\n  ${offenders.join('\n  ')}',
      );
    });

    test('no source file outside config hard-codes an API origin to call', () {
      // API_BASE_URL is the single environment switch for anything the app
      // CALLS. A literal origin anywhere else is a build that cannot be
      // pointed at staging.
      //
      // The exception below is deliberate and is not a violation of that rule:
      // it is a security allowlist, not a call target. See [_hostAllowlistFiles].
      final offenders = <String>[];
      for (final file in _libDartFiles()) {
        final path = _relative(file);
        if (path.contains('common/config/')) continue;
        if (_hostAllowlistFiles.any(path.endsWith)) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (_isComment(lines[i])) continue;
          for (final literal in _stringLiterals(lines[i])) {
            if (literal.contains('api.servana.com') ||
                literal.contains('localhost') ||
                literal.contains('127.0.0.1') ||
                literal.contains('10.0.2.2')) {
              offenders.add('$path:${i + 1}  →  "$literal"');
            }
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'Hard-coded hosts found:\n  ${offenders.join('\n  ')}');
    });
  });
}

/// Files permitted to name hosts literally, because the literal IS the control.
///
/// `payment_webview_screen.dart` holds `_approvedHosts`: the deny-by-default
/// set of origins the checkout WebView may navigate to. Those strings are a
/// security boundary, not a call target — the screen never issues a request to
/// them, it refuses navigation to anything absent from the set.
///
/// Sourcing that set from configuration would be strictly worse: an allowlist
/// a build define can extend is an allowlist an attacker who controls the
/// build environment can extend, and one fetched at runtime is one the network
/// can extend. It stays compiled in on purpose.
///
/// This exemption is narrow by construction — it is matched per file, so a new
/// host literal anywhere else still fails the test.
const List<String> _hostAllowlistFiles = <String>[
  'common/presentation/screens/payment_webview_screen.dart',
];

Iterable<File> _libDartFiles() sync* {
  final lib = Directory('lib');
  if (!lib.existsSync()) return;
  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (!path.endsWith('.dart')) continue;
    // Generated code is derived, not authored.
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    yield entity;
  }
}

Iterable<File> _presentationDartFiles() =>
    _libDartFiles().where((f) => _relative(f).contains('/presentation/'));

String _relative(File file) => file.path.replaceAll(r'\', '/');

bool _isComment(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Extracts single- and double-quoted literals. Good enough for a lint: it
/// does not need to parse Dart, only to notice a URL sitting in a widget.
Iterable<String> _stringLiterals(String line) sync* {
  final pattern = RegExp("'([^']*)'|\"([^\"]*)\"");
  for (final match in pattern.allMatches(line)) {
    yield match.group(1) ?? match.group(2) ?? '';
  }
}

bool _looksLikeEndpoint(String literal) {
  if (literal.contains('/api/')) return true;
  if (literal.startsWith('/api')) return true;
  if (literal.startsWith('http://') || literal.startsWith('https://')) {
    // External destinations a screen legitimately opens — a privacy policy, a
    // store listing — are not API endpoints.
    return literal.contains('/api');
  }
  return false;
}
