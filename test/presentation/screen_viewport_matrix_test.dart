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
///  - **`MerchantMenuScreen`, `StoreItemsScreen`** — both build under a
///    `StoreItemsBloc` provider this harness does not supply yet.
///  - **`ItemOptionMenuScreen`** — ⚠ REAL overflow remaining at text scale
///    2.0 only. Its 1.3 failure WAS fixed: `menu_item_widget.dart` pinned a
///    fixed `height: 120` around text that scales, and that widget is used
///    by three screens.
///  - **`ItemOptionMenuScreen`** — ⚠ a REAL 112px bottom overflow remains at
///    text scale 2.0 ONLY; 1.0 and 1.3 are clean. Two attempts did not land
///    it, and it resists the usual probe because the screen also raises an
///    ASYNC error, which kills a harness that overrides FlutterError.onError
///    (the binding then asserts on `_pendingExceptionDetails`). Whoever
///    picks this up should read the widget location from an unswallowed
///    run rather than reuse the probe pattern in this file's history.
///    `menu_item_widget.dart` WAS fixed on the way: its 120px box now
///    scales with the text and is capped at 180, because it holds an
///    AspectRatio(1) image that would otherwise be a 240px square on a
///    320px handset.
///  - **`SplashScreen`** — reads the session through flutter_secure_storage,
///    whose platform channel never completes under the test binding. It
///    logs `session unreadable, treating as signed out` after a 4s timeout
///    and carries on, which is the right behaviour and still not a screen
///    this harness can render.
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
import 'package:client/modules/homepage/presentation/screens/search_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_options_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_addons_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_branch_slot_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_checkout_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_confirmation_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_options_screen.dart';
import 'package:client/modules/job_order/presentation/screens/select_payment_method_screen.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/landing/presentation/screens/welcome_screen.dart';
import 'package:client/modules/merchant_menu/presentation/screens/merchant_menu_screen.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/screens/store_items_screen.dart';
import 'package:client/modules/catalog/application/catalog_controller.dart';
import 'package:client/modules/catalog/application/service_detail_controller.dart';
import 'package:client/modules/catalog/presentation/screens/catalog_browse_screen.dart';
import 'package:client/modules/catalog/presentation/screens/category_screen.dart';
import 'package:client/modules/catalog/presentation/screens/service_detail_screen.dart';
import 'package:client/modules/catalog/presentation/screens/subcategory_screen.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/modules/authentication/presentation/screens/authentication_screen.dart';
import 'package:client/modules/profile/presentation/screens/email_verification_screen.dart';
import 'package:client/modules/registration/presentation/bloc/registration_bloc.dart';
import 'package:client/modules/registration/presentation/screens/create_account_screen.dart';
import 'package:client/common/presentation/screens/address_form_screen.dart';
import 'package:client/modules/job_order/presentation/screens/add_additional_item_menu_screen.dart';
import 'package:client/modules/review/presentation/screens/review_detail_screen.dart';
import 'package:client/modules/registration/presentation/screens/account_pending_for_approval.dart';
import 'package:client/modules/job_order/presentation/screens/job_order_summary_screen.dart';
import 'package:client/common/presentation/screens/authentication_gate_screen.dart';
import 'package:client/modules/settings/presentation/screens/permissions_screen.dart';
import 'package:client/modules/settings/presentation/screens/profile_edit_screen.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/modules/messaging/presentation/screens/booking_chat_screen.dart';
import 'package:client/modules/messaging/presentation/screens/messages_inbox_screen.dart';
import 'package:client/common/presentation/screens/booking_otp_screen.dart';
import 'package:client/modules/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
import 'package:client/modules/support/presentation/screens/support_ticket_detail_screen.dart';
import 'package:client/modules/tracking/presentation/screens/live_tracking_screen.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_bloc.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/modules/job_order/presentation/screens/job_order_screen.dart';
import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/presentation/screens/payment_webview_screen.dart';
import 'package:client/modules/categories/presentation/screens/category_experience_screen.dart';

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
  'SearchScreen': () => const SearchScreen(),
  // The booking flow, end to end.
  'SelectPaymentMethodScreen': () => const SelectPaymentMethodScreen(),
  'AirconOptionsScreen': () => const AirconOptionsScreen(),
  'AirconCheckoutScreen': () => const AirconCheckoutScreen(),
  'AirconConfirmationScreen': () => const AirconConfirmationScreen(),
  'BwOptionsScreen': () => const BwOptionsScreen(serviceId: 1),
  'BwAddOnsScreen': () => const BwAddOnsScreen(),
  'BwBranchSlotScreen': () => const BwBranchSlotScreen(),
  'BwCheckoutScreen': () => const BwCheckoutScreen(),
  'BwConfirmationScreen': () => const BwConfirmationScreen(),
  'WelcomeScreen': () => const WelcomeScreen(),
  'MerchantMenuScreen': () => const MerchantMenuScreen(),
  'StoreItemsScreen': () =>
      const StoreItemsScreen(merchantId: '1', merchantName: 'Test Merchant'),
  // Catalog. These take their controller and callbacks as constructor
  // arguments rather than resolving them, so they need no extra DI.
  'CatalogBrowseScreen': () => CatalogBrowseScreen(
        controller: dpLocator<CatalogController>(),
        onCategorySelected: (_) {},
      ),
  'CategoryScreen': () => CategoryScreen(
        controller: dpLocator<CatalogController>(),
        categoryId: 1,
        onSubcategorySelected: (_) {},
      ),
  'SubcategoryScreen': () => SubcategoryScreen(
        controller: dpLocator<CatalogController>(),
        subcategoryId: 1,
        onServiceSelected: (_) {},
      ),
  'ServiceDetailScreen': () => ServiceDetailScreen(
        controller: dpLocator<ServiceDetailController>(),
        serviceId: 1,
        onStartBooking: (_, __) {},
      ),
  // The entry funnel.
  'AuthenticationScreen': () => const AuthenticationScreen(),
  'CreateAccountScreen': () => const CreateAccountScreen(),
  'EmailVerificationScreen': () => const EmailVerificationScreen(),
  // Stragglers with cheap or no dependencies.
  'AddressFormScreen': () => const AddressFormScreen(),
  'AuthenticationGateScreen': () => const AuthenticationGateScreen(),
  'ProfileEditScreen': () => const ProfileEditScreen(),
  'MessagesInboxScreen': () => const MessagesInboxScreen(),
  'NotificationsScreen': () => const NotificationsScreen(),
  'LiveTrackingScreen': () => const LiveTrackingScreen(bookingId: '42'),
  'PaymentWebViewScreen': () => const PaymentWebViewScreen(
        bookingId: 42,
        checkoutUrl: 'https://example.invalid/checkout',
      ),
  'CategoryExperienceScreen': () =>
      const CategoryExperienceScreen(categoryId: ServiceCategoryId.aircon),
  'JobOrderScreen': () => JobOrderScreen(
        service: MerchantServiceModel(),
        merchantId: '1',
        merchantName: 'Test Merchant',
      ),
  'SupportTicketDetailScreen': () =>
      const SupportTicketDetailScreen(ticketKey: 'TKT-1'),
  'HomeScreen': () => const HomeScreen(),
  'BookingDetailScreen': () => const BookingDetailScreen(bookingId: '42'),
  'BookingOtpScreen': () => const BookingOtpScreen(
        bookingId: 42,
        flow: BookingOtpFlow.resume,
      ),
  'BookingChatScreen': () => const BookingChatScreen(jobOrderId: '42'),
  // Empty lists on purpose: this renders the empty state, which is what a
  // customer sees whenever the catalog cannot answer.
  'ServiceCategoryListScreen': () => ServiceCategoryListScreen(
        title: 'Aircon Services',
        filterChips: const [],
        items: const [],
        onCardTap: (_, __) {},
      ),
  'PermissionsScreen': () => const PermissionsScreen(),
  'AccountPendingForApprovalScreen': () =>
      const AccountPendingForApprovalScreen(),
  'AddAdditionalItemMenuScreen': () => const AddAdditionalItemMenuScreen(),
  'JobOrderSummaryScreen': () => const JobOrderSummaryScreen(id: '1'),
  // Asserts at construction that one of bookingId/reviewId is present.
  'ReviewDetailScreen': () => const ReviewDetailScreen(bookingId: '42'),
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
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider<AuthenticationBloc>(
                        create: (_) => buildTestAuthenticationBloc(),
                      ),
                      BlocProvider<JobOrderBloc>(
                        create: (_) => buildTestJobOrderBloc(),
                      ),
                      BlocProvider<StoreItemsBloc>(
                        create: (_) => buildTestStoreItemsBloc(),
                      ),
                      BlocProvider<StoreOptionsBloc>(
                        create: (_) => buildTestStoreOptionsBloc(),
                      ),
                      BlocProvider<RegistrationBloc>(
                        create: (_) => dpLocator<RegistrationBloc>(),
                      ),
                    ],
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
