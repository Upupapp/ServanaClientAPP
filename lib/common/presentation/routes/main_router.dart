import 'package:client/common/data/models/job_order_model.dart';
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
import 'package:client/common/presentation/widgets/main_nav_scaffold.dart';
// import 'package:client/modules/payments/presentation/screens/add_credit_card_screen.dart';
import 'package:client/modules/registration/presentation/screens/create_account_screen.dart';
import 'package:client/modules/store_items/presentation/screens/store_items_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_options_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_confirmation_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_repair_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/beauty_wellness_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_options_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/hair_nails_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/massage_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_addons_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_branch_slot_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_checkout_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_confirmation_screen.dart';
import 'package:client/common/presentation/screens/payment_webview_screen.dart';
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
        final isProtected = loc.startsWith(BookingsScreen.route) ||
            loc.startsWith(MessagesInboxScreen.route) ||
            loc.startsWith(ProfileScreen.route);

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
                        if (extra
                            is! ({
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
                      path: AirconRepairScreen.route,
                      name: AirconRepairScreen.routeName,
                      builder: (context, state) => const AirconRepairScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: BeautyWellnessScreen.route,
                      name: BeautyWellnessScreen.routeName,
                      builder: (context, state) => const BeautyWellnessScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: HairNailsScreen.route,
                      name: HairNailsScreen.routeName,
                      builder: (context, state) => const HairNailsScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: MassageScreen.route,
                      name: MassageScreen.routeName,
                      builder: (context, state) => const MassageScreen(),
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
                        final extra = state.extra;
                        final serviceId =
                            extra is int ? extra : int.tryParse('$extra') ?? 0;
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
                      builder: (context, state) =>
                          const BwBranchSlotScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: BwCheckoutScreen.route,
                      name: BwCheckoutScreen.routeName,
                      builder: (context, state) =>
                          const BwCheckoutScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: rootNavigatorKey,
                      path: BwConfirmationScreen.route,
                      name: BwConfirmationScreen.routeName,
                      builder: (context, state) =>
                          const BwConfirmationScreen(),
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
                            if (extra
                                is! ({
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
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: BookingDetailScreen.route,
          name: BookingDetailScreen.routeName,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! JobOrder) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => context.goNamed(HomeScreen.routeName),
              );
              return const Scaffold();
            }
            return BookingDetailScreen(booking: extra);
          },
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
      ],
    );
  }
}
