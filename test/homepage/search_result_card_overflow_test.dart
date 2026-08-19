/// The search results grid must not overflow its tiles.
///
/// Found by running the app on a Pixel 8 emulator: every card in the search
/// results grid painted "BOTTOM OVERFLOWED BY 0.556 PIXELS".
///
/// Half a pixel is not a visual defect, and that is exactly why it survived —
/// nothing looked wrong in a screenshot, and no test rendered the card at a
/// real tile size. But it is a genuine RenderFlex overflow, and the same layout
/// overflowed by ~24 logical pixels on a 360-wide phone at 1.3x text scale,
/// where it is a visibly clipped card rather than a debug stripe.
///
/// **These tests render the real [SearchResultCard].** The first version pumped
/// a hand-written copy of its layout, and that copy passed against the broken
/// production widget — a copy only ever tests the copy. `SearchResultCard` was
/// made `@visibleForTesting` specifically so this file can build the actual
/// thing at actual grid-tile sizes.
///
/// `tester.pumpWidget` surfaces a RenderFlex overflow as a thrown FlutterError,
/// so these fail on the defect rather than merely describing it.
library;

import 'dart:io';

import 'package:client/modules/homepage/presentation/screens/search_screen.dart';
import 'package:client/modules/search/domain/search_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors `_buildResultsGrid`'s delegate in search_screen.dart. Held in sync
/// by `the production grid delegate still matches this test` below.
const double kCrossAxisSpacing = 12;
const double kMainAxisSpacing = 12;
const double kChildAspectRatio = 0.72;
const EdgeInsets kGridPadding = EdgeInsets.fromLTRB(16, 4, 16, 24);

// `level2` is now the Service NAME and `categoryLabel` the hierarchy path —
// the card renders both, so the overflow rows this test pins are unchanged in
// length even though the fields they come from moved.
SearchResult _result({
  required String level2,
  required int minPrice,
  required int maxPrice,
  required String categoryLabel,
}) =>
    SearchResult(
      serviceId: 15,
      serviceName: level2,
      subcategoryId: 7,
      subcategoryName: level2,
      categoryId: 3,
      categoryName: categoryLabel,
      minPricePesos: minPrice,
      maxPricePesos: maxPrice,
      bookable: true,
    );

/// The exact rows from the emulator screenshot that overflowed.
final _realItems = <SearchResult>[
  _result(
      level2: 'Facial',
      minPrice: 1000,
      maxPrice: 3000,
      categoryLabel: 'Beauty & Wellness'),
  _result(
      level2: 'Hair',
      minPrice: 300,
      maxPrice: 900,
      categoryLabel: 'Hair & Nails'),
  _result(
      level2: 'Massage',
      minPrice: 400,
      maxPrice: 1200,
      categoryLabel: 'Massage'),
  _result(
      level2: 'Beauty Drip',
      minPrice: 990,
      maxPrice: 2500,
      categoryLabel: 'Beauty & Wellness'),
];

Widget _grid(List<SearchResult> items) => MaterialApp(
      home: Scaffold(
        body: GridView.builder(
          padding: kGridPadding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: kCrossAxisSpacing,
            mainAxisSpacing: kMainAxisSpacing,
            childAspectRatio: kChildAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) =>
              SearchResultCard(result: items[i], onTap: () {}),
        ),
      ),
    );

void main() {
  group('search results grid does not overflow', () {
    // Logical sizes of devices this actually ships to. The Pixel 8 entry is the
    // one that reproduced the reported defect.
    const sizes = <String, Size>{
      'Pixel 8 (411x914)': Size(411, 914),
      'small phone (360x640)': Size(360, 640),
      'large phone (430x932)': Size(430, 932),
      'tablet (768x1024)': Size(768, 1024),
    };

    for (final entry in sizes.entries) {
      testWidgets('no overflow on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_grid(_realItems));
        await tester.pump();

        expect(tester.takeException(), isNull,
            reason: 'the card overflowed its grid tile on ${entry.key}');
      });
    }

    testWidgets('no overflow with a long title that wraps to two lines',
        (tester) async {
      tester.view.physicalSize = const Size(411, 914) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_grid([
        _result(
          level2: 'Deep Tissue Therapeutic Full Body Massage',
          minPrice: 1250,
          maxPrice: 4000,
          categoryLabel: 'Beauty & Wellness',
        ),
      ]));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 1.3x text scale', (tester) async {
      // The app clamps nav labels to 1.3x (servana_nav_item.dart), so 1.3 is
      // the largest scale the design is expected to hold. A half-pixel margin
      // is not a margin at all at that scale.
      tester.view.physicalSize = const Size(411, 914) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: _grid(_realItems),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'card overflowed once text was scaled to 1.3x');
    });

    testWidgets('the quote-price variant also fits', (tester) async {
      // minPricePesos <= 0 renders "Get a quote" instead of "From ₱N", a
      // different string length on the same line.
      tester.view.physicalSize = const Size(360, 640) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_grid([
        _result(
            level2: 'Custom Package',
            minPrice: 0,
            maxPrice: 0,
            categoryLabel: 'Beauty & Wellness'),
      ]));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('the production grid delegate still matches this test', () {
    late final String src;

    setUpAll(() {
      src = File(
        'lib/modules/homepage/presentation/screens/search_screen.dart',
      ).readAsStringSync();
    });

    test('search_screen.dart uses the values pumped above', () {
      // If someone retunes the grid, the fixtures above stop representing the
      // real screen and would keep passing while it overflows again.
      expect(src, contains('childAspectRatio: $kChildAspectRatio'));
      expect(src, contains('crossAxisSpacing: ${kCrossAxisSpacing.toInt()}'));
      expect(src, contains('mainAxisSpacing: ${kMainAxisSpacing.toInt()}'));
    });

    test('the card image absorbs the slack instead of being a hard square', () {
      // A fixed square image plus fixed text heights cannot divide evenly into
      // a tile height derived from an aspect ratio, so the image has to be the
      // flexible part.
      //
      // Comments are stripped first: the source explains the old AspectRatio in
      // prose, and a naive substring check matches the explanation rather than
      // the code — which is exactly how this assertion first failed against a
      // correct implementation.
      final card = src
          .substring(src.indexOf('class SearchResultCard'))
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');

      expect(card, contains('Expanded('),
          reason: 'SearchResultCard must let the image absorb slack');
      expect(card, isNot(contains('AspectRatio(')),
          reason: 'a hard square image is what did not fit the tile');
    });
  });
}
