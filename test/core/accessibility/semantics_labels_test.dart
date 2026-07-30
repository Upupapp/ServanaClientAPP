import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/accessibility/semantics_labels.dart';

void main() {
  group('SemanticsLabels', () {
    group('constants', () {
      test('back label is non-empty', () {
        expect(SemanticsLabels.back, isNotEmpty);
      });

      test('auth constants are non-empty', () {
        expect(SemanticsLabels.showPassword, isNotEmpty);
        expect(SemanticsLabels.hidePassword, isNotEmpty);
        expect(SemanticsLabels.forgotPassword, isNotEmpty);
        expect(SemanticsLabels.createAccount, isNotEmpty);
      });

      test('navigation constants are distinct', () {
        final navLabels = [
          SemanticsLabels.tabHome,
          SemanticsLabels.tabBookings,
          SemanticsLabels.tabMessages,
          SemanticsLabels.tabProfile,
        ];
        expect(navLabels.toSet().length, equals(navLabels.length));
      });
    });

    group('tabMessagesWithUnread', () {
      test('includes unread count', () {
        final label = SemanticsLabels.tabMessagesWithUnread(5);
        expect(label, contains('5'));
        expect(label.toLowerCase(), contains('messages'));
      });

      test('singular count is grammatical', () {
        final label = SemanticsLabels.tabMessagesWithUnread(1);
        expect(label, contains('1'));
      });
    });

    group('ratingLabel', () {
      test('includes rating, max, and meaning', () {
        final label = SemanticsLabels.ratingLabel(4, 5, 'Very good');
        expect(label, contains('4'));
        expect(label, contains('5'));
        expect(label, contains('Very good'));
      });
    });

    group('ratingMeaning', () {
      test('returns correct strings for 1-5', () {
        expect(SemanticsLabels.ratingMeaning(1), equals(SemanticsLabels.ratingMeaningPoor));
        expect(SemanticsLabels.ratingMeaning(2), equals(SemanticsLabels.ratingMeaningFair));
        expect(SemanticsLabels.ratingMeaning(3), equals(SemanticsLabels.ratingMeaningGood));
        expect(SemanticsLabels.ratingMeaning(4), equals(SemanticsLabels.ratingMeaningVeryGood));
        expect(SemanticsLabels.ratingMeaning(5), equals(SemanticsLabels.ratingMeaningExcellent));
      });

      test('returns empty for out-of-range', () {
        expect(SemanticsLabels.ratingMeaning(0), isEmpty);
        expect(SemanticsLabels.ratingMeaning(6), isEmpty);
      });
    });

    group('ratingHint', () {
      test('when no rating selected, guides user to tap', () {
        expect(SemanticsLabels.ratingHint(0).toLowerCase(), contains('tap'));
      });

      test('when rating exists, guides to change', () {
        expect(SemanticsLabels.ratingHint(3).toLowerCase(), contains('double'));
      });
    });

    group('trackingStatus', () {
      test('without eta returns status only', () {
        final label = SemanticsLabels.trackingStatus('En route', null);
        expect(label, equals('En route'));
      });

      test('with eta appends eta text', () {
        final label = SemanticsLabels.trackingStatus('En route', '5 min');
        expect(label, contains('En route'));
        expect(label, contains('5 min'));
      });
    });

    group('bookingStep', () {
      test('formats step and total', () {
        final label = SemanticsLabels.bookingStep(2, 4);
        expect(label, contains('2'));
        expect(label, contains('4'));
      });
    });

    group('addressCardLabel', () {
      test('includes address info', () {
        final label = SemanticsLabels.addressCardLabel(
          'Home',
          '123 Main St',
          true,
          true,
        );
        expect(label, contains('Home'));
        expect(label, contains('123 Main St'));
        expect(label.toLowerCase(), contains('primary'));
        expect(label.toLowerCase(), contains('serviceable'));
      });

      test('not serviceable is communicated', () {
        final label = SemanticsLabels.addressCardLabel(
          'Work',
          '456 Other St',
          false,
          false,
        );
        expect(label.toLowerCase(), contains('not serviceable'));
      });
    });

    group('newMessagesAvailable', () {
      test('singular', () {
        expect(SemanticsLabels.newMessagesAvailable(1), contains('1'));
        expect(SemanticsLabels.newMessagesAvailable(1), isNot(contains('messages')));
      });

      test('plural', () {
        final label = SemanticsLabels.newMessagesAvailable(3);
        expect(label, contains('3'));
      });
    });

    group('searchResultsCount', () {
      test('singular', () {
        final label = SemanticsLabels.searchResultsCount(1);
        expect(label, contains('1'));
        expect(label, isNot(contains('services ')));
      });

      test('plural', () {
        final label = SemanticsLabels.searchResultsCount(0);
        expect(label, contains('0'));
      });
    });
  });
}
