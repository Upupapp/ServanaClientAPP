/// Regression tests for the MainRouter auth guard redirect logic.
///
/// The guard was previously broken by a case-mismatch: it checked
/// `/settings` (lowercase) while SettingsScreen.route is `/Settings`.
/// These tests lock in the exact route strings and protection rules so
/// any future rename is immediately caught.
library;

import 'package:client/common/presentation/screens/drawer_placeholder_screens.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/modules/bookings/presentation/screens/booking_calendar_screen.dart';
import 'package:client/modules/bookings/presentation/screens/bookings_screen.dart';
import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
import 'package:client/modules/messaging/presentation/screens/messages_inbox_screen.dart';
import 'package:client/modules/profile/presentation/screens/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the `isProtected` logic in MainRouter.router() exactly.
/// Update this if the guard changes — that forces you to also update the test.
bool _isProtected(String loc) =>
    loc.startsWith(SettingsScreen.route) || // '/Settings'
    loc.startsWith(BookingsScreen.route) || // '/Bookings'
    loc.startsWith('/bookings') || // '/bookings/:id' detail routes
    loc.startsWith('/booking/') || // legacy singular alias
    loc.startsWith(MessagesInboxScreen.route) ||
    loc.startsWith(ProfileScreen.route) ||
    loc.startsWith('/support') ||
    loc.startsWith('/review/') ||
    loc.startsWith('/BookingChat') ||
    loc.startsWith('/SavedAddresses') ||
    loc.startsWith('/Rewards') ||
    loc.startsWith('/Favourites') ||
    loc.startsWith(NotificationsScreen.route) || // '/Notifications'
    loc.startsWith(BookingCalendarScreen.route) || // '/Calendar'
    loc.startsWith('/JobOrderSummaryScreen') ||
    loc.startsWith(LanguageScreen.route); // '/Language'

void main() {
  // ── AuthStateService ──────────────────────────────────────────────────────

  group('AuthStateService.isAuthenticated', () {
    test('is false for unknown', () {
      final s = AuthStateService();
      expect(s.isAuthenticated, isFalse);
    });

    test('is false for guest', () {
      final s = AuthStateService();
      s.update(AuthStatus.guest);
      expect(s.isAuthenticated, isFalse);
    });

    test('is false for expired', () {
      final s = AuthStateService();
      s.update(AuthStatus.expired);
      expect(s.isAuthenticated, isFalse);
    });

    test('is true only for authenticated', () {
      final s = AuthStateService();
      s.update(AuthStatus.authenticated);
      expect(s.isAuthenticated, isTrue);
    });

    test('update() notifies listeners on status change', () {
      final s = AuthStateService();
      var count = 0;
      s.addListener(() => count++);
      s.update(AuthStatus.authenticated);
      expect(count, 1);
    });

    test('update() is a no-op when status unchanged', () {
      final s = AuthStateService();
      s.update(AuthStatus.guest);
      var count = 0;
      s.addListener(() => count++);
      s.update(AuthStatus.guest);
      expect(count, 0);
    });
  });

  // ── Route constants — case regression ─────────────────────────────────────
  //
  // The guard was previously broken because SettingsScreen.route is '/Settings'
  // (capital S) but the check used '/settings' (lowercase). Pin both values:

  group('Route constants — case sensitivity', () {
    test('SettingsScreen.route starts with capital S', () {
      expect(SettingsScreen.route, startsWith('/S'));
    });

    test('SettingsScreen.route is exactly /Settings', () {
      expect(SettingsScreen.route, '/Settings');
    });

    test('LanguageScreen.route is exactly /Language', () {
      expect(LanguageScreen.route, '/Language');
    });

    test('NotificationsScreen.route starts with /N', () {
      expect(NotificationsScreen.route, startsWith('/N'));
    });

    test('BookingsScreen.route starts with /B', () {
      expect(BookingsScreen.route, startsWith('/B'));
    });

    test('BookingCalendarScreen.route is exactly /Calendar', () {
      expect(BookingCalendarScreen.route, '/Calendar');
    });
  });

  // ── Auth guard: protected routes ──────────────────────────────────────────

  group('Auth guard — protected routes require authentication', () {
    test('/Settings is protected', () {
      expect(_isProtected('/Settings'), isTrue);
    });

    test('/Settings/appearance is protected (subpath)', () {
      expect(_isProtected('/Settings/appearance'), isTrue);
    });

    test('/Language is protected', () {
      expect(_isProtected('/Language'), isTrue);
    });

    test('/Bookings is protected', () {
      expect(_isProtected('/Bookings'), isTrue);
    });

    test('/bookings/123 is protected (detail)', () {
      expect(_isProtected('/bookings/123'), isTrue);
    });

    test('/booking/456 is protected (legacy alias)', () {
      expect(_isProtected('/booking/456'), isTrue);
    });

    test('/Notifications is protected', () {
      expect(_isProtected('/Notifications'), isTrue);
    });

    test('/Calendar is protected', () {
      expect(_isProtected('/Calendar'), isTrue);
    });

    test('/support is protected', () {
      expect(_isProtected('/support'), isTrue);
    });

    test('/review/ is protected', () {
      expect(_isProtected('/review/new'), isTrue);
    });

    test('/BookingChat is protected', () {
      expect(_isProtected('/BookingChat/42'), isTrue);
    });

    test('/SavedAddresses is protected', () {
      expect(_isProtected('/SavedAddresses'), isTrue);
    });

    test('/Rewards is protected', () {
      expect(_isProtected('/Rewards'), isTrue);
    });

    test('/Favourites is protected', () {
      expect(_isProtected('/Favourites'), isTrue);
    });

    test('/JobOrderSummaryScreen is protected', () {
      expect(_isProtected('/JobOrderSummaryScreen/7'), isTrue);
    });

    test('${HomeScreen.route} is NOT protected', () {
      expect(_isProtected(HomeScreen.route), isFalse);
    });
  });

  // ── Auth guard: public routes ─────────────────────────────────────────────

  group('Auth guard — public routes are accessible without auth', () {
    test('/ (splash) is public', () {
      expect(_isProtected('/'), isFalse);
    });

    test('/welcome is public', () {
      expect(_isProtected('/welcome'), isFalse);
    });

    test('/auth is public', () {
      expect(_isProtected('/auth'), isFalse);
    });

    test('/create-account is public', () {
      expect(_isProtected('/create-account'), isFalse);
    });

    // Case-mismatch regression: '/settings' (lowercase) must NOT be treated
    // as the same as '/Settings' (capital S). If route constants change to
    // lowercase, the _isProtected function must be updated too.
    test('/settings (lowercase) is NOT protected by /Settings guard', () {
      expect(_isProtected('/settings'), isFalse);
    });
  });
}
