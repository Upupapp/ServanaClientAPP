import 'package:client/common/presentation/shell/core_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoreTab', () {
    test('values are in branch order', () {
      expect(CoreTab.home.index, 0);
      expect(CoreTab.bookings.index, 1);
      expect(CoreTab.messages.index, 2);
      expect(CoreTab.profile.index, 3);
    });

    test('only Home allows guests', () {
      expect(CoreTab.home.allowsGuest, isTrue);
      expect(CoreTab.bookings.allowsGuest, isFalse);
      expect(CoreTab.messages.allowsGuest, isFalse);
      expect(CoreTab.profile.allowsGuest, isFalse);
    });

    test('labels are non-empty and correct', () {
      expect(CoreTab.home.label, 'Home');
      expect(CoreTab.bookings.label, 'Bookings');
      expect(CoreTab.messages.label, 'Messages');
      expect(CoreTab.profile.label, 'Profile');
    });

    test('icons are distinct across active and inactive states', () {
      for (final tab in CoreTab.values) {
        expect(tab.icon, isNotNull);
        expect(tab.activeIcon, isNotNull);
        // Active icon should differ from inactive for visual distinction.
        expect(tab.activeIcon, isNot(equals(tab.icon)));
      }
    });

    test('semanticLabel without badge matches label', () {
      for (final tab in CoreTab.values) {
        expect(tab.semanticLabel(), tab.label);
      }
    });

    test('semanticLabel with badge includes count', () {
      expect(CoreTab.bookings.semanticLabel(badge: 3), contains('3'));
      expect(CoreTab.bookings.semanticLabel(badge: 3), contains('Bookings'));
    });

    test('all values have entries — no switch falls through', () {
      // If a new value was added without updating helpers, this throws.
      for (final tab in CoreTab.values) {
        expect(tab.label, isNotEmpty);
        expect(() => tab.icon, returnsNormally);
        expect(() => tab.activeIcon, returnsNormally);
        expect(() => tab.semanticLabel(), returnsNormally);
        expect(() => tab.allowsGuest, returnsNormally);
      }
    });
  });
}
