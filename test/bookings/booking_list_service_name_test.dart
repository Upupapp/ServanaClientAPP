/// A booking must not be labelled with a service nobody booked.
///
/// `_mapApiBookingToJobOrder` opened with
///
///     String serviceName = 'Beauty & Wellness';
///
/// and only moved off it when the booking carried an addon with a `level_3`.
/// Every booking without addons — a plumbing job, an aircon clean — was
/// therefore listed as Beauty & Wellness in the customer's own bookings screen
/// and calendar.
///
/// The name was invented here because the list endpoint genuinely did not
/// return one. `getBookingsByUserId` joined payments, branches, addresses and
/// workers but never the service, while the DETAIL query had been given those
/// joins some time ago. Backend 23a28e2 adds them to the list under the same
/// aliases, so the name is now read rather than guessed.
///
/// Same failure class as the ₱0.00 and Gulf-of-Guinea findings: a missing value
/// replaced by a plausible constant, which then reads as real data to
/// everything downstream. A blank label is recoverable; a confident wrong one
/// is not.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source with comment lines stripped, so a comment quoting the old default
/// cannot satisfy or fail an assertion about the code.
///
/// Read line-wise and rejoined with `\n` rather than sliced by byte offset:
/// this repo is checked out with CRLF on Windows, and a fixed-width window over
/// raw bytes lands in a different place there than it does in CI.
String _code(String path) => File(path).readAsLinesSync().where((l) {
      final t = l.trimLeft();
      return !t.startsWith('//') && !t.startsWith('///');
    }).join('\n');

void main() {
  late final String backend;

  setUpAll(() {
    backend = _code('lib/common/data/backend/http_backend.dart');
  });

  group('the invented default is gone', () {
    test('no service category is hardcoded as a fallback name', () {
      // The specific string, and the shape. A different plausible-looking
      // constant would be the same defect wearing another label.
      expect(backend, isNot(contains("serviceName = 'Beauty & Wellness'")));
      expect(backend, isNot(contains("String serviceName = 'Beauty")));
    });

    test('serviceName still starts from something, so it is never unassigned', () {
      expect(backend, contains('String serviceName = _firstNonEmpty('));
    });
  });

  group('the name is read from the response first', () {
    test('reads the keys the backend now returns', () {
      // Option name before service name before category: most specific first.
      // "Split-type cleaning" tells the customer more than "Aircon", which
      // tells them more than "Home services".
      final start = backend.indexOf('_firstNonEmpty([');
      expect(start, greaterThan(-1));
      final chain = backend.substring(start, start + 200);

      expect(chain.indexOf("b['serviceOptionName']"), greaterThan(-1));
      expect(chain.indexOf("b['serviceName']"), greaterThan(chain.indexOf("b['serviceOptionName']")));
      expect(chain.indexOf("b['serviceCategory']"), greaterThan(chain.indexOf("b['serviceName']")));
    });

    test('keeps the addon fallback for a build older than the deploy', () {
      // An app build outlives a deploy in both directions. A released binary
      // talking to an API without the new columns must degrade to the old
      // behaviour, not to a blank list.
      expect(backend, contains("breakdown['addons']"));
      expect(backend, contains("first['level_3']"));
    });

    test('the fallback runs only when nothing was returned', () {
      final guard = backend.indexOf('if (serviceName.isEmpty)');
      final addons = backend.indexOf("breakdown['addons']");
      expect(guard, greaterThan(-1));
      expect(addons, greaterThan(guard));
    });
  });

  group('_firstNonEmpty', () {
    test('does not accept an empty string as a value', () {
      // A LEFT JOIN produces nulls and a text column can hold '', so a plain
      // `??` chain would stop at the empty string and report success.
      expect(backend, contains('value.isNotEmpty'));
      expect(backend, contains(".toString().trim()"));
    });
  });
}
