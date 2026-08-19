/// Every repository the injector builds should have somebody who asks for it.
///
/// ## The thing this is watching for
///
/// The convergence work built canonical `/api/v1` transports domain by
/// domain, each one a data-source pair behind a repository, each repository
/// registered in `main_injector.dart`. Three of them reached no screen —
/// `BookingRepository`, `BookingExperiencesRepository` and
/// `HomeCompositionRepository` — and all three are wired now. **The allowlist
/// is empty**, which is the state this test exists to keep.
///
/// A registered singleton nobody resolves is not neutral. It reads as
/// "migrated" to the next person who greps the injector, and it makes the
/// matching `V1Capability` look shippable when enabling it would move no
/// traffic — the flag is read by an object with no callers.
///
/// ## Why an allowlist rather than a failure
///
/// Wiring those two is a screen-level refactor with its own risk, and it is a
/// decision about scope rather than a defect to patch quietly. So they are
/// named below and the test fails on the THIRD. The list may shrink; it must
/// not grow without somebody deciding that it should.
///
/// ## What this measure can and cannot see
///
/// A consumer is a mention of the type under `presentation/`, `application/`
/// or `domain/use_cases/` — the three layers that can drive a screen. That is
/// deliberately generous: this is a smoke detector for a transport with no UI,
/// not a call-graph analysis.
///
/// Two consequences worth naming rather than discovering later:
///
///  1. **A mention is not a use.** `HomeCompositionRepository` passes this
///     test on the strength of one line in `authentication_bloc.dart` that
///     calls `.clear()` on logout — the app clears a cache that nothing ever
///     fills, because Home renders from the legacy `HomeStore`. That is a real
///     dark transport this detector cannot express, and it is recorded in
///     `docs/audit/SWEEP_CLIENT_2026_08_18.md` instead of being forced into
///     the measure here.
///  2. **The use-case layer counts.** `StoreOptionsRepository` reaches its
///     screen through `domain/use_cases/`, so restricting the roots to
///     presentation and application alone reports it falsely. It was reported
///     falsely, by the first version of this file.
///
/// `HomeCompositionRepository` now has a real consumer —
/// `HomeCompositionController` — so the caveat above is history rather than a
/// live exemption. It is kept because the measure's blind spot has not
/// changed.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Registered but deliberately unconsumed, each with the reason it is here.
///
/// Removing a name from this set is the goal. Adding one needs a decision.
const Map<String, String> _knownUnconsumed = <String, String>{};

/// The layers from which a screen can be driven.
const List<String> _consumerRoots = <String>[
  '/presentation/',
  '/application/',
  '/domain/use_cases/',
];

/// Reads a file as text with line endings normalised.
///
/// Checked out on Windows these files arrive CRLF. A source-introspection test
/// that matches across line boundaries passes on CI and fails on a developer
/// machine, or the reverse, for reasons that have nothing to do with the code
/// being checked.
String _read(File file) => file.readAsStringSync().replaceAll('\r\n', '\n');

final _registration = RegExp(r'\(\) => ([A-Z][A-Za-z0-9_]*Repository)\(');

Set<String> _registeredRepositories() => _registration
    .allMatches(_read(File('lib/common/injectors/main_injector.dart')))
    .map((m) => m.group(1)!)
    .toSet();

String _consumerSource() => Directory('lib')
    .listSync(recursive: true, followLinks: false)
    .whereType<File>()
    .where((f) {
      // Normalise separators: this runs on Windows, where paths are '\'.
      final path = f.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart')) return false;
      return _consumerRoots.any(path.contains);
    })
    .map(_read)
    .join('\n');

void main() {
  test('the injector file is where this test expects it', () {
    // If this fails, every assertion below would vacuously pass.
    expect(
      File('lib/common/injectors/main_injector.dart').existsSync(),
      isTrue,
      reason: 'tests run from the package root; main_injector.dart moved',
    );
  });

  test('the extraction still matches the injector', () {
    // A registration style change would empty this set and quietly turn the
    // whole file green.
    expect(_registeredRepositories(), hasLength(greaterThan(15)));
  });

  test('every registered repository is named by a consumer layer', () {
    final unconsumed = _registeredRepositories()
        .where((type) => !_consumerSource().contains(type))
        .toSet();

    expect(
      unconsumed.difference(_knownUnconsumed.keys.toSet()),
      isEmpty,
      reason: 'a repository was registered with no screen, controller or use '
          'case behind it. Wire it, or add it to _knownUnconsumed with the '
          'reason — a registered singleton nobody resolves reads as a '
          'migrated domain to the next person who greps the injector.',
    );
  });

  test('the allowlist has not gone stale', () {
    final registered = _registeredRepositories();
    final consumers = _consumerSource();

    // An entry that is now consumed, or no longer registered, is a stale
    // exemption — and a stale exemption is how an allowlist quietly becomes
    // permission for the next one.
    for (final entry in _knownUnconsumed.entries) {
      expect(
        registered.contains(entry.key) && !consumers.contains(entry.key),
        isTrue,
        reason: '${entry.key} is exempted but no longer needs to be — it is '
            'either consumed now or gone. Remove it from _knownUnconsumed.',
      );
    }
  });
}
