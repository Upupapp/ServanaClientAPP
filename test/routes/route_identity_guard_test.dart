/// TAB 07 — booking entry identity at route boundaries.
///
/// A booking entry either knows which Service it is starting, or it must not
/// start. The failure this guards against is not a crash — it is a screen that
/// proceeds confidently with a placeholder id, fetches nothing, and shows the
/// customer an empty page as though the catalog were empty.
///
/// The instance that shipped: the Beauty & Wellness options route coerced its
/// extra with `int.tryParse('$extra') ?? 0` and passed `serviceId: 0` down.
/// `StoreOptionItems.merchantServiceID` is a String that DEFAULTS TO "0", so a
/// row whose id the API omits reaches it by an ordinary tap.
///
/// The second group is the part that matters more: it fails the *class* of
/// defect rather than the one that was found, by scanning every route builder
/// for an identity coercion that cannot fail.
library;

import 'dart:io';

import 'package:client/common/presentation/routes/main_router.dart';
import 'package:flutter_test/flutter_test.dart';

/// An identity coercion that cannot fail: parse, then substitute a literal.
final _coercion = RegExp(r'int\.tryParse\([^)]*\)\s*\?\?\s*\d');

/// Prose that merely *describes* a coercion is not one.
bool _isComment(String line) => line.trimLeft().startsWith('//');

void main() {
  group('asServiceId refuses what it cannot resolve', () {
    test('accepts a positive int', () {
      expect(MainRouter.asServiceId(180), 180);
    });

    test('accepts a numeric string, because the model carries one', () {
      // StoreOptionItems.merchantServiceID is declared String, not int.
      expect(MainRouter.asServiceId('180'), 180);
      expect(MainRouter.asServiceId('  180  '), 180);
    });

    test('rejects "0" — the model default when the API omits the id', () {
      // The exact value that shipped as a real Service id.
      expect(MainRouter.asServiceId('0'), isNull);
      expect(MainRouter.asServiceId(0), isNull);
    });

    test('rejects a negative id', () {
      expect(MainRouter.asServiceId(-1), isNull);
      expect(MainRouter.asServiceId('-1'), isNull);
    });

    test('rejects absent and unparseable extras', () {
      expect(MainRouter.asServiceId(null), isNull);
      expect(MainRouter.asServiceId(''), isNull);
      expect(MainRouter.asServiceId('abc'), isNull);
      expect(MainRouter.asServiceId(const <String, dynamic>{}), isNull);
      // The old code did `int.tryParse('$extra')`, which stringifies an object
      // and parses the result — reliably null, but only by accident.
      expect(MainRouter.asServiceId(Object()), isNull);
    });

    test('a double is not an id', () {
      // Row ids are integers. Accepting 180.7 would round into a real row.
      expect(MainRouter.asServiceId(180.7), isNull);
    });
  });

  group('no route builder invents an identity', () {
    test('the detector fires on a known-bad line, and ignores prose', () {
      // A scan that only ever reports clean is indistinguishable from a scan
      // that is broken. This pins both directions.
      //
      // It is not hypothetical: the first run of the scan below flagged the doc
      // comment in `asServiceId` that quotes the old coercion. Comments are
      // excluded now, so the exclusion itself needs a fixture too.
      expect(_coercion.hasMatch("int.tryParse('\$extra') ?? 0"), isTrue);
      expect(_coercion.hasMatch('int.tryParse(raw) ?? 1'), isTrue);
      expect(_coercion.hasMatch('int.tryParse(raw)'), isFalse);
      expect(_isComment("  /// coerced with int.tryParse('\$x') ?? 0"), isTrue);
      expect(_isComment("  // int.tryParse(x) ?? 0"), isTrue);
      expect(_isComment('  final id = int.tryParse(x) ?? 0;'), isFalse);
    });

    test('no identity coercion falls back to a literal id', () {
      // readAsLinesSync handles LF and CRLF itself. A fixed-byte window over
      // the source would not, and this repo is edited on Windows.
      final lines = File('lib/common/presentation/routes/main_router.dart')
          .readAsLinesSync();

      final offenders = lines
          .asMap()
          .entries
          .where((e) => !_isComment(e.value))
          .where((e) => _coercion.hasMatch(e.value))
          .map((e) => 'line ${e.key + 1}: ${e.value.trim()}')
          .toList();

      expect(
        offenders,
        isEmpty,
        reason: 'A route that cannot resolve its identity must recover to Home, '
            'not substitute a literal. Use MainRouter.asServiceId and bounce '
            'when it returns null.\n${offenders.join('\n')}',
      );
    });

    test('every identity-bearing route recovers to Home', () {
      final source = File('lib/common/presentation/routes/main_router.dart')
          .readAsStringSync();

      // Each of these routes takes required identity through `extra`. The
      // recovery is the same in all of them, and this asserts none silently
      // loses it.
      const identityRoutes = <String>[
        'JobOrderScreen',
        'StoreItemsScreen',
        'BookingOtpScreen',
        'PaymentWebViewScreen',
        'ItemOptionMenuScreen',
        'BwOptionsScreen',
      ];

      for (final route in identityRoutes) {
        final start = source.indexOf('$route.route');
        expect(start, greaterThan(-1), reason: '$route is not routed');

        // The builder for this route, up to the start of the next GoRoute.
        final nextRoute = source.indexOf('GoRoute(', start);
        final body =
            source.substring(start, nextRoute == -1 ? source.length : nextRoute);

        expect(
          body.contains('HomeScreen.routeName'),
          isTrue,
          reason: '$route takes identity from `extra` but has no recovery. '
              'A lost extra — a deep link, a web refresh, a process restart — '
              'must land the customer on Home, never on a screen bound to an '
              'identity that was never resolved.',
        );
      }
    });
  });
}
