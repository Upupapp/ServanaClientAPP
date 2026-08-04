/// The address form must not invent a location, and must not write the city
/// into the street line.
///
/// Two defects, found tracing the "Taguig, Taguig" report against 1.0.0+36.
///
/// 1. `_composeAddressLine` appended `locality` — the city — to the street
///    line, while `_reverseGeocodeAndFill` put the same `locality` into the
///    city field. One value in two columns, printed twice by every screen.
///
/// 2. The worse one. With no initial location the map opens on a hardcoded
///    BGC/Taguig fallback and then tries GPS. The GPS auto-attempt swallows
///    failures deliberately — but the map still lays out, still fires
///    `onCameraIdle`, and that idle reverse-geocoded whatever the camera was
///    sitting on. Whenever GPS was off, denied or slow, that was the fallback.
///    A customer anywhere in the country could save an address geocoded from
///    Taguig, with the fallback's coordinates attached — and those coordinates
///    feed the geo record behind coverage checks and dispatch. It looked like a
///    formatting bug and was a wrong-location bug.
///
/// Source-level assertions: the screen needs a live GoogleMap, a platform
/// geocoder and a real GPS fix to build, and the standing rule is that
/// validation stops at `flutter analyze` + `flutter test`. What is checkable
/// without those is the decision logic, and that is what broke.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Comments are stripped before every assertion.
///
/// The fix documents the old behaviour in prose — it names `locality`, quotes
/// "Taguig, Taguig", and explains the fallback — because naming a defect is the
/// point of the comment. A raw substring check matches that prose and reports a
/// bug that is not there.
String _code(String path) => File(path).readAsLinesSync().where((l) {
      final t = l.trimLeft();
      return !t.startsWith('//') && !t.startsWith('///');
    }).join('\n');

void main() {
  late final String form;

  setUpAll(() {
    form = _code('lib/common/presentation/screens/address_form_screen.dart');
  });

  group('the street line excludes the city', () {
    test('_composeAddressLine no longer reads locality', () {
      final start = form.indexOf('String _composeAddressLine(');
      expect(start, greaterThan(-1));
      final body =
          form.substring(start, form.indexOf('}', form.indexOf(']', start)));

      expect(body, isNot(contains('p.locality')),
          reason: 'the city belongs to postTown alone; putting it here is what '
              'produced "Taguig, Taguig"');
    });

    test('it still carries the barangay', () {
      final start = form.indexOf('String _composeAddressLine(');
      final body =
          form.substring(start, form.indexOf('}', form.indexOf(']', start)));

      // subLocality is the barangay and nothing else carries it: addressTwo is
      // unit+street, postTown is the city. Dropping it would be data loss, not
      // deduplication.
      expect(body, contains('p.subLocality'));
      expect(body, contains('p.thoroughfare'));
      expect(body, contains('p.subThoroughfare'));
    });

    test('the city field is still populated from locality', () {
      // The value is not discarded — it moves to the field that owns it.
      expect(form,
          contains("_cityController.text = (place.locality ?? '').trim()"));
    });

    test('the hint no longer asks for the city in that field', () {
      expect(
        form,
        isNot(contains(
            "'House/Unit/Building, Street, Barangay, City, Province'")),
        reason: 'asking for the city here is what taught customers to type it '
            'into the line the city gets appended to',
      );
      expect(form, contains("hint: 'House/Unit/Building, Street, Barangay'"));
    });
  });

  group('an unchosen pin is never geocoded', () {
    test('the flag exists and starts set when there is no initial location',
        () {
      expect(form, contains('bool _pinIsUnconfirmed'));
      expect(form, contains('_pinIsUnconfirmed = true'));
    });

    test('onCameraIdle refuses to geocode while it is set', () {
      final start = form.indexOf('Future<void> _onCameraIdle()');
      expect(start, greaterThan(-1));
      final body = form.substring(
          start, form.indexOf('Future<void> _reverseGeocodeAndFill'));

      expect(body, contains('if (_pinIsUnconfirmed) return;'),
          reason: 'without this the BGC fallback is geocoded into the '
              "customer's address whenever GPS fails");

      // Order matters: the guard must precede the geocode call, not follow it.
      expect(body.indexOf('_pinIsUnconfirmed'),
          lessThan(body.indexOf('_reverseGeocodeAndFill')));
    });

    test('a real GPS fix clears it', () {
      final start = form.indexOf('Future<void> _recenterOnGps(');
      final body =
          form.substring(start, form.indexOf('Future<void> _animateTo'));
      expect(body, contains('_pinIsUnconfirmed = false'));

      // It must clear only on the success path — after the await, before the
      // catch. Clearing in the catch would restore the original bug.
      expect(body.indexOf('_pinIsUnconfirmed = false'),
          lessThan(body.indexOf('} catch')));
    });

    test('touching the map clears it', () {
      // Listener, not GestureDetector: the map claims pan gestures, so a
      // GestureDetector never sees them.
      expect(form, contains('onPointerDown:'));
      expect(form, contains('setState(() => _pinIsUnconfirmed = false)'));
    });

    test('the customer is told when nothing was located', () {
      // Previously silent — the fallback pin looked like a result.
      expect(form, contains("We couldn't detect your location"));
    });
  });

  group('the GPS auto-attempt still fails quietly', () {
    test('showFailureFeedback is still false on the automatic call', () {
      // The fix must not turn a silent retry into a snackbar on every cold
      // start; the inline notice covers it instead.
      expect(form, contains('_recenterOnGps(showFailureFeedback: false)'));
    });
  });

  group('every screen joins addresses through one formatter', () {
    // Seven screens each built their own '$addressOne, $postTown'. Each one was
    // a separate chance to get it wrong, and all seven were wrong the same way.
    for (final path in const [
      'lib/modules/bw_booking/presentation/screens/bw_checkout_screen.dart',
      'lib/modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart',
      'lib/modules/bw_booking/presentation/screens/bw_confirmation_screen.dart',
      'lib/modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart',
      'lib/modules/bw_booking/data/bw_booking_store.dart',
      'lib/modules/aircon_booking/data/aircon_booking_store.dart',
      'lib/common/data/backend/http_backend.dart',
    ]) {
      test('${path.split('/').last} uses formatAddressLine', () {
        final src = _code(path);
        expect(src, contains('formatAddressLine('),
            reason: '$path still joins the address itself');
      });
    }

    test('no hand-rolled join survives anywhere in lib/', () {
      final offenders = <String>[];
      for (final e in Directory('lib').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final src = _code(e.path);
        if (RegExp(r"\$\{?[\w'\[\]?. ]*postTown[\w'\[\]?. ]*\}?'")
                .hasMatch(src) &&
            !src.contains('formatAddressLine(')) {
          offenders.add(e.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'these interpolate postTown without the shared formatter:\n'
              '${offenders.join('\n')}');
    });
  });
}
