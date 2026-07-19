import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/common/presentation/screens/drawer_placeholder_screens.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_options_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_repair_screen.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_state.dart';
import 'package:client/modules/bookings/presentation/screens/booking_calendar_screen.dart';
import 'package:client/modules/bookings/presentation/screens/bookings_screen.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/beauty_wellness_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_addons_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/hair_nails_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/massage_screen.dart';
import 'package:client/modules/homepage/presentation/dialogs/logout_dialog.dart';
import 'package:client/modules/homepage/presentation/screens/search_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/homepage/presentation/widgets/drawer_item_widget.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:client/modules/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = "HomeScreen";
  static String route = "/HomeScreen";
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final store = dpLocator<HomeStore>();
  final bwStore = dpLocator<BwBookingStore>();
  final airconStore = dpLocator<AirconBookingStore>();
  final _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: "scaffoldKey");

  static const String _merchantName = 'Servana';

  @override
  void initState() {
    super.initState();
    store.loadBookings();
    bwStore.ensureOptionsLoaded(serviceId: 2);
    airconStore.ensureOptionsLoaded(serviceId: 1);
    _restoreDraftIfPending();
  }

  // STITCH-C05-001 / LEAK-C05-001: restores a pending BookingDraft after the
  // guest→checkout→auth-gate→login path, where the BlocListener fires before
  // this widget is first mounted and the state transition is therefore missed.
  // Also called from BlocListener for the normal login path so auth guard and
  // clear() are applied in both code paths from a single source.
  void _restoreDraftIfPending() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!dpLocator<AuthStateService>().isAuthenticated) return;
      final draft = dpLocator<BookingDraftService>().restore();
      if (draft?.returnRouteName != null) {
        context.pushNamed(draft!.returnRouteName!);
        dpLocator<BookingDraftService>().clear();
      }
    });
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthenticationAuthenticated) {
          store.loadBookings();
          _restoreDraftIfPending();
        }
      },
      child: Scaffold(
        backgroundColor: ColorPalette.primaryBackground,
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: RefreshIndicator(
          color: ColorPalette.primaryColorDark,
          onRefresh: () async {
            store.loadBookings();
            bwStore.loadOptionsWithAddons(serviceId: 2);
            airconStore.loadOptionsWithAddons(serviceId: 1);
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeaderSection()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildAvailableServices(),
                ),
              ),
              SliverToBoxAdapter(child: _buildActiveBookingSection()),
              SliverToBoxAdapter(child: _buildFeaturedSection()),
              SliverToBoxAdapter(child: _buildDiscoveryCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorPalette.primaryColorDark,
            ColorPalette.primaryGradientEnd(),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            _buildGreeting(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            onPressed: () =>
                context.pushNamed(NotificationsScreen.routeName),
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 26),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Observer(builder: (ctx) {
        final session = store.session;
        if (session != null) {
          final parts = session.fullname
                .split(RegExp(r'\s+'))
                .where((p) => p.isNotEmpty)
                .toList();
          final first = parts.isNotEmpty ? parts.first : _merchantName;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_timeGreeting()},',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              Text(
                first,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find your next service',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Book a $_merchantName professional today',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          AppHaptics.selection();
          context.pushNamed(SearchScreen.routeName);
        },
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded,
                  color: ColorPalette.primaryColorDark, size: 22),
              const SizedBox(width: 10),
              Text(
                'Search for services…',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 14,
                  color: ColorPalette.secondaryText.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Service categories ────────────────────────────────────────────────────

  Widget _buildAvailableServices() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.shadow(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(
              'Services',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: ColorPalette.secondaryText,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ServiceCategoryTile(
                icon: Icons.spa_outlined,
                label: 'Beauty',
                onTap: () {
                  AppHaptics.selection();
                  context.pushNamed(BeautyWellnessScreen.routeName);
                },
              ),
              _ServiceCategoryTile(
                icon: Icons.content_cut_outlined,
                label: 'Hair &\nNails',
                onTap: () {
                  AppHaptics.selection();
                  context.pushNamed(HairNailsScreen.routeName);
                },
              ),
              _ServiceCategoryTile(
                icon: Icons.self_improvement_outlined,
                label: 'Massage',
                onTap: () {
                  AppHaptics.selection();
                  context.pushNamed(MassageScreen.routeName);
                },
              ),
              _ServiceCategoryTile(
                icon: Icons.ac_unit_rounded,
                label: 'Aircon\nRepair',
                onTap: () {
                  AppHaptics.selection();
                  context.pushNamed(AirconRepairScreen.routeName);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Active booking card (auth + active booking only) ─────────────────────

  Widget _buildActiveBookingSection() {
    return Observer(builder: (ctx) {
      if (store.session == null) return const SizedBox.shrink();
      final active = store.bookings
          .where((b) =>
              b.jobOrderStatus != JobOrderStatus.completed &&
              b.jobOrderStatus != JobOrderStatus.cancelled &&
              b.jobOrderStatus != JobOrderStatus.none)
          .firstOrNull;
      if (active == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Semantics(
          button: true,
          label: 'Active booking: ${active.merchantServiceName}. Tap to view.',
          child: GestureDetector(
            onTap: () {
              AppHaptics.selection();
              context.goNamed(BookingsScreen.routeName);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorPalette.primaryColorDark,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: ColorPalette.primaryColorDark.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.assignment_outlined,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active.merchantServiceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${active.jobOrderStatusToString} · ${DateFormat('MMM d').format(active.scheduleDate)}',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Featured services (real data, no fake metadata) ───────────────────────

  Widget _buildFeaturedSection() {
    return Observer(builder: (ctx) {
      final bwItems = bwStore.bookableOptions
          .map((o) => _FeaturedItem(raw: o, isAircon: false));
      final airconItems = airconStore.bookableOptions
          .map((o) => _FeaturedItem(raw: o, isAircon: true));
      final all = [...bwItems, ...airconItems].take(12).toList();
      final isLoading = bwStore.isLoading || airconStore.isLoading;

      if (all.isEmpty && isLoading) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Featured Services', onSeeAll: null),
              const SizedBox(height: 12),
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        );
      }
      if (all.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _sectionHeader(
                'Featured Services',
                onSeeAll: () => context.pushNamed(SearchScreen.routeName),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 222,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: all.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final item = all[i];
                  final name = (item.raw['level_3'] ??
                          item.raw['name'] ??
                          item.raw['optionName'] ??
                          'Service')
                      .toString();
                  final price = ServiceCardModel.extractPrice(item.raw);
                  final imageAsset =
                      ServiceCardModel(raw: item.raw, name: name).imageAsset;
                  return _FeaturedServiceCard(
                    name: name,
                    price: price,
                    imageAsset: imageAsset,
                    categoryLabel: item.isAircon ? 'Aircon' : 'Beauty & Wellness',
                    onTap: () {
                      AppHaptics.selection();
                      if (item.isAircon) {
                        airconStore.selectOption(item.raw);
                        context.pushNamed(AirconOptionsScreen.routeName);
                      } else {
                        bwStore.selectOption(item.raw);
                        context.pushNamed(BwAddOnsScreen.routeName);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Educational discovery card ────────────────────────────────────────────

  Widget _buildDiscoveryCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorPalette.primaryColorLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: ColorPalette.primaryColorDark.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryColorDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'How it works',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: ColorPalette.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _HowItWorksStep(
              number: 1,
              text: 'Choose your service from our categories',
            ),
            const SizedBox(height: 10),
            const _HowItWorksStep(
              number: 2,
              text: 'Select a date and time that works for you',
            ),
            const SizedBox(height: 10),
            const _HowItWorksStep(
              number: 3,
              text:
                  'Confirm your booking and a professional will be on the way',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  AppHaptics.selection();
                  context.pushNamed(SearchScreen.routeName);
                },
                style: TextButton.styleFrom(
                  backgroundColor: ColorPalette.primaryColorDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Browse Services',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header helper ─────────────────────────────────────────────────

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ColorPalette.secondaryText,
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              'See All',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: ColorPalette.primaryColorDark,
              ),
            ),
          ),
      ],
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: ColorPalette.primaryColor,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 280,
                child: Stack(
                  children: [
                    Positioned(
                      top: 200,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorPalette.secondaryBackground,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 150,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox.square(
                            dimension: 100,
                            child: CircleAvatar(
                              backgroundColor:
                                  ColorPalette.secondaryBackground,
                              child: Text(
                                _initials(store.session?.fullname),
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  color: ColorPalette.secondaryText,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            store.session?.fullname ?? 'Guest',
                            maxLines: 2,
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              color: ColorPalette.secondaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration:
                    BoxDecoration(color: ColorPalette.secondaryBackground),
                child: Column(
                  children: [
                    const Gap(30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          "My Account",
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const Gap(15),
                    DrawerItemWidget(
                      iconFile: "assets/icons/rewards icon.png",
                      title: "Rewards",
                      onTap: () {
                        Navigator.of(context).pop();
                        context.pushNamed(RewardsScreen.routeName);
                      },
                    ),
                    DrawerItemWidget(
                      iconFile: "assets/icons/favourites icon.png",
                      title: "Favourites",
                      onTap: () {
                        Navigator.of(context).pop();
                        context.pushNamed(FavouritesScreen.routeName);
                      },
                    ),
                    DrawerItemWidget(
                      iconFile: "assets/icons/order history icon.png",
                      title: "Orders History",
                      onTap: () {
                        Navigator.of(context).pop();
                        context.goNamed(BookingsScreen.routeName);
                      },
                    ),
                    DrawerItemWidget(
                      iconFile: "assets/icons/calendarclock.png",
                      title: "Booking Calendar",
                      onTap: () {
                        Navigator.of(context).pop();
                        context.pushNamed(BookingCalendarScreen.routeName);
                      },
                    ),
                    DrawerItemWidget(
                      iconFile: "assets/icons/profile icon.png",
                      title: "Profile",
                      onTap: () {
                        Navigator.of(context).pop();
                        context.goNamed(ProfileScreen.routeName);
                      },
                    ),
                    DrawerItemWidget(
                      iconFile: "assets/icons/saved addresses icon.png",
                      title: "Saved Addresses",
                      onTap: () {
                        Navigator.of(context).pop();
                        context.pushNamed(SavedAddressesScreen.routeName);
                      },
                    ),
                    const Gap(15),
                    const Divider(endIndent: 20, indent: 20),
                    const Gap(15),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          "General",
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const Gap(15),
                    DrawerItemWidget(
                      iconFile: "assets/icons/settings icon.png",
                      title: "Settings",
                      onTap: () {
                        Navigator.of(context).pop();
                        context.pushNamed(SettingsScreen.routeName);
                      },
                    ),
                    DrawerItemWidget(
                      iconFile: "assets/icons/languages icon.png",
                      title: "Language",
                      onTap: () {
                        Navigator.of(context).pop();
                        context.pushNamed(LanguageScreen.routeName);
                      },
                    ),
                    DrawerItemWidget(
                      iconFile: "assets/icons/help and support icon.png",
                      title: "Help & Support",
                      onTap: () {
                        Navigator.of(context).pop();
                        context.pushNamed(HelpSupportScreen.routeName);
                      },
                    ),
                    DrawerItemWidget(
                      title: "Logout",
                      onTap: () {
                        Navigator.of(context).pop();
                        LogoutDialog.showDialog(
                          context: context,
                          onConfirm: () {
                            context
                                .read<AuthenticationBloc>()
                                .add(AuthLogout());
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '?';
    final parts =
        n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final first = parts.isNotEmpty ? parts.first : n;
    final last = parts.length > 1 ? parts.last : '';
    final a = first.isNotEmpty ? first[0] : '?';
    final b = last.isNotEmpty ? last[0] : '';
    return (a + b).toUpperCase();
  }
}

// ── Service category tile ────────────────────────────────────────────────────

class _ServiceCategoryTile extends StatelessWidget {
  const _ServiceCategoryTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: ColorPalette.primaryBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ColorPalette.shadow(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 24, color: ColorPalette.primaryColorDark),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 12,
                color: ColorPalette.secondaryText,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured service card ────────────────────────────────────────────────────

class _FeaturedServiceCard extends StatelessWidget {
  const _FeaturedServiceCard({
    required this.name,
    required this.price,
    required this.imageAsset,
    required this.categoryLabel,
    this.onTap,
  });

  final String name;
  final int price;
  final String imageAsset;
  final String categoryLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$name, $categoryLabel${price > 0 ? ", ₱$price" : ""}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 175,
          decoration: BoxDecoration(
            color: ColorPalette.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.shadow(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  imageAsset,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorPalette.primaryColorLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categoryLabel,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: ColorPalette.primaryColorDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: ColorPalette.secondaryText,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (price > 0)
                        Text(
                          '₱$price',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: ColorPalette.primaryColorDark,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Source-tagged item for the featured carousel ─────────────────────────────

class _FeaturedItem {
  _FeaturedItem({required this.raw, required this.isAircon});
  final Map<String, dynamic> raw;
  final bool isAircon;
}

// ── How-it-works step ────────────────────────────────────────────────────────

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: ColorPalette.primaryColorDark,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 13,
                color: ColorPalette.secondaryText.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
