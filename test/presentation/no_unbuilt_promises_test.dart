/// An MVP is judged by what a customer can finish.
///
/// A control that is visible and cannot complete costs more trust than a
/// feature that is simply absent: the customer cannot tell the difference
/// between "not built" and "broken", so they assume broken. Worse, "coming
/// soon" is a promise, and two of the three places this app made it were not
/// scheduled by anyone.
///
///  - **Mobile-number login.** Not a rename away. The canonical endpoint takes
///    a Firebase phone credential, not a number and an OTP, so it is a
///    redesign. The screen now states what to do instead of promising.
///  - **Rewards and Favourites.** Both screens are placeholders whose whole
///    body is the words "coming soon". The drawer no longer offers them. The
///    screens and routes stay for the release that builds them.
///
/// Comment lines are stripped before matching, because the code that removed
/// each affordance carries an explanation naming it.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _code(String p) => File(p)
    .readAsLinesSync()
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

const _authScreen =
    'lib/modules/authentication/presentation/screens/authentication_screen.dart';
const _homeScreen =
    'lib/modules/homepage/presentation/screens/home_screen.dart';

void main() {
  group('the sign-in screen promises nothing it cannot do', () {
    test('it does not say anything is coming soon', () {
      expect(
        _code(_authScreen).toLowerCase(),
        isNot(contains('coming soon')),
        reason: 'the front door must not advertise an unscheduled feature',
      );
    });

    test('a mobile number is answered with what to do instead', () {
      final code = _code(_authScreen);
      expect(code, contains('Sign in with your email address.'));
      // The guard itself must stay. Without it a customer who types their
      // phone number is told their credentials are wrong, which is the same
      // class of lie this sweep removed from the failure mapper.
      expect(code, contains('_isMobileInput'));
    });
  });

  group('the drawer offers no placeholder destination', () {
    test('Rewards is not reachable from the drawer', () {
      expect(_code(_homeScreen), isNot(contains('RewardsScreen.routeName')));
    });

    test('Favourites is not reachable from the drawer', () {
      expect(_code(_homeScreen), isNot(contains('FavouritesScreen.routeName')));
    });

    test('the destinations that remain are real screens', () {
      // A positive control: if this file stopped finding the drawer at all,
      // the two assertions above would pass for the wrong reason.
      final code = _code(_homeScreen);
      expect(code, contains('BookingsScreen.routeName'));
      expect(code, contains('SettingsScreen'));
    });
  });
}
