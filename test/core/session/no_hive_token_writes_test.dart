import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the steady state of the expand-migrate-contract move: **no code path
/// writes token material into the Hive session record.**
///
/// The migration in `SessionTokenStore` strips the legacy `token` and
/// `refreshToken` fields once the secure copy is verified. That is pointless if
/// a later edit reintroduces a write — the credential would silently reappear
/// in the general-purpose object store the move exists to get it out of.
///
/// A source scan is the right tool here because the property is about which
/// code EXISTS, not about what one execution does. A behavioural test can only
/// prove the paths it exercises; this covers the ones nobody thought to.
void main() {
  group('no new Hive token writes', () {
    test('nothing constructs a session save carrying token material', () {
      final offenders = <String>[];

      for (final file in _libDartFiles()) {
        final path = _relative(file);
        // The store itself is allowed to name these fields: stripping them is
        // its job, and it writes only empty values.
        if (path.endsWith('core/session/session_token_store.dart')) continue;

        final source = file.readAsStringSync();
        for (final match in _saveSessionCalls(source)) {
          // A save that explicitly blanks the fields is the intended shape.
          final blanks = match.contains("token: ''") &&
              match.contains('refreshToken: null');
          if (blanks) continue;
          // A save that does not mention tokens at all re-persists whatever the
          // record already held, which after migration is empty. Fine.
          final mentionsToken =
              match.contains('token:') || match.contains('refreshToken:');
          if (!mentionsToken) continue;
          offenders.add('$path  →  ${_collapse(match)}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Token material must be written only to SessionTokenStore.\n'
            'A saveSession(...) that sets token/refreshToken to anything other\n'
            "than '' / null puts a credential back into Hive.\nFound:\n  "
            '${offenders.join('\n  ')}',
      );
    });

    test('the UserSession model still declares the fields', () {
      // The contract phase — removing them from the Hive adapter — is NOT part
      // of this change. Deleting persisted fields is its own migration, and
      // doing it here would break the record for every installed customer.
      // This test exists so their continued presence reads as deliberate.
      final model =
          File('lib/common/data/models/user_session.dart').readAsStringSync();
      expect(model, contains('String token'));
      expect(model, contains('String? refreshToken'));
    });

    test('the migration verifies the secure write before stripping', () {
      // The ordering IS the safety property: strip-then-discover-the-write-
      // failed loses a refresh token that cannot be regenerated on-device for
      // email/password sessions.
      final store =
          File('lib/core/session/session_token_store.dart').readAsStringSync();
      final readBack = store.indexOf('readBack');
      final strip = store.indexOf('stripLegacyTokens()', readBack);
      expect(readBack, greaterThan(-1),
          reason: 'the migration must read the secure value back');
      expect(strip, greaterThan(readBack),
          reason: 'the strip must come after the read-back check');
    });
  });
}

Iterable<File> _libDartFiles() sync* {
  final lib = Directory('lib');
  if (!lib.existsSync()) return;
  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (!path.endsWith('.dart')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    yield entity;
  }
}

String _relative(File file) => file.path.replaceAll(r'\', '/');

/// Extracts each `saveSession(` call with a balanced argument list.
Iterable<String> _saveSessionCalls(String source) sync* {
  const needle = 'saveSession(';
  var index = source.indexOf(needle);
  while (index != -1) {
    var depth = 0;
    var end = index + needle.length - 1;
    for (; end < source.length; end++) {
      final ch = source[end];
      if (ch == '(') depth++;
      if (ch == ')') {
        depth--;
        if (depth == 0) break;
      }
    }
    yield source.substring(
        index, end < source.length ? end + 1 : source.length);
    index = source.indexOf(needle, index + needle.length);
  }
}

String _collapse(String text) {
  final single = text.replaceAll(RegExp(r'\s+'), ' ');
  return single.length <= 160 ? single : '${single.substring(0, 160)}…';
}
