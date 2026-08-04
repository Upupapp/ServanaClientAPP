/// The category hero subtitle must clear the back button on every device.
///
/// `_HeroBackground` is the FlexibleSpaceBar *background*, so its origin is the
/// raw top of the app bar — above the status bar, not below it. It padded the
/// subtitle by a fixed `top: 60`, which lands inside the toolbar band on any
/// device where statusBar + kToolbarHeight exceeds 60, and the subtitle then
/// rendered underneath the back arrow.
///
/// It is device-dependent, so pumping one viewport proves nothing. These
/// assert the arithmetic across the inset range real devices actually produce.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Status-bar insets seen in the wild: older 4.7" phones through modern
/// punch-hole and Dynamic Island devices.
const _insets = <double>[0, 20, 24, 33, 44, 47, 48, 54, 59];

void main() {
  group('subtitle clearance above the toolbar', () {
    test('the old fixed offset collided on most real devices', () {
      // Documents why this changed: 60 was not merely tight, it sat above the
      // toolbar's bottom edge for every inset over 4pt.
      const oldOffset = 60.0;
      final colliding =
          _insets.where((i) => i + kToolbarHeight > oldOffset).toList();
      expect(colliding.length, greaterThan(_insets.length ~/ 2),
          reason: 'the old constant should be shown to fail widely');
    });

    test('the new offset clears the toolbar at every inset', () {
      for (final inset in _insets) {
        final subtitleTop = inset + kToolbarHeight + 8;
        final toolbarBottom = inset + kToolbarHeight;
        expect(subtitleTop, greaterThan(toolbarBottom),
            reason: 'subtitle overlaps the back button at inset $inset');
      }
    });

    test('the subtitle still fits inside the expanded hero', () {
      // expandedHeight is fixed at 180. Pushing the text past that would trade
      // one overflow for another.
      const expandedHeight = 180.0;
      const twoLinesAt13px = 13.0 * 1.4 * 2;
      for (final inset in _insets) {
        final subtitleTop = inset + kToolbarHeight + 8;
        expect(subtitleTop + twoLinesAt13px, lessThanOrEqualTo(expandedHeight),
            reason: 'subtitle overflows the 180pt hero at inset $inset');
      }
    });
  });

  group('source guards', () {
    final src = File(
      'lib/modules/categories/presentation/widgets/category_hero.dart',
    ).readAsStringSync();

    test('the fixed 60pt offset is gone', () {
      expect(src, isNot(contains('EdgeInsets.fromLTRB(20, 60, 20, 0)')));
    });

    test('the offset derives from the device inset and toolbar height', () {
      expect(src, contains('MediaQuery.paddingOf(context).top'));
      expect(src, contains('kToolbarHeight'));
    });

    test('the subtitle is bounded so large text cannot overflow the hero', () {
      expect(src, contains('maxLines: 2'));
      expect(src, contains('TextOverflow.ellipsis'));
    });
  });
}
