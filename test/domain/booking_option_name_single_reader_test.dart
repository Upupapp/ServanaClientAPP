/// The name of the thing being booked is read in ONE place.
///
/// ## The defect this pins
///
/// `canonicalOptionMap` — the only thing that builds an option map for a
/// Catalog V2 Service — writes the service name under `'level3'`:
///
///     'level3': service.name,
///
/// Six screens and stores read it back as `opt['level_3']`, with an underscore,
/// then fall through `name` and `optionName` (which the canonical map does not
/// set either) to a hardcoded literal. The result, measured on a device on
/// 2026-08-20: booking **Wiring fixtures**, an ELECTRICAL service, produced a
/// checkout reading
///
///     Booking Summary — Beauty & Wellness Service — ₱5000.00
///
/// Every service booked through the canonical catalogue was mislabelled, on
/// both checkout and confirmation, in both the beauty and aircon flows. Nothing
/// failed: the fallback is a valid String, so the app rendered a confident lie.
///
/// `ServiceOptionDisplay.name()` already existed and already handled BOTH
/// spellings. All six sites bypassed it. This test is the reason they cannot
/// bypass it again — a foundation with no callers defends nothing.
///
/// ## Why it scans source
///
/// The six readers are private methods with no seam to drive from a unit test.
/// A source scan is the honest way to assert "there is one reader", and it is
/// the assertion that would actually have caught this: the helper was always
/// correct, so testing the helper proves nothing about who calls it.
library;

import 'dart:io';

import 'package:client/common/domain/services/service_option_display.dart';
import 'package:client/modules/catalog/application/canonical_booking_handoff.dart'
    show canonicalOptionMap;
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Line endings normalised — a CRLF checkout must not change what this sees.
String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    fail('$path does not exist — this test asserts against a file that has '
        'moved or been deleted.');
  }
  return file.readAsStringSync().replaceAll('\r\n', '\n');
}

/// Every file that displays or reports the booked option's name.
const _bookingSites = <String>[
  'lib/modules/bw_booking/data/bw_booking_store.dart',
  'lib/modules/bw_booking/presentation/screens/bw_checkout_screen.dart',
  'lib/modules/bw_booking/presentation/screens/bw_confirmation_screen.dart',
  'lib/modules/aircon_booking/data/aircon_booking_store.dart',
  'lib/modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart',
  'lib/modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart',
];

void main() {
  group('the writer and the reader agree on the key', () {
    test('the canonical map key is one ServiceOptionDisplay understands', () {
      // Drives the REAL `canonicalOptionMap` rather than a hand-written map of
      // what it is believed to produce. A test that restates the production
      // value cannot catch the production value changing — and this defect was
      // precisely a rename on one side that the other side never saw.
      //
      // The service is the one that exposed the bug on a device: Electrical,
      // the only Home Maintenance service, whose checkout read "Beauty &
      // Wellness Service".
      final map = canonicalOptionMap(const CatalogServiceDetail(
        service: CatalogService(
          id: 7,
          subcategoryId: 24,
          subcategoryName: 'Electrical',
          categoryId: 3,
          categoryName: 'Home Maintenance',
          name: 'Wiring fixtures',
          slug: 'wiring-fixtures',
          status: CatalogStatus.active,
          displayOrder: 1,
          bookable: true,
        ),
        available: true,
      ));

      expect(ServiceOptionDisplay.name(map), 'Wiring fixtures',
          reason: 'the handoff and the display helper disagree on the key, so '
              'every canonical booking renders a fallback label');
      // And the reverse spelling still resolves, because legacy option maps
      // coming from `service_options` use it.
      expect(
        ServiceOptionDisplay.name(const {'level_3': 'Gluta Drip'}),
        'Gluta Drip',
      );
    });

    test('the handoff writes a key the helper actually reads', () {
      // Guards the pair rather than either half: this is the contract that
      // broke, and it broke because the two sides were edited independently.
      final source = _read(
          'lib/modules/catalog/application/canonical_booking_handoff.dart');
      final written = RegExp(r"'(level_?3)':").allMatches(source).map(
            (m) => m.group(1)!,
          );

      expect(written, isNotEmpty,
          reason: 'canonicalOptionMap no longer names the service at all');
      for (final key in written) {
        expect(
          ServiceOptionDisplay.name({key: 'Probe'}),
          'Probe',
          reason: '`$key` is written by canonicalOptionMap but '
              'ServiceOptionDisplay.name does not read it',
        );
      }
    });
  });

  group('there is exactly one reader', () {
    test('no booking screen or store hand-rolls the option-name lookup', () {
      // Whole-file scan, NOT line-by-line: `dart format` splits these lookups
      // across four lines, and a per-line matcher would find nothing and pass
      // vacuously — the same trap that made an earlier reachability guard
      // useless.
      final offenders = <String>[];
      for (final path in _bookingSites) {
        final source = _read(path);
        if (RegExp(r"\[\s*'level_?3'\s*\]").hasMatch(source)) {
          offenders.add(path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'these read the option name directly instead of calling '
            'ServiceOptionDisplay.name(), which is how `level3` and `level_3` '
            'drifted apart and mislabelled every canonical booking',
      );
    });

    test('the hardcoded fallback label is not repeated across the flows', () {
      // Three copies of "Beauty & Wellness Service" and three of "Aircon
      // Service" is one rule stated six times. The point is not the string —
      // it is that six copies drift, and these six already had.
      for (final label in ['Beauty & Wellness Service', 'Aircon Service']) {
        final copies = _bookingSites
            .where((path) => _read(path).contains("'$label'"))
            .length;
        expect(
          copies,
          lessThanOrEqualTo(1),
          reason: '"$label" is hardcoded in $copies booking files',
        );
      }
    });

    test('every booking site routes through the shared helper', () {
      // The inverse of the scan above. Without this, deleting the lookup
      // entirely would pass — an empty screen is not a fixed screen.
      for (final path in _bookingSites) {
        expect(
          _read(path),
          contains('ServiceOptionDisplay.name('),
          reason: '$path no longer resolves the option name at all',
        );
      }
    });
  });
}
