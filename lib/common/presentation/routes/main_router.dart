import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/domain/auth/auth_return_intent.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/authentication_gate_screen.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:client/modules/authentication/presentation/screens/authentication_screen.dart';
import 'package:client/modules/bookings/presentation/screens/booking_calendar_screen.dart';
import 'package:client/modules/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:client/modules/bookings/presentation/screens/bookings_screen.dart';
import 'package:client/common/presentation/screens/booking_otp_screen.dart';
import 'package:client/common/presentation/screens/drawer_placeholder_screens.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
import 'package:client/modules/homepage/presentation/screens/search_screen.dart';
import 'package:client/modules/job_order/presentation/screens/add_additional_item_menu_screen.dart';
import 'package:client/modules/job_order/presentation/screens/job_order_screen.dart';
import 'package:client/modules/job_order/presentation/screens/job_order_summary_screen.dart';
import 'package:client/modules/job_order/presentation/screens/select_payment_method_screen.dart';
import 'package:client/modules/landing/presentation/screens/splash_screen.dart';
import 'package:client/modules/landing/presentation/screens/welcome_screen.dart';
import 'package:client/modules/messaging/presentation/screens/booking_chat_screen.dart';
import 'package:client/modules/messaging/presentation/screens/messages_inbox_screen.dart';
import 'package:client/modules/merchant_menu/presentation/screens/item_option_menu_screen.dart';
import 'package:client/modules/merchant_menu/presentation/screens/merchant_menu_screen.dart';
import 'package:client/modules/profile/presentation/screens/profile_screen.dart';
import 'package:client/modules/profile/presentation/screens/email_verification_screen.dart';
import 'package:client/common/presentation/widgets/main_nav_scaffold.dart';
import 'package:client/modules/registration/presentation/screens/create_account_screen.dart';
import 'package:client/modules/store_items/presentation/screens/store_items_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_options_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_options_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_addons_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_branch_slot_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_checkout_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_confirmation_screen.dart';
import 'package:client/common/presentation/screens/payment_webview_screen.dart';
import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/presentation/routes/category_routes.dart';
import 'package:client/common/presentation/routes/catalog_routes.dart';
import 'package:client/modules/catalog/application/canonical_booking_handoff.dart';
import 'package:client/modules/catalog/application/catalog_controller.dart';
import 'package:client/modules/catalog/application/service_detail_controller.dart';
import 'package:client/modules/catalog/presentation/screens/catalog_browse_screen.dart';
import 'package:client/modules/catalog/presentation/screens/catalog_unavailable_screen.dart';
import 'package:client/modules/catalog/presentation/screens/category_screen.dart';
import 'package:client/modules/catalog/presentation/screens/service_detail_screen.dart';
import 'package:client/modules/catalog/presentation/screens/subcategory_screen.dart';
import 'package:client/modules/categories/presentation/screens/category_experience_screen.dart';
import 'package:client/modules/settings/presentation/screens/about_screen.dart';
import 'package:client/modules/settings/presentation/screens/appearance_screen.dart';
import 'package:client/modules/settings/presentation/screens/permissions_screen.dart';
import 'package:client/modules/settings/presentation/screens/delete_account_screen.dart';
import 'package:client/modules/settings/presentation/screens/privacy_legal_screen.dart';
import 'package:client/modules/settings/presentation/screens/profile_edit_screen.dart';
import 'package:client/modules/settings/presentation/screens/security_screen.dart';
import 'package:client/modules/review/presentation/screens/review_detail_screen.dart';
import 'package:client/modules/review/presentation/screens/review_form_screen.dart';
import 'package:client/modules/support/presentation/screens/create_support_ticket_screen.dart';
import 'package:client/modules/support/presentation/screens/help_center_screen.dart';
import 'package:client/modules/support/presentation/screens/safety_support_screen.dart';
import 'package:client/modules/support/presentation/screens/support_home_screen.dart';
import 'package:client/modules/support/presentation/screens/support_ticket_detail_screen.dart';
import 'package:client/modules/support/presentation/screens/support_tickets_screen.dart';
import 'package:client/modules/tracking/domain/tracking_args.dart';
import 'package:client/modules/tracking/presentation/screens/live_tracking_screen.dart';
import 'package:go_router/go_router.dart';

class MainRouter {
  /// Route-level cross-fade. Splash uses this to dissolve into welcome/home;
  /// welcome and home use it to dissolve in. When go_router transitions A→B,
  /// A's `secondaryAnimation` and B's `animation` are tied to the same tween,
  /// so the source fades out while the destination fades in.
  ///
  /// 700 ms with `easeInOut` lingers around the 50% mark — both pages share
  /// the screen briefly, which reads as a deliberate dissolve rather than a
  /// quick swap. Same curve on both halves keeps the blend symmetric.
  static ServiceCategoryId? _categoryIdFromKey(String key) => switch (key) {
        'beauty_wellness' => ServiceCategoryId.beautyWellness,
        'hair_nails' => ServiceCategoryId.hairAndNails,
        'massage' => ServiceCategoryId.massage,
        'aircon' => ServiceCategoryId.aircon,
        _ => null,
      };

  /// Reads a canonical `services.id` out of a route extra.
  ///
  /// Returns null when the extra is absent, unparseable, or not a positive id,
  /// so the caller can bounce Home rather than continue with a placeholder.
  ///
  /// This exists because the alternative shipped: the Beauty & Wellness options
  /// route coerced a bad extra with `int.tryParse('$extra') ?? 0` and handed
  /// `serviceId: 0` to the screen, which then fetched options for a Service that
  /// cannot exist. It is reachable — `StoreOptionItems.merchantServiceID` is a
  /// String that DEFAULTS TO "0", so a row the API omits the id for walks
  /// straight into it — and it fails silently, showing an empty options screen
  /// instead of an error.
  ///
  /// Zero is rejected rather than treated as a sentinel: an id is a row that
  /// exists, and every other identity-bearing route in this file already bounces
  /// Home instead of inventing one.
  @visibleForTesting
  static int? asServiceId(Object? extra) {
    final id = switch (extra) {
      final int value => value,
      final String value => int.tryParse(value.trim()),
      _ => null,
    };
    return (id != null && id > 0) ? id : null;
  }

  static CustomTransitionPage<T> _fadePage<T>(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 700),
      reverseTransitionDuration: const Duration(milliseconds: 700),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        final fadeOut = CurvedAnimation(
          parent: ReverseAnimation(secondaryAnimation),
          curve: Curves.easeInOut,
        );
        return FadeTransition(
          opacity: fadeIn,
          child: FadeTransition(opacity: fadeOut, child: child),
        );
      },
    );
  }

  static GoRouter router() {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final authState = dpLocator<AuthStateService>();
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: SplashScreen.route,
      debugLogDiagnostics: kDebugMode,
      // Re-evaluate redirect whenever auth status changes (login/logout/guest).
      refreshListenable: authState,
      redirect: (context, state) {
        // Status unknown = splash is still running its session check.
        // Don't redirect yet — the splash will navigate when ready.
        if (authState.status == AuthStatus.unknown) return null;

        final loc = state.matchedLocation;

        // Protected routes require a signed-in session.
        final isProtected =
            loc.startsWith(SettingsScreen.route) || // '/Settings'
                loc.startsWith(BookingsScreen.route) || // "/Bookings" tab
                loc.startsWith('/bookings') || // "/bookings/:id" detail routes
                loc.startsWith(
                    '/booking/') || // legacy "/booking/:id" singular alias
                loc.startsWith(MessagesInboxScreen.route) ||
                loc.startsWith(ProfileScreen.route) ||
                loc.startsWith('/support') ||
                loc.startsWith('/review/') || // /review/new, /review/detail
                loc.startsWith('/BookingChat') || // /BookingChat/:jobOrderId
                loc.startsWith('/SavedAddresses') ||
                loc.startsWith('/Rewards') ||
                loc.startsWith('/Favourites') ||
                loc.startsWith(NotificationsScreen.route) || // '/Notifications'
                loc.startsWith(BookingCalendarScreen.route) || // '/Calendar'
                loc.startsWith(
                    '/JobOrderSummaryScreen') || // '/JobOrderSummaryScreen/:id'
                loc.startsWith(LanguageScreen.route); // '/Language'

        if (isProtected && !authState.isAuthenticated) {
          // Always land on WelcomeScreen — post-logout and unauthenticated
          // deep-link attempts both need a clean entry point, not the auth
          // gate interstitial (which has no return context here).
          return WelcomeScreen.route;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: SplashScreen.route,
          name: SplashScreen.routeName,
          pageBuilder: (context, state) =>
              _fadePage(state, const SplashScreen()),
        ),
        GoRoute(
            path: WelcomeScreen.route,
            name: WelcomeScreen.routeName,
            pageBuilder: (context, state) =>
                _fadePage(state, const WelcomeScreen()),
            routes: [
              GoRoute(
                path: AuthenticationScreen.route,
                name: AuthenticationScreen.routeName,
                builder: (context, state) => const AuthenticationScreen(),
              ),
            ]),
        GoRoute(
          path: CreateAccountScreen.route,
          name: CreateAccountScreen.routeName,
          builder: (context, state) => const CreateAccountScreen(),
        ),
        GoRoute(
          path: EmailVerificationScreen.route,
          name: EmailVerificationScreen.routeName,
          builder: (context, state) {
            final args = state.extra;
            if (args is! SignupEmailVerificationArgs ||
                args.email.trim().isEmpty) {
              return const WelcomeScreen();
            }
            return EmailVerificationScreen(
              signupEmail: args.email.trim(),
              codeAlreadySent: true,
            );
          },
        ),
        StatefulShellRoute.indexedStack(
          // Page-level fade so splash → home dissolves rather than slides.
          // Tab switches inside the shell are handled by the navigationShell
          // and are unaffected by this transition.
          pageBuilder: (context, state, navigationShell) => _fadePage(
            state,
            MainNavScaffold(navigationShell: navigationShell),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: HomeScreen.route,
                  name: HomeScreen.routeName,
                  builder: (context, state) => const HomeScreen(),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: SearchScreen.route,
                      name: SearchScreen.routeName,
                      builder: (context, state) => const SearchScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: JobOrderScreen.route,
                      name: JobOrderScreen.routeName,
                      builder: (context, state) {
                        final extra = state.extra;
                        if (extra is! MerchantServiceModel) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => context.goNamed(HomeScreen.routeName),
                          );
                          return const Scaffold();
                        }
                        return JobOrderScreen(
                          service: extra,
                          merchantId: state.pathParameters["id"] ?? '',
                          merchantName: state.pathParameters["name"] ?? '',
                        );
                      },
                      routes: [
                        GoRoute(
                          parentNavigatorKey: rootNavigatorKey,
                          path: AddAdditionalItemMenuScreen.route,
                          name: AddAdditionalItemMenuScreen.routeName,
                          builder: (context, state) =>
                              const AddAdditionalItemMenuScreen(),
                        ),
                      ],
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: StoreItemsScreen.route,
                      name: StoreItemsScreen.routeName,
                      builder: (context, state) {
                        final extra = state.extra;
                        if (extra is! ({
                          String merchantId,
                          String merchantName,
                          String? categoryName
                        })) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => context.goNamed(HomeScreen.routeName),
                          );
                          return const Scaffold();
                        }
                        return StoreItemsScreen(
                          merchantId: extra.merchantId,
                          merchantName: extra.merchantName,
                          categoryName: extra.categoryName,
                        );
                      },
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: SelectPaymentMethodScreen.route,
                      name: SelectPaymentMethodScreen.routeName,
                      builder: (context, state) =>
                          const SelectPaymentMethodScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: CategoryRoutes.aircon,
                      name: CategoryRoutes.aircon,
                      builder: (context, state) =>
                          const CategoryExperienceScreen(
                              categoryId: ServiceCategoryId.aircon),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: CategoryRoutes.beautyWellness,
                      name: CategoryRoutes.beautyWellness,
                      builder: (context, state) =>
                          const CategoryExperienceScreen(
                              categoryId: ServiceCategoryId.beautyWellness),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: CategoryRoutes.hairNails,
                      name: CategoryRoutes.hairNails,
                      builder: (context, state) =>
                          const CategoryExperienceScreen(
                              categoryId: ServiceCategoryId.hairAndNails),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: CategoryRoutes.massage,
                      name: CategoryRoutes.massage,
                      builder: (context, state) =>
                          const CategoryExperienceScreen(
                              categoryId: ServiceCategoryId.massage),
                    ),
                    // ── Canonical Catalog V2 ───────────────────────────────
                    //
                    // Category → Subcategory → Service, every hop keyed on a
                    // canonical backend id. These sit alongside the legacy
                    // category routes above rather than replacing them: those
                    // names are live deep links and notification targets, and
                    // retiring them is a separate, deliberate step once no
                    // build in the field still emits them.
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: CatalogRoutes.browsePath,
                      name: CatalogRoutes.browse,
                      builder: (context, state) => CatalogBrowseScreen(
                        controller: dpLocator<CatalogController>(),
                        onCategorySelected: (categoryId) => context.pushNamed(
                          CatalogRoutes.category,
                          pathParameters: {'categoryId': '$categoryId'},
                        ),
                      ),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: CatalogRoutes.categoryPath,
                      name: CatalogRoutes.category,
                      builder: (context, state) {
                        final id = CatalogRoutes.parseId(
                            state.pathParameters['categoryId']);
                        if (id == null) return const CatalogUnavailableScreen();
                        return CategoryScreen(
                          controller: dpLocator<CatalogController>(),
                          categoryId: id,
                          onSubcategorySelected: (subcategoryId) =>
                              context.pushNamed(
                            CatalogRoutes.subcategory,
                            pathParameters: {'subcategoryId': '$subcategoryId'},
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: CatalogRoutes.subcategoryPath,
                      name: CatalogRoutes.subcategory,
                      builder: (context, state) {
                        final id = CatalogRoutes.parseId(
                            state.pathParameters['subcategoryId']);
                        if (id == null) return const CatalogUnavailableScreen();
                        return SubcategoryScreen(
                          controller: dpLocator<CatalogController>(),
                          subcategoryId: id,
                          // Routes on service.id — identity is never rebuilt
                          // from the name (§35).
                          onServiceSelected: (service) => context.pushNamed(
                            CatalogRoutes.service,
                            pathParameters: {'serviceId': '${service.id}'},
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: CatalogRoutes.servicePath,
                      name: CatalogRoutes.service,
                      builder: (context, state) {
                        final id = CatalogRoutes.parseId(
                            state.pathParameters['serviceId']);
                        if (id == null) return const CatalogUnavailableScreen();
                        return ServiceDetailScreen(
                          // Factory, not singleton: add-on selection belongs to
                          // one Service and must not follow the customer to the
                          // next.
                          controller: dpLocator<ServiceDetailController>(),
                          serviceId: id,
                          onStartBooking: (detail, addonIds) =>
                              startCanonicalBooking(
                            context: context,
                            detail: detail,
                            selectedAddonIds: addonIds,
                          ),
                        );
                      },
                    ),
                    // Deep-link path route: /category/:categoryKey
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: 'category/:categoryKey',
                      name: 'CategoryExperience',
                      builder: (context, state) {
                        final key = state.pathParameters['categoryKey'] ?? '';
                        final id = _categoryIdFromKey(key);
                        if (id == null) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => context.goNamed(HomeScreen.routeName),
                          );
                          return const Scaffold();
                        }
                        return CategoryExperienceScreen(categoryId: id);
                      },
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: AirconOptionsScreen.route,
                      name: AirconOptionsScreen.routeName,
                      builder: (context, state) => const AirconOptionsScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: AirconCheckoutScreen.route,
                      name: AirconCheckoutScreen.routeName,
                      builder: (context, state) => const AirconCheckoutScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: AirconConfirmationScreen.route,
                      name: AirconConfirmationScreen.routeName,
                      builder: (context, state) =>
                          const AirconConfirmationScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: BookingOtpScreen.route,
                      name: BookingOtpScreen.routeName,
                      builder: (context, state) {
                        final args = state.extra;
                        if (args is! BookingOtpArgs) {
                          // No booking context (e.g. web refresh / deep link,
                          // where push `extra` is lost) — bounce home instead
                          // of crashing on the cast.
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => context.goNamed(HomeScreen.routeName),
                          );
                          return const Scaffold();
                        }
                        return BookingOtpScreen(
                          bookingId: args.bookingId,
                          flow: args.flow,
                          confirmationRouteName: args.confirmationRouteName,
                        );
                      },
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: BwOptionsScreen.route,
                      name: BwOptionsScreen.routeName,
                      builder: (context, state) {
                        final serviceId = asServiceId(state.extra);
                        if (serviceId == null) {
                          // Same recovery every other identity-bearing route
                          // uses. Booking options for a Service we cannot name
                          // is not a degraded screen, it is a wrong one.
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => context.goNamed(HomeScreen.routeName),
                          );
                          return const Scaffold();
                        }
                        return BwOptionsScreen(serviceId: serviceId);
                      },
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: BwAddOnsScreen.route,
                      name: BwAddOnsScreen.routeName,
                      builder: (context, state) => const BwAddOnsScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: BwBranchSlotScreen.route,
                      name: BwBranchSlotScreen.routeName,
                      builder: (context, state) => const BwBranchSlotScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: BwCheckoutScreen.route,
                      name: BwCheckoutScreen.routeName,
                      builder: (context, state) => const BwCheckoutScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: BwConfirmationScreen.route,
                      name: BwConfirmationScreen.routeName,
                      builder: (context, state) => const BwConfirmationScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: PaymentWebViewScreen.route,
                      name: PaymentWebViewScreen.routeName,
                      builder: (context, state) {
                        final extra = state.extra;
                        if (extra is! PaymentScreenArgs) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => context.goNamed(HomeScreen.routeName),
                          );
                          return const Scaffold();
                        }
                        return PaymentWebViewScreen(
                          bookingId: extra.bookingId,
                          checkoutUrl: extra.checkoutUrl,
                        );
                      },
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: MerchantMenuScreen.route,
                      name: MerchantMenuScreen.routeName,
                      builder: (context, state) => const MerchantMenuScreen(),
                      routes: [
                        GoRoute(
                          parentNavigatorKey: rootNavigatorKey,
                          path: ItemOptionMenuScreen.route,
                          name: ItemOptionMenuScreen.routeName,
                          builder: (context, state) {
                            final extra = state.extra;
                            if (extra is! ({
                              MerchantServiceModel service,
                              String? joIId
                            })) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => context.goNamed(HomeScreen.routeName),
                              );
                              return const Scaffold();
                            }
                            return ItemOptionMenuScreen(
                              service: extra.service,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: BookingsScreen.route,
                  name: BookingsScreen.routeName,
                  builder: (context, state) => const BookingsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: MessagesInboxScreen.route,
                  name: MessagesInboxScreen.routeName,
                  builder: (context, state) => const MessagesInboxScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: ProfileScreen.route,
                  name: ProfileScreen.routeName,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: JobOrderSummaryScreen.route,
          name: JobOrderSummaryScreen.routeName,
          builder: (context, state) => JobOrderSummaryScreen(
            id: state.pathParameters["id"] ?? '',
          ),
        ),
        // Path-param detail route — replaces the old extra-based /BookingDetail.
        // Navigated to via context.go('/bookings/<id>') from the bookings list
        // and via the legacy /booking/:id alias below.
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: BookingDetailScreen.route, // '/bookings/:bookingId'
          name: BookingDetailScreen.routeName, // 'BookingDetail'
          builder: (context, state) => BookingDetailScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
          ),
        ),
        // Booking chat — reached via _openMessaging() in BookingDetailScreen.
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/bookings/:bookingId/messages',
          name: 'BookingMessages',
          builder: (context, state) => BookingChatScreen(
            jobOrderId: state.pathParameters['bookingId'] ?? '',
            title: 'Booking Chat',
          ),
        ),
        // Live tracking — reached via BookingDetailScreen "Track Provider" button.
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/bookings/:bookingId/track',
          name: LiveTrackingScreen.routeName,
          builder: (context, state) => LiveTrackingScreen(
            bookingId: state.pathParameters['bookingId'] ?? '',
            args: state.extra is TrackingArgs
                ? state.extra as TrackingArgs
                : null,
          ),
        ),
        // Legacy alias — keeps old push('/booking/:id') deep links working.
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/booking/:id',
          name: 'BookingDetailById',
          builder: (context, state) => BookingDetailScreen(
            bookingId: state.pathParameters['id'] ?? '',
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: BookingCalendarScreen.route,
          name: BookingCalendarScreen.routeName,
          builder: (context, state) => const BookingCalendarScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: RewardsScreen.route,
          name: RewardsScreen.routeName,
          builder: (context, state) => const RewardsScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: FavouritesScreen.route,
          name: FavouritesScreen.routeName,
          builder: (context, state) => const FavouritesScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: SavedAddressesScreen.route,
          name: SavedAddressesScreen.routeName,
          builder: (context, state) => const SavedAddressesScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: SettingsScreen.route,
          name: SettingsScreen.routeName,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: LanguageScreen.route,
          name: LanguageScreen.routeName,
          builder: (context, state) => const LanguageScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: ProfileEditScreen.route,
          name: ProfileEditScreen.routeName,
          builder: (context, state) => const ProfileEditScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: AppearanceScreen.route,
          name: AppearanceScreen.routeName,
          builder: (context, state) => const AppearanceScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: AboutScreen.route,
          name: AboutScreen.routeName,
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: SecurityScreen.route,
          name: SecurityScreen.routeName,
          builder: (context, state) => const SecurityScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: PrivacyLegalScreen.route,
          name: PrivacyLegalScreen.routeName,
          builder: (context, state) => const PrivacyLegalScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: DeleteAccountScreen.route,
          name: DeleteAccountScreen.routeName,
          builder: (context, state) => const DeleteAccountScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: PermissionsScreen.route,
          name: PermissionsScreen.routeName,
          builder: (context, state) => const PermissionsScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: HelpSupportScreen.route,
          name: HelpSupportScreen.routeName,
          builder: (context, state) => const HelpSupportScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: NotificationsScreen.route,
          name: NotificationsScreen.routeName,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: BookingChatScreen.route,
          name: BookingChatScreen.routeName,
          builder: (context, state) => BookingChatScreen(
            jobOrderId: state.pathParameters["jobOrderId"] ?? '',
            title: state.extra is String ? state.extra as String : null,
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: AuthenticationGateScreen.route,
          name: AuthenticationGateScreen.routeName,
          builder: (context, state) => AuthenticationGateScreen(
            returnIntent: state.extra is AuthReturnIntent
                ? state.extra as AuthReturnIntent
                : null,
          ),
        ),
        // ── Support (C18 SUPPORTCORE+) ──────────────────────────────────────
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: SupportHomeScreen.route,
          name: SupportHomeScreen.routeName,
          builder: (context, state) => const SupportHomeScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: SupportTicketsScreen.route,
          name: SupportTicketsScreen.routeName,
          builder: (context, state) => const SupportTicketsScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/support/tickets/:ticketKey',
          name: SupportTicketDetailScreen.routeName,
          builder: (context, state) => SupportTicketDetailScreen(
            ticketKey: state.pathParameters['ticketKey'] ?? '',
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: CreateSupportTicketScreen.route,
          name: CreateSupportTicketScreen.routeName,
          builder: (context, state) => CreateSupportTicketScreen(
            initialCategory: state.uri.queryParameters['category'],
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: SafetySupportScreen.route,
          name: SafetySupportScreen.routeName,
          builder: (context, state) => const SafetySupportScreen(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: HelpCenterScreen.route,
          name: HelpCenterScreen.routeName,
          builder: (context, state) => const HelpCenterScreen(),
        ),
        // ── Reviews (C19 REVIEWCORE+) ───────────────────────────────────────
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: ReviewFormScreen.route,
          name: ReviewFormScreen.routeName,
          builder: (context, state) => ReviewFormScreen(
            bookingId: state.uri.queryParameters['bookingId'] ?? '',
            bookingLabel: state.uri.queryParameters['bookingLabel'],
            serviceCategory: state.uri.queryParameters['serviceCategory'],
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: ReviewDetailScreen.route,
          name: ReviewDetailScreen.routeName,
          builder: (context, state) => ReviewDetailScreen(
            bookingId: state.uri.queryParameters['bookingId'],
            reviewId: state.uri.queryParameters['reviewId'],
          ),
        ),
      ],
    );
  }
}
