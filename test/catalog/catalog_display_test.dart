/// Catalog display defects found by the six-pass services audit.
///
/// Three separate bugs, one theme: a value arrived in a shape the reader did not
/// expect, and the screen showed *something* rather than nothing — so nobody
/// noticed. None of the three had a test.
library;

import 'package:client/common/domain/pricing/catalog_price.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('price extraction is shared, so screens cannot disagree', () {
    // search_repository read only `base_price` and cast it `as num?`, defaulting
    // to 0 — and SearchResult renders 0 as "Get a quote". category_experience
    // read four keys and parsed strings. The same option could therefore show a
    // price on a category card and "Get a quote" in search.
    //
    // The spellings genuinely differ by endpoint: /services/full writes
    // `base_price` explicitly, /options-with-addons ships `basePrice` via
    // toCamel. Neither reader should hardcode one.

    test('reads the snake spelling /services/full sends', () {
      expect(extractCatalogPricePesos({'base_price': 3190}), 3190);
    });

    test('reads the camel spelling options-with-addons sends', () {
      expect(extractCatalogPricePesos({'basePrice': 3190}), 3190);
    });

    test('parses a numeric string, which pg returns for NUMERIC columns', () {
      // The old `as num?` cast yielded null here, so a priced service rendered
      // as "Get a quote".
      expect(extractCatalogPricePesos({'base_price': '3190'}), 3190);
    });

    test('tolerates currency formatting in a string price', () {
      expect(extractCatalogPricePesos({'base_price': '₱3,190.00'}), 3190);
    });

    test('falls back through price and amount', () {
      expect(extractCatalogPricePesos({'price': 500}), 500);
      expect(extractCatalogPricePesos({'amount': 750}), 750);
    });

    test('prefers the first populated key in order', () {
      expect(
        extractCatalogPricePesos({'basePrice': 100, 'price': 999}),
        100,
      );
    });

    test('an unpriced row is null, NOT zero', () {
      // The distinction the old `?? 0` destroyed: null means "ask for a quote",
      // 0 means the item is genuinely free. Collapsing them is what put
      // "Get a quote" on services that had a price.
      expect(extractCatalogPricePesos({}), isNull);
      expect(extractCatalogPricePesos({'base_price': null}), isNull);
    });

    test('a genuine zero survives as zero', () {
      expect(extractCatalogPricePesos({'base_price': 0}), 0);
      expect(extractCatalogPricePesosInt({'base_price': 0}), 0);
    });

    test('the int form rounds rather than truncating', () {
      expect(extractCatalogPricePesosInt({'base_price': 3190.6}), 3191);
    });

    test('garbage does not throw', () {
      expect(extractCatalogPricePesos({'base_price': 'n/a'}), isNull);
      expect(extractCatalogPricePesos({'base_price': <String, dynamic>{}}),
          isNull);
    });
  });

  group('level_2 matching is substring, not equality', () {
    // The Beauty & Wellness allow-list is {'drip','facial'} while the backend
    // sends 'Beauty Drip' and 'Beauty Drip Add Ons' (migration 005). Exact
    // membership could never match, so all 10 Beauty Drip treatments were
    // filtered out and the Drip chip selected nothing.
    //
    // This was masked while the backend dropped level2 from /services/full
    // entirely: the repository short-circuits on an empty value, so everything
    // was included. Fixing the catalog to send names is what made the filter
    // start excluding.
    bool matches(Set<String> allowList, String level2) =>
        allowList.any((a) => level2.toLowerCase().contains(a));

    const allowList = {'drip', 'facial'};

    test('the real level_2 values now match', () {
      expect(matches(allowList, 'Beauty Drip'), isTrue);
      expect(matches(allowList, 'Beauty Drip Add Ons'), isTrue);
      expect(matches(allowList, 'Facial'), isTrue);
    });

    test('exact matching would have failed on the same values', () {
      // Pins the regression itself rather than only the fix.
      expect(allowList.contains('beauty drip'), isFalse);
      expect(allowList.contains('beauty drip add ons'), isFalse);
    });

    test('unrelated categories are still excluded', () {
      expect(matches(allowList, 'Massage'), isFalse);
      expect(matches(allowList, 'Hair'), isFalse);
      expect(matches(allowList, 'Nails'), isFalse);
    });

    test('a future label variant matches without another edit', () {
      expect(matches(allowList, 'Beauty Drip Premium'), isTrue);
    });
  });

  group('featured services interleave instead of truncating one category', () {
    // `[...bwItems, ...airconItems].take(12)` filled its window from Beauty &
    // Wellness — which seeds well over twelve options — before reaching any
    // aircon item, so "Featured Services" could never feature an aircon
    // service. A cap that reads as a display limit was acting as a filter.
    List<String> featured(List<String> bw, List<String> ac, {int cap = 12}) {
      final all = <String>[];
      for (var i = 0;
          all.length < cap && (i < bw.length || i < ac.length);
          i++) {
        if (i < bw.length) all.add(bw[i]);
        if (all.length < cap && i < ac.length) all.add(ac[i]);
      }
      return all;
    }

    test('both categories appear when both have items', () {
      final out = featured(
        List.generate(30, (i) => 'bw$i'),
        List.generate(10, (i) => 'ac$i'),
      );
      expect(out.length, 12);
      expect(out.any((s) => s.startsWith('ac')), isTrue);
      expect(out.any((s) => s.startsWith('bw')), isTrue);
    });

    test('the old concatenate-then-take showed zero aircon items', () {
      final old =
          [...List.generate(30, (i) => 'bw$i'), 'ac0'].take(12).toList();
      expect(old.any((s) => s.startsWith('ac')), isFalse);
    });

    test('one empty category still fills the window', () {
      expect(featured(List.generate(30, (i) => 'bw$i'), const []).length, 12);
      expect(featured(const [], List.generate(30, (i) => 'ac$i')).length, 12);
    });

    test('fewer items than the cap returns them all, without padding', () {
      expect(featured(['a', 'b'], ['c']), ['a', 'c', 'b']);
    });

    test('both empty yields an empty list rather than throwing', () {
      expect(featured(const [], const []), isEmpty);
    });
  });
}
