/// Renders whole screens at real device sizes and text scales.
///
/// ## Why this file exists
///
/// The two files whose names suggested this coverage did not provide it.
/// `responsive_test.dart` tests `ServanaBreakpoints`, `otpCellWidth`,
/// `chatBubbleMaxWidth`, `horizontalPadding` and `minTouchTarget` — arithmetic
/// on numbers, no widget. `core/accessibility/accessibility_tokens_test.dart`
/// asserts token constants and `MediaQuery` plumbing, also no widget. The only
/// rendered-overflow test in the repo was for one search card.
///
/// So sixty screens shipped to real customers without any of them ever being
/// built at a phone-sized viewport, and `RewardsScreen` was clipping 411px of
/// its own explanation at the text scale this app declares it supports.
///
/// ## Why an overflow matters more in release than it looks in debug
///
/// In debug an overflow paints the yellow-and-black hatching and throws, which
/// is loud. In a **release** build it does neither: the content is silently
/// clipped. Nobody gets an error report; the customer just sees less text than
/// was written. That is why this runs at 2.0 rather than stopping at the
/// comfortable sizes.
///
/// ## Two traps, both paid for already
///
///  1. **Pass the screen bare.** These widgets bring their own `Scaffold`.
///     Wrapping one in a `SingleChildScrollView` here yields "given an
///     infinite size during layout", which reads as a product bug and is the
///     harness's fault.
///  2. **Set `tester.view.physicalSize`.** Flutter's default test surface is
///     800x600 — a small tablet in landscape, not a phone. A layout that
///     overflows every real handset passes at the default.
///
/// ## Scope, stated rather than implied
///
/// `test/support/screen_test_container.dart` registers the dependencies these
/// screens resolve, so this is no longer limited to the four that construct
/// without the locator. The container holds REAL controllers over a
/// `MockClient` that answers an empty envelope — a hand-written fake would
/// agree with the screen by construction, and a real controller over a dead
/// network produces the empty states a real screen actually meets.
///
/// Still NOT covered, and named rather than quietly omitted:
///
///  - **Home and the booking flows** — a live MobX store graph.
///  - **The permissions screen** — reaches Firebase Messaging directly.
///  - **`BookingsScreen`, `MessagesInboxScreen`, `BookingCalendarScreen`** —
///    all three resolve `HomeStore`, which is the same MobX graph. They are
///    the shell's own tabs, so covering them means standing that graph up;
///    worth doing, and not free.
///  - **`NotificationsScreen`** — needs the notifications repository graph
///    (`remote`, `local`, `canonical`, `router`), four dependencies deep.
///  - **`ProfileScreen`** — its dependencies ARE registered here now and it
///    builds, but rendering it raises **four exceptions** the harness cannot
///    yet attribute. That is an open question, not a clean skip: it may be
///    image loading over the mock client, and it may not. It is named here
///    rather than dropped so the next person starts from the finding.
///
/// A GoRouter ancestor IS now supplied, so that limitation is gone.
///
/// A screen whose dependency is missing fails with GetIt's own message naming
/// the type, which says exactly what to add to the container.
library;

import 'package:client/common/presentation/screens/drawer_placeholder_screens.dart';
import 'package:client/modules/review/presentation/screens/review_form_screen.dart';
import 'package:client/modules/settings/presentation/screens/about_screen.dart';
import 'package:client/modules/settings/presentation/screens/appearance_screen.dart';
import 'package:client/modules/settings/presentation/screens/privacy_legal_screen.dart';
import 'package:client/modules/settings/presentation/screens/security_screen.dart';
import 'package:client/modules/support/presentation/screens/help_center_screen.dart';
import 'package:client/modules/support/presentation/screens/safety_support_screen.dart';
import 'package:client/modules/support/presentation/screens/support_home_screen.dart';
import 'package:client/modules/support/presentation/screens/support_tickets_screen.dart';
import 'package:client/modules/catalog/presentation/screens/catalog_unavailable_screen.dart';
import 'package:client/modules/support/presentation/screens/create_support_ticket_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/screen_test_container.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/profile/presentation/screens/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client/modules/bookings/presentation/screens/booking_calendar_screen.dart';
import 'package:client/modules/bookings/presentation/screens/bookings_screen.dart';

/// Real handsets, smallest first. 320x568 is an iPhone SE 1st gen — still the
/// floor Play and the App Store will serve.
const Map<String, Size> _viewports = <String, Size>{
  '320x568': Size(320, 568),
  '360x640': Size(360, 640),
  '390x844': Size(390, 844),
};

/// 1.0 is the default, 1.3 is `AccessibilityTokens.largeTextThreshold`, and
/// 2.0 is `AccessibilityTokens.maxRequiredTextScale` — the ceiling this app
/// promises to support. All three are asserted, because a screen that survives
/// 1.3 and dies at 2.0 is a screen that fails exactly the users who need it.
const List<double> _scales = <double>[1.0, 1.3, 2.0];

/// Every screen here builds against the container in `setUp`.
final Map<String, Widget Function()> _screens = <String, Widget Function()>{
  'AboutScreen': () => const AboutScreen(),
  'SecurityScreen': () => const SecurityScreen(),
  'RewardsScreen': () => const RewardsScreen(),
  'FavouritesScreen': () => const FavouritesScreen(),
  'AppearanceScreen': () => const AppearanceScreen(),
  'PrivacyLegalScreen': () => const PrivacyLegalScreen(),
  'SupportHomeScreen': () => const SupportHomeScreen(),
  'SupportTicketsScreen': () => const SupportTicketsScreen(),
  'HelpCenterScreen': () => const HelpCenterScreen(),
  'SafetySupportScreen': () => const SafetySupportScreen(),
  'ReviewFormScreen': () => const ReviewFormScreen(bookingId: '42'),
  // Added by the full sweep. These four ship in the drawer and had never
  // been built at a phone viewport.
  'SettingsScreen': () => const SettingsScreen(),
  'LanguageScreen': () => const LanguageScreen(),
  'SavedAddressesScreen': () => const SavedAddressesScreen(),
  'HelpSupportScreen': () => const HelpSupportScreen(),
  // Core customer screens, reachable now that the harness supplies a
  // GoRouter ancestor. Every one of these ships and none had ever been
  // built at a phone viewport.
  'CatalogUnavailableScreen': () => const CatalogUnavailableScreen(),
  'CreateSupportTicketScreen': () => const CreateSupportTicketScreen(),
  'ProfileScreen': () => const ProfileScreen(),
  'BookingsScreen': () => const BookingsScreen(),
  'BookingCalendarScreen': () => const BookingCalendarScreen(),
};

void main() {
  setUp(registerScreenDependencies);
  tearDown(resetScreenDependencies);

  group('screens lay out without overflow at every supported viewport', () {
    for (final screen in _screens.entries) {
      for (final viewport in _viewports.entries) {
        for (final scale in _scales) {
          testWidgets(
            '${screen.key} at ${viewport.key}, text scale $scale',
            (tester) async {
              tester.view.physicalSize = viewport.value;
              tester.view.devicePixelRatio = 1.0;
              addTearDown(tester.view.reset);

              await tester.pumpWidget(
                MediaQuery(
                  data: MediaQueryData(
                    size: viewport.value,
                    textScaler: TextScaler.linear(scale),
                  ),
                  // A GoRouter ancestor, so screens that call GoRouter.of()
                  // can build at all. Without it they throw 'No GoRouter
                  // found in context', which the matrix used to report as an
                  // overflow. The screen is still passed BARE — it supplies
                  // its own Scaffold.
                  child: BlocProvider<AuthenticationBloc>(
                    create: (_) => buildTestAuthenticationBloc(),
                    child: MaterialApp.router(
                      routerConfig: GoRouter(
                        routes: [
                          GoRoute(
                            path: '/',
                            builder: (_, __) => screen.value(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              await tester.pump(const Duration(milliseconds: 350));

              final overflow = tester.takeException();

              // Tear the tree down and let any armed timer fire before the
              // binding checks for pending ones. `ServanaApiClient` wraps every
              // request in a 30s timeout, so a screen that loads on build arms
              // one — that is the harness meeting a real client, not a leak,
              // and pumping past it is how the two are told apart. A timer
              // still pending after this WOULD be a leak, and the binding
              // still says so.
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump(const Duration(seconds: 31));

              // Name what actually happened. `takeException()` catches ANY
              // exception, and this used to report every one of them as an
              // overflow — so a missing DI registration read as "overflowed at
              // 390x844 ... silent clipping" and sent the reader hunting a
              // layout bug that did not exist. A harness that misattributes a
              // cause is the same defect this app has been fixing all week.
              expect(
                overflow,
                isNull,
                reason: '${screen.key} threw at ${viewport.key}, text scale '
                    '$scale -- ${overflow.runtimeType}: $overflow . '
                    'If that is a RenderFlex overflow, a release build clips '
                    'it SILENTLY — the content simply disappears. If it is '
                    'anything else, it is the harness missing a dependency '
                    'rather than a layout defect.',
              );
            },
          );
        }
      }
    }
  });

  group('the matrix itself', () {
    test('covers every screen at every viewport and every scale', () {
      // Guards against a screen being added to `_screens` while a viewport or
      // a scale is quietly dropped to make it pass.
      expect(_viewports, hasLength(3));
      expect(_scales, containsAll(<double>[1.0, 1.3, 2.0]));
      expect(
        _screens.length,
        greaterThanOrEqualTo(11),
        reason: 'screens should only ever be added to this matrix',
      );
    });

    test('includes the smallest handset the stores still serve', () {
      // 320dp is where the Rewards clipping was worst — 411px over. Dropping
      // this viewport would make the matrix green and the defect invisible.
      expect(_viewports.values.map((s) => s.width), contains(320.0));
    });
  });
}
