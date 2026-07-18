import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/drawer_placeholder_screens.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/modules/bookings/presentation/screens/booking_calendar_screen.dart';
import 'package:client/modules/bookings/presentation/screens/bookings_screen.dart';
import 'package:client/modules/homepage/presentation/screens/search_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/homepage/presentation/widgets/drawer_item_widget.dart';
import 'package:client/modules/landing/presentation/screens/welcome_screen.dart';
import 'package:client/modules/profile/presentation/screens/profile_screen.dart';
import 'package:client/modules/store_items/presentation/screens/store_items_screen.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_options_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_repair_screen.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/beauty_wellness_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_addons_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/hair_nails_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/massage_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

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

  static const String _merchantId = 'servana';
  static const String _merchantName = 'Servana';

  static const _blue = Color(0xFF1F44F2);
  static const _darkBlue = Color(0xFF0926B0);
  static const _orange = Color(0xFFF99343);
  static const _darkOrange = Color(0xFFB65509);
  static const _navyText = Color(0xFF02205B);
  static const _greyBg = Color(0xFFF7F7F7);

  final PageController _promoController = PageController(viewportFraction: 0.95);
  int _promoIndex = 0;

  @override
  void initState() {
    store.loadBookings();
    bwStore.ensureOptionsLoaded(serviceId: 2);
    airconStore.ensureOptionsLoaded(serviceId: 1);
    super.initState();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greyBg,
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 14),
            _buildAvailableServices(),
            const SizedBox(height: 14),
            _buildPromoBanner(),
            const SizedBox(height: 6),
            _buildPromoIndicator(),
            const SizedBox(height: 18),
            _buildRecommendedHeader(),
            const SizedBox(height: 8),
            _buildRecommendedServices(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.7, -0.5),
          end: Alignment(0.7, 1.0),
          colors: [_blue, _darkBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
              child: Observer(builder: (context) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const Icon(Icons.menu, color: Colors.white, size: 28),
                    ),
                    GestureDetector(
                      onTap: () =>
                          context.pushNamed(NotificationsScreen.routeName),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 28),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 10),
            Observer(builder: (context) {
              final fullName = store.session?.fullname ?? 'Guest';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Hi, $fullName!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Gothic A1',
                        fontWeight: FontWeight.w700,
                        fontSize: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Gothic A1',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 0.24,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: GestureDetector(
                onTap: () => context.pushNamed(SearchScreen.routeName),
                child: Container(
                  height: 51,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  decoration: BoxDecoration(
                    color: _greyBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.04),
                      width: 0.8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade600, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search for services you need',
                          style: TextStyle(
                            fontFamily: 'Gothic A1',
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.24,
                          ),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 31,
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.04),
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.tune, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableServices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'Available Services',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: _navyText,
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
                    context.pushNamed(BeautyWellnessScreen.routeName);
                  },
                ),
                _ServiceCategoryTile(
                  icon: Icons.content_cut_outlined,
                  label: 'Hair &\nNails',
                  onTap: () {
                    context.pushNamed(HairNailsScreen.routeName);
                  },
                ),
                _ServiceCategoryTile(
                  icon: Icons.self_improvement_outlined,
                  label: 'Massage',
                  onTap: () {
                    context.pushNamed(MassageScreen.routeName);
                  },
                ),
                _ServiceCategoryTile(
                  icon: Icons.ac_unit_rounded,
                  label: 'Aircon\nRepair',
                  onTap: () {
                    context.pushNamed(AirconRepairScreen.routeName);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return SizedBox(
      height: 178,
      child: PageView(
        controller: _promoController,
        onPageChanged: (i) => setState(() => _promoIndex = i),
        children: const [
          _PromoBannerCard(
            title: 'Book Massage\nServices Now!',
            subtitle: 'Get 5% Cashback on all\ndining experience',
            gradientColors: [_orange, _darkOrange],
          ),
          _PromoBannerCard(
            title: 'Book Massage\nServices Now!',
            subtitle: 'Get 5% Cashback on all\ndining experience',
            gradientColors: [_blue, _darkBlue],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        2,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: _promoIndex == i ? 20 : 6,
          decoration: BoxDecoration(
            color:
                _promoIndex == i ? _blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          const Text(
            'Recommended Services',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: _navyText,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              await context.pushNamed(
                StoreItemsScreen.routeName,
                extra: (
                  merchantId: _merchantId,
                  merchantName: _merchantName,
                  categoryName: null,
                ),
              );
            },
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedServices() {
    return Observer(builder: (context) {
      final bwItems = bwStore.bookableOptions
          .map((o) => _RecommendedItem(raw: o, isAircon: false));
      final airconItems = airconStore.bookableOptions
          .map((o) => _RecommendedItem(raw: o, isAircon: true));

      final all = [...bwItems, ...airconItems];
      final isLoading = bwStore.isLoading || airconStore.isLoading;

      if (all.isEmpty && isLoading) {
        return const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (all.isEmpty) {
        return const SizedBox.shrink();
      }

      final items = all.take(10).toList();
      return SizedBox(
        height: 300,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final item = items[i];
            final name = (item.raw['level_3'] ??
                    item.raw['name'] ??
                    item.raw['optionName'] ??
                    'Service')
                .toString();
            final price = ServiceCardModel.extractPrice(item.raw);
            final imageAsset =
                ServiceCardModel(raw: item.raw, name: name).imageAsset;
            return _RecommendedServiceCard(
              name: name,
              price: price,
              imageAsset: imageAsset,
              onTap: () {
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
      );
    });
  }

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
                      top: 200, left: 0, right: 0, bottom: 0,
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
                      top: 150, left: 0, right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox.square(
                            dimension: 100,
                            child: CircleAvatar(
                              backgroundColor: ColorPalette.secondaryBackground,
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
                decoration: BoxDecoration(color: ColorPalette.secondaryBackground),
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
                        SessionService.deleteSession();
                        context.goNamed(WelcomeScreen.routeName);
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
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final first = parts.isNotEmpty ? parts.first : n;
    final last = parts.length > 1 ? parts.last : '';
    final a = first.isNotEmpty ? first[0] : '?';
    final b = last.isNotEmpty ? last[0] : '';
    return (a + b).toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Service category tile (Beauty, Hair & Nails, Massage, Aircon Repair)
// ---------------------------------------------------------------------------
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
        width: 68,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(icon, size: 24, color: const Color(0xFF02205B)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: 'Gothic A1',
                fontSize: 12,
                color: Color(0xFF02205B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Promo banner card
// ---------------------------------------------------------------------------
class _PromoBannerCard extends StatelessWidget {
  const _PromoBannerCard({
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });

  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          final imageWidth = cardWidth * 0.48;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: const Alignment(-0.6, -0.7),
                end: const Alignment(0.6, 1.0),
                colors: gradientColors,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 0,
                  top: -2,
                  bottom: -11,
                  width: imageWidth,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    child: Image.asset(
                      'assets/images/home/book_image.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: SizedBox(
                    width: cardWidth - imageWidth - 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 26,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Gothic A1',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.3,
                            letterSpacing: -0.64,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recommended service card
// ---------------------------------------------------------------------------
class _RecommendedServiceCard extends StatelessWidget {
  const _RecommendedServiceCard({
    required this.name,
    required this.price,
    required this.imageAsset,
    this.onTap,
  });

  final String name;
  final int price;
  final String imageAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0D333333), offset: Offset(0, 0)),
            BoxShadow(
                color: Color(0x0D333333),
                offset: Offset(-1, 1),
                blurRadius: 3),
            BoxShadow(
                color: Color(0x0A333333),
                offset: Offset(-3, 3),
                blurRadius: 5),
            BoxShadow(
                color: Color(0x08333333),
                offset: Offset(-8, 7),
                blurRadius: 6),
            BoxShadow(
                color: Color(0x03333333),
                offset: Offset(-14, 12),
                blurRadius: 7),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x801F44F2),
                      ],
                      stops: [0.4, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.srcATop,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      height: 140,
                      width: double.infinity,
                    ),
                  ),
                ),
                // TODO: backend pending — restore promo badge once API exposes
                // a real discount/originalPrice field. Showing a fabricated
                // "Save 50%" without backing data is a soft trust risk.
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF99343),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.favorite_outline,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            _ReviewAvatars(reviewCount: '+200 reviews'),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: const Color(0xFF555555).withOpacity(0.71)),
                const SizedBox(width: 6),
                Text(
                  '24 hours open',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: const Color(0xFF555555).withOpacity(0.71),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: const Color(0xFF555555).withOpacity(0.71)),
                const SizedBox(width: 6),
                Text(
                  '3km away',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: const Color(0xFF555555).withOpacity(0.71),
                  ),
                ),
                const Spacer(),
                if (price > 0)
                  Text(
                    '₱$price',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                      letterSpacing: 0.28,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Source-tagged option for the recommended carousel — distinguishes B&W vs.
// aircon so the tap handler routes to the right next screen.
class _RecommendedItem {
  _RecommendedItem({required this.raw, required this.isAircon});
  final Map<String, dynamic> raw;
  final bool isAircon;
}

// ---------------------------------------------------------------------------
// Overlapping review avatar circles
// ---------------------------------------------------------------------------
class _ReviewAvatars extends StatelessWidget {
  const _ReviewAvatars({required this.reviewCount});
  final String reviewCount;

  @override
  Widget build(BuildContext context) {
    const double size = 27;
    const double overlap = 10;
    const avatarColors = [Color(0xFFF99343), Color(0xFFCADBFF), Color(0xFF025BF7)];
    const avatarLetters = ['R', 'Q', 'E'];

    return Row(
      children: [
        SizedBox(
          width: size + (avatarColors.length - 1) * (size - overlap),
          height: size,
          child: Stack(
            children: List.generate(avatarColors.length, (i) {
              return Positioned(
                left: i * (size - overlap),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: avatarColors[i],
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      avatarLetters[i],
                      style: const TextStyle(
                        fontFamily: 'Gothic A1',
                        fontSize: 12,
                        color: Color(0xFF02205B),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          reviewCount,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF025BF7),
          ),
        ),
      ],
    );
  }
}
