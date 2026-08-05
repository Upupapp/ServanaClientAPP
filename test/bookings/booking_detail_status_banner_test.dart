/// The booking detail screen must not tell a customer their booking is fine
/// when it does not know that.
///
/// Reported from production against 1.0.0+36: booking SVN-000104 showed a green
/// tick reading "Confirmed — Your booking has been confirmed." directly above a
/// card reading "Pending / Awaiting technician", with the Service and Brand rows
/// rendered as bare labels with nothing beside them.
///
/// Neither half was a rendering glitch. `_StatusBanner` decided what to say from
/// `paymentStatus` and whether the scheduled time was still in the future, and
/// never read the booking's status at all — so a cash booking that had not been
/// assigned yet (not paid, nothing to pay, schedule already passed) fell through
/// every branch to a final `else` hardcoded to green "Confirmed". And `_InfoRow`
/// rendered an empty value as a zero-width `Text`, so a row whose data was
/// missing collapsed to its label.
///
/// These are source-level assertions. The widgets are private to the screen and
/// the screen needs a live `ServanaApiClient` from `dpLocator` to build, so
/// pumping it here would test a mock of the bug rather than the bug. What can be
/// pinned without that is the decision logic itself.
library;

import 'dart:io';

import 'package:client/common/domain/booking/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comments are stripped before every assertion below.
///
/// The fix carries a comment block that quotes the old broken behaviour —
/// "Your booking has been confirmed.", "Confirmed" — because naming the defect
/// is the point of the comment. A raw substring check matches that prose and
/// reports a bug that is not there, which is exactly how an earlier version of
/// this suite "failed" against correct code.
String _code(String path) => File(path)
    .readAsLinesSync()
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  late final String screen;

  setUpAll(() {
    screen = _code(
        'lib/modules/bookings/presentation/screens/booking_detail_screen.dart');
  });

  group('the banner reads the booking status', () {
    test('_StatusBanner is given the status', () {
      // Without this the widget cannot consult the status no matter what its
      // build method does.
      expect(screen, contains('required this.status'));
      expect(screen, contains('status: _bookingStatus'));
    });

    test('it resolves the status through the shared mapper', () {
      // 22 states with agreed customer-facing copy already exist. A second
      // vocabulary invented inside one screen is how the two halves of this
      // screen came to disagree in the first place.
      expect(screen, contains('BookingStatusMapper.fromString(status)'));
      expect(screen, contains('BookingStatusMapper.customerLabel(s)'));
      expect(screen, contains('BookingStatusMapper.heroSubtitle(s)'));
    });

    test('no branch hardcodes a reassuring fallback', () {
      // The specific regression: an unrecognised state must never resolve to
      // "Confirmed". Asserted against code with comments stripped.
      expect(screen, isNot(contains("text = 'Confirmed';")),
          reason: 'a literal Confirmed branch is how the false green banner '
              'was produced');
      expect(screen,
          isNot(contains("subtitle = 'Your booking has been confirmed.';")));
    });

    test('an unknown status says so instead of guessing', () {
      expect(screen, contains('BookingStatus.unknown'));
      expect(screen, contains("text = 'Status Unavailable';"));
    });
  });

  group('the mapper backs that up', () {
    // If these ever change, the banner's behaviour changes with them, so they
    // are pinned here rather than assumed.

    test('an unrecognised wire status maps to unknown, not to confirmed', () {
      for (final raw in <String?>[
        null,
        '',
        'PENDING',
        'SOMETHING_NEW',
        'WORKER_ASSIGNED_V2',
      ]) {
        final s = BookingStatusMapper.fromString(raw);
        expect(s, isNot(BookingStatus.confirmed),
            reason: '"$raw" must not be read as confirmed');
      }
    });

    test('unknown is not grouped as upcoming or completed', () {
      // Its group drives the banner colour. Anything cheerful here would put
      // the green tick back by another route.
      final group = BookingStatusMapper.groupCategory(BookingStatus.unknown);
      expect(group, isNot('completed'));
      expect(group, isNot('upcoming'));
    });

    test('genuinely confirmed still reads as confirmed', () {
      // Guard against over-correcting: the fix must not make the happy path
      // vague.
      expect(BookingStatusMapper.customerLabel(BookingStatus.confirmed),
          'Confirmed');
      expect(BookingStatusMapper.customerLabel(BookingStatus.completed),
          'Completed');
    });
  });

  group('missing values are visible as missing', () {
    test('_InfoRow substitutes a dash for an empty value', () {
      expect(screen, contains("static const String _absent = '—';"));
      expect(screen, contains("value.trim().isEmpty ? _absent : value"));
    });

    test('both layouts render the substituted value, not the raw one', () {
      // _InfoRow has two branches — a stacked one for narrow screens and a
      // row for wide. The production screenshot was the stacked branch, and
      // patching only the other one would have left the reported bug in place
      // on exactly the devices that reported it.
      expect(screen, contains('Text(display, style: valueStyle)'));
      expect(screen, isNot(contains('Text(value, style: valueStyle)')));
    });
  });

  group('the service name has somewhere to come from', () {
    test('the screen reads the fields the backend now sends', () {
      // getBookingById joined payments, branches, addresses and workers but
      // never the service, so serviceName was absent from the response and this
      // chain resolved to ''. Both halves had to change; this pins the client
      // half.
      expect(screen, contains("b['serviceOptionName']"));
      expect(screen, contains("b['serviceName']"));
      expect(screen, contains("b['branchName']"));
    });
  });
}
