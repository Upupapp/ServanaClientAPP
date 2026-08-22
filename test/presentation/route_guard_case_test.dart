import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every settings route is behind the auth guard, whatever its capitalisation.
///
/// ## The hole this closes
///
/// `SettingsScreen.route` is `'/Settings'`. Every settings SUB-screen is lower
/// case: `/settings/privacy`, `/settings/security`, `/settings/profile-edit`,
/// `/settings/appearance`, `/settings/permissions`, `/settings/about` and
/// `/settings/delete-account`.
///
/// The router guard tested `loc.startsWith(SettingsScreen.route)`, and
/// `String.startsWith` is case-sensitive — so **none of those seven were
/// protected**. Anyone could deep-link to profile editing or account deletion
/// with no session. The count grew to seven on 2026-08-23 when the deletion
/// screen was added at a lower-case path; the register had recorded six.
///
/// The paired defect: the settings notification deep link pushed the literal
/// `'/settings'`, which GoRouter does not match against `'/Settings'` — so it
/// opened an error page, and the path it opened was also the unguarded one.
///
/// Both are fixed by comparing in one case. This test exists because the next
/// screen added under `/settings/...` must inherit the guard rather than
/// silently rejoin the hole.
void main() {
  /// Source with `//` comments removed.
  ///
  /// The prefix list carries trailing comments that themselves contain quoted
  /// paths — `'/JobOrderSummaryScreen/:id'` among them. A naive scan reads
  /// those as entries and reports a lower-case violation that does not exist.
  /// This is the second time in this repository a source-scanning test has been
  /// fooled by a comment; strip first, then parse.
  String codeOnly(String src) => src.split('\n').map((l) {
        final i = l.indexOf('//');
        return i < 0 ? l : l.substring(0, i);
      }).join('\n');

  final router = codeOnly(
      File('lib/common/presentation/routes/main_router.dart')
          .readAsStringSync());

  /// Route constants declared anywhere in the app, as (file, path).
  List<MapEntry<String, String>> routeConstants() {
    final out = <MapEntry<String, String>>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final src = f.readAsStringSync();
      for (final m in RegExp(
              r'''static\s+(?:const\s+)?String\s+route\s*=\s*['"](/[^'"]*)['"]''')
          .allMatches(src)) {
        out.add(MapEntry(f.path, m.group(1)!));
      }
    }
    return out;
  }

  test('the scan finds route constants at all', () {
    // Floor: a guard that finds nothing proves nothing.
    final all = routeConstants();
    expect(all.length, greaterThan(10),
        reason: 'found ${all.length} route constants — the scan is broken');
    expect(all.map((e) => e.value), contains('/settings/delete-account'));
  });

  test('the comment stripper keeps the code and drops the comments', () {
    expect(router, contains('protectedPrefixes'),
        reason: 'the stripper removed code');
    expect(router, isNot(contains('JobOrderSummaryScreen/:id')),
        reason:
            'comments were not stripped — the prefix parse below is unsafe');
  });

  test('the guard compares case-insensitively', () {
    expect(router, contains('toLowerCase()'),
        reason: 'the guard must normalise case, or a lower-case /settings/... '
            'route silently falls outside it');
  });

  test('every /settings route is covered by a protected prefix', () {
    // Extract the declared prefix list from the router source.
    final block =
        RegExp(r'protectedPrefixes\s*=\s*<String>\[(.*?)\];', dotAll: true)
            .firstMatch(router);
    expect(block, isNotNull,
        reason: 'protectedPrefixes list not found — was the guard rewritten?');
    final prefixes = RegExp(r"'([^']+)'")
        .allMatches(block!.group(1)!)
        .map((m) => m.group(1)!)
        .toList();

    expect(prefixes.length, greaterThan(5),
        reason: 'parsed ${prefixes.length} prefixes — the parse is broken');
    for (final p in prefixes) {
      expect(p, equals(p.toLowerCase()),
          reason: "prefix '$p' is not lower case, so it can never match the "
              'lower-cased location');
    }

    final unguarded = <String>[];
    for (final e in routeConstants()) {
      final loc = e.value.toLowerCase();
      if (!loc.startsWith('/settings')) continue;
      if (!prefixes.any(loc.startsWith)) unguarded.add('${e.value} (${e.key})');
    }
    expect(unguarded, isEmpty,
        reason:
            'settings routes outside the auth guard:\n${unguarded.join('\n')}');
  });

  test('account deletion in particular is behind the guard', () {
    // Called out separately because it is the worst one to leave open and the
    // one App Review will walk.
    final block =
        RegExp(r'protectedPrefixes\s*=\s*<String>\[(.*?)\];', dotAll: true)
            .firstMatch(router)!;
    final prefixes = RegExp(r"'([^']+)'")
        .allMatches(block.group(1)!)
        .map((m) => m.group(1)!);
    expect(prefixes.any('/settings/delete-account'.startsWith), isTrue);
  });

  test('the settings deep link pushes the route constant, not a literal', () {
    final nav = File(
      'lib/modules/notifications/application/notification_navigation_coordinator.dart',
    ).readAsStringSync();
    expect(nav, isNot(contains("push('/settings')")),
        reason: 'a literal path drifts from the constant and GoRouter matches '
            'case-sensitively — push SettingsScreen.route instead');
    expect(nav, contains('SettingsScreen.route'));
  });
}
