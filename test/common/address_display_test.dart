/// Addresses must not print their city twice, and must not lose a real one.
///
/// Reported from production against 1.0.0+36: the checkout address list showed
/// two rows reading "Home / Taguig, Taguig" and "Home / 15, Del Pilar, Manila,
/// Manila".
///
/// Nothing duplicated the city in storage. `_composeAddressLine` in the address
/// form appended `locality` to the street line, and `_reverseGeocodeAndFill`
/// put that same `locality` into the city field. One value, written to two
/// columns, then printed by seven screens that each assumed the street line was
/// street-level only.
///
/// The form no longer writes it, but rows saved by 1.0.0+36 still carry it and
/// nothing rewrites them — so the display has to cope with both shapes.
library;

import 'package:client/common/domain/address/address_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the two rows that were reported', () {
    test('"Taguig" + "Taguig" collapses to one Taguig', () {
      expect(formatAddressLine('Taguig', 'Taguig'), 'Taguig');
    });

    test('"15, Del Pilar, Manila" + "Manila" drops the repeat', () {
      expect(
        formatAddressLine('15, Del Pilar, Manila', 'Manila'),
        '15, Del Pilar, Manila',
      );
    });
  });

  group('addresses saved after the fix', () {
    test('a street-level line still gets its city appended', () {
      // The form now writes street-level only, so this is the shape every new
      // row has. Suppressing the city here would be the opposite bug.
      expect(
        formatAddressLine('15, Del Pilar, San Antonio', 'Manila'),
        '15, Del Pilar, San Antonio, Manila',
      );
    });

    test('an empty street line falls back to the city alone', () {
      expect(formatAddressLine('', 'Makati City'), 'Makati City');
      expect(formatAddressLine(null, 'Makati City'), 'Makati City');
    });

    test('a missing city leaves the line untouched', () {
      expect(formatAddressLine('15, Del Pilar', ''), '15, Del Pilar');
      expect(formatAddressLine('15, Del Pilar', null), '15, Del Pilar');
    });

    test('both empty yields empty, not a stray comma', () {
      // The old join produced ", " here and leaned on a regex to strip it.
      expect(formatAddressLine('', ''), '');
      expect(formatAddressLine(null, null), '');
    });
  });

  group('what must NOT be stripped', () {
    test('a city name inside a street name survives', () {
      // "Manila Street" in Quezon City. A substring check would cut the street
      // name in half — corrupting a correct address to tidy a broken one.
      expect(
        formatAddressLine('12 Manila Street, Project 4', 'Quezon City'),
        '12 Manila Street, Project 4, Quezon City',
      );
    });

    test('a city appearing mid-line, not at the end, survives', () {
      expect(
        formatAddressLine('Makati Avenue, Poblacion', 'Makati'),
        'Makati Avenue, Poblacion, Makati',
      );
    });

    test('a partial match is not treated as a repeat', () {
      // "Manila" vs "Manila City" are different strings; only a whole trailing
      // component counts.
      expect(
        formatAddressLine('15, Del Pilar, Manila', 'Manila City'),
        '15, Del Pilar, Manila, Manila City',
      );
    });
  });

  group('tolerances', () {
    test('case differences still count as a repeat', () {
      // The two values arrive from different sources — a typed field and a
      // geocoder response — so they disagree on case routinely.
      //
      // The surviving copy takes the CITY field's casing, not the street
      // line's. postTown is the canonical city column, so "15, Del Pilar,
      // Manila" is the better of the two renderings and a customer who typed
      // "manila" in a hurry still sees it presented properly. This test
      // originally asserted the opposite and was wrong.
      expect(formatAddressLine('15, Del Pilar, manila', 'Manila'),
          '15, Del Pilar, Manila');
      expect(formatAddressLine('TAGUIG', 'Taguig'), 'Taguig');
    });

    test('surrounding whitespace is ignored', () {
      expect(formatAddressLine('15, Del Pilar,  Manila ', ' Manila '),
          '15, Del Pilar, Manila');
    });
  });

  group('the backfill predicate agrees with the display', () {
    // A backfill that used its own rule would drift from what customers see.
    test('flags exactly the rows the display would dedupe', () {
      expect(addressLineRepeatsCity('Taguig', 'Taguig'), isTrue);
      expect(addressLineRepeatsCity('15, Del Pilar, Manila', 'Manila'), isTrue);
      expect(addressLineRepeatsCity('15, Del Pilar, San Antonio', 'Manila'),
          isFalse);
      expect(
          addressLineRepeatsCity('12 Manila Street', 'Quezon City'), isFalse);
      expect(addressLineRepeatsCity('', 'Manila'), isFalse);
      expect(addressLineRepeatsCity('Manila', ''), isFalse);
    });

    test('predicate and formatter never disagree', () {
      // Property check across the cases above: if the predicate says a row
      // repeats, the formatter must shorten it; if not, it must not.
      const cases = <List<String>>[
        ['Taguig', 'Taguig'],
        ['15, Del Pilar, Manila', 'Manila'],
        ['15, Del Pilar, San Antonio', 'Manila'],
        ['12 Manila Street, Project 4', 'Quezon City'],
        ['Makati Avenue, Poblacion', 'Makati'],
        ['TAGUIG', 'Taguig'],
      ];
      for (final c in cases) {
        final repeats = addressLineRepeatsCity(c[0], c[1]);
        final joined = formatAddressLine(c[0], c[1]);
        final naive = '${c[0]}, ${c[1]}';
        expect(joined == naive, !repeats,
            reason: 'disagreement on "${c[0]}" + "${c[1]}"');
      }
    });
  });
}
