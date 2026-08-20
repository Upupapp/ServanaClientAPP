/// A customer must not be able to walk into a flow the shipped build cannot
/// serve.
///
/// ## The measured fact this guards
///
/// `HttpBackend` — what a release build wires, because `MOCK_BACKEND` defaults
/// to `false` — answers the entire merchant / job-order surface with a stub:
/// `getMerchantDetails` and `getMerchantJoDetails` return null,
/// `getJobOrderItems` and `getJobOrderEmployees` return empty lists, and
/// `insertJobOrder` returns false.
///
/// Rendered against that composition rather than against the test container's
/// `MockBackend`, `JobOrderSummaryScreen` showed a booking summary that was
/// entirely invented: status **ACCEPTED** whatever the booking's real status,
/// **today's date** as the schedule, an empty service list, `Distance From
/// Office: null km`, and a total of **₱0.00**. `JobOrderScreen` ends in a
/// "Book Now" that calls `insertJobOrder`, which returns false every time.
///
/// The Booking Calendar in the home drawer used to open that summary for every
/// real booking. It now opens `BookingDetailScreen`, which reads the same
/// booking through `BookingRepository` and shows what the server actually
/// holds.
///
/// ## Why a property and not a spot check
///
/// The screens and their routes are deliberately KEPT, as Rewards and
/// Favourites were, for the release that builds the surface behind them. Kept
/// code is one `pushNamed` away from being reachable again, and the next such
/// edge will be added by someone who does not know the backend is a stub. So
/// this asserts the property — nothing OUTSIDE the flow navigates INTO it —
/// rather than the one instance that was wrong.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens whose data comes only from the stubbed surface.
const Set<String> kStubBackedScreens = {
  'JobOrderSummaryScreen',
  'JobOrderScreen',
  'StoreItemsScreen',
  'ItemOptionMenuScreen',
  'SelectPaymentMethodScreen',
  'AddAdditionalItemMenuScreen',
  'MerchantMenuScreen',
};

/// Files allowed to navigate within the flow.
///
/// The three module directories, plus `merchants_widget.dart`: it lives under
/// `homepage/` for historical reasons but its only renderer is
/// `job_order/presentation/widgets/booking_dialog_sheet.dart`, so it is inside
/// the flow in every sense but its path.
bool _insideFlow(String path) {
  final p = path.replaceAll(r'\', '/');
  return p.contains('/modules/job_order/') ||
      p.contains('/modules/merchant_menu/') ||
      p.contains('/modules/store_items/') ||
      p.endsWith('/homepage/presentation/widgets/merchants_widget.dart');
}

/// The router names every route, including ones only deep links reach. It is
/// the declaration site, not a navigation edge.
bool _isRouter(String path) =>
    path.replaceAll(r'\', '/').endsWith('/routes/main_router.dart');

void main() {
  test('nothing outside the merchant/job-order flow navigates into it', () {
    // Scanned over the WHOLE source, not line by line.
    //
    // The first version of this matched each line on its own and was therefore
    // vacuous against the only formatting this codebase uses: `dart format`
    // puts `context.pushNamed(` on one line and `SomeScreen.routeName` on the
    // next, so a per-line regex could never see a single real navigation edge.
    // It passed — and it still passed when the offending edge was put back,
    // which is how it was caught.
    final navigation = RegExp(
      r'(?:push|go|pushReplacement)Named\(\s*([A-Za-z_][A-Za-z0-9_]*)\.routeName',
      multiLine: true,
    );
    // Line comments are stripped first: a commented-out edge is not an edge,
    // and one widget file carries a disabled push in a comment block.
    final lineComment = RegExp(r'^[ \t]*//.*$', multiLine: true);

    final offenders = <String>[];
    var scanned = 0;
    var edgesSeen = 0;

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (_insideFlow(entity.path) || _isRouter(entity.path)) continue;
      scanned++;

      // Normalised: a CRLF checkout must not change what this test reads.
      final source = entity
          .readAsStringSync()
          .replaceAll('\r\n', '\n')
          .replaceAll(lineComment, '');

      for (final match in navigation.allMatches(source)) {
        edgesSeen++;
        final target = match.group(1)!;
        if (kStubBackedScreens.contains(target)) {
          final line =
              '\n'.allMatches(source.substring(0, match.start)).length + 1;
          offenders.add('${entity.path}:$line -> $target');
        }
      }
    }

    expect(scanned, greaterThan(100),
        reason: 'the scan found almost no files — it is not looking at lib/');
    // Without this, "no offenders" and "no matches at all" are the same result.
    expect(edgesSeen, greaterThan(20),
        reason: 'the navigation pattern matched almost nothing — it has '
            'stopped recognising how this codebase navigates, and would '
            'report any flow as unreachable');

    expect(
      offenders,
      isEmpty,
      reason: 'These navigate into a flow whose backend is a stub in every '
          'release build, so the customer reaches a screen showing fabricated '
          'data or a button that cannot succeed: ${offenders.join(', ')}. '
          'Either serve the flow for real, or route somewhere that is served. '
          'The Booking Calendar was the last such edge and now opens '
          'BookingDetailScreen.',
    );
  });

  test('the stubbed methods really are unconditional stubs', () {
    // Without this the test above is a rule about nothing: if the surface were
    // implemented, keeping these screens unreachable would be wrong rather
    // than right, and this file should be deleted instead of quietly passing.
    final backend = File('lib/common/data/backend/http_backend.dart')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');

    const stubs = {
      'getMerchantDetails': 'return null;',
      'getMerchantJoDetails': 'return null;',
      'getJobOrderItems': 'return [];',
      'getJobOrderEmployees': 'return [];',
      'insertJobOrder': 'return false;',
    };

    stubs.forEach((method, body) {
      final start = backend.indexOf('$method(');
      expect(start, greaterThan(-1),
          reason: 'HttpBackend no longer declares $method');

      // The next statement after the signature. A stub is short; if the method
      // has grown a real body, this window will not contain the bare return.
      final window = backend.substring(start, start + 400);
      expect(window, contains(body),
          reason: 'HttpBackend.$method is no longer a stub — the flow it '
              'serves may now be worth making reachable again, and this '
              "file's premise needs revisiting rather than its expectations "
              'relaxing');
    });
  });
}
