import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:client/core/analytics/domain/analytics_event.dart';
import 'package:client/core/analytics/events/home_events.dart';
import 'package:client/modules/homepage/application/home_campaign_eligibility.dart';
import 'package:client/modules/homepage/presentation/controllers/home_campaign_controller.dart';
import 'package:client/modules/homepage/presentation/widgets/servana_launch_benefits_modal.dart';
import 'package:client/common/constants/app_spacing.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/core/recovery/pending_payment_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/application/consent_gate_service.dart';
import 'package:client/common/domain/booking/booking_draft_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/common/presentation/screens/drawer_placeholder_screens.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/modules/notifications/application/notifications_controller.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_options_screen.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_state.dart';
import 'package:client/modules/bookings/presentation/screens/booking_calendar_screen.dart';
import 'package:client/modules/bookings/presentation/screens/bookings_screen.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_addons_screen.dart';
import 'package:client/modules/homepage/data/home_promotion_repository.dart';
import 'package:client/modules/homepage/domain/home_promotion.dart';
import 'package:client/modules/homepage/presentation/dialogs/logout_dialog.dart';
import 'package:client/modules/homepage/presentation/screens/search_screen.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/homepage/presentation/widgets/drawer_item_widget.dart';
import 'package:client/modules/homepage/presentation/widgets/home_atmosphere.dart';
import 'package:client/modules/homepage/presentation/widgets/home_benefit_section.dart';
import 'package:client/modules/homepage/presentation/widgets/home_category_grid.dart';
import 'package:client/modules/homepage/presentation/widgets/home_more_categories.dart';
import 'package:client/modules/homepage/application/home_composition_controller.dart';
import 'package:client/common/presentation/routes/catalog_routes.dart';
import 'package:client/modules/homepage/presentation/widgets/home_header.dart';
import 'package:client/modules/homepage/presentation/widgets/home_promotion_banner.dart';
import 'package:client/modules/homepage/presentation/widgets/home_search.dart';
import 'package:client/modules/job_order/data/enums/job_order_status.dart';
import 'package:client/modules/profile/presentation/screens/profile_screen.dart';
import 'package:client/common/presentation/category_campaign/category_campaign_coordinator.dart';
import 'package:client/common/presentation/category_campaign/category_campaign_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:client/common/presentation/routes/category_routes.dart';

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
  final _notifCtrl = dpLocator<NotificationsController>();
  final _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: "scaffoldKey");

  final _promoRepo = HomePromotionRepository();
  final _campaign = dpLocator<HomeCampaignController>();
  final _composition = dpLocator<HomeCompositionController>();

  /// Presents category promo banners and owns their single-instance guard.
  ///
  /// Held on the State, not rebuilt per tap: the guard has to outlive the
  /// individual gesture it is guarding against.
  final _categoryCampaigns = CategoryCampaignCoordinator(
    analytics: dpLocator<AnalyticsCoordinator>(),
  );

  /// Read once for §21 app-version targeting. package_info_plus is already a
  /// dependency and AnalyticsContextProvider reads it the same way.
  String _appVersion = '0.0.0';

  @override
  void initState() {
    super.initState();
    store.loadBookings();
    bwStore.ensureOptionsLoaded(serviceId: 2);
    airconStore.ensureOptionsLoaded(serviceId: 1);
    _restoreDraftIfPending();
    _loadAppVersion();
    _maybeShowConsentGate();
    _precacheCategoryCampaigns();
    // Fills the composition cache that logout has always cleared. Not awaited
    // and never surfaced as an error: the curated grid renders regardless, so
    // a catalog that cannot be read costs Home nothing.
    unawaited(_composition.load());
  }

  /// Warms the category campaign artwork once Home has drawn.
  ///
  /// Deliberately post-frame: these are ~2 MB PNGs each, and decoding them on
  /// the way to Home's first paint would trade a visible startup cost for a
  /// saving the customer only benefits from if they tap that category. Failure
  /// is ignored — the popup's own error path already falls back to the native
  /// layout, so a warm cache is an optimisation, not a dependency.
  void _precacheCategoryCampaigns() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final campaign in CategoryCampaignRegistry.all) {
        precacheImage(AssetImage(campaign.assetPath), context)
            .catchError((_) {});
      }
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) _appVersion = info.version;
    } catch (_) {
      // Leaves the permissive default. A version lookup failure must not
      // suppress the campaign — §21's bounds are optional, and an unparseable
      // or missing version is ignored rather than treated as out of range.
    }
  }

  @override
  void dispose() {
    // Home had no dispose() at all. The campaign schedules a delayed
    // presentation, and a Timer keeps its closure alive independently of the
    // widget tree — uncancelled, it fires into a disposed context (§8).
    _campaign.cancelPendingPresentation();
    super.dispose();
  }

  void _maybeShowConsentGate() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Awaited, so the campaign cannot race it. Both previously targeted the
      // same first frame; §7 puts required consent above a promotion, and two
      // modals opening together is the failure that ordering prevents.
      await dpLocator<ConsentGateService>().maybeShow(
        context,
        dpLocator<AnalyticsCoordinator>(),
      );
      if (!mounted) return;
      _maybeScheduleLaunchCampaign();
    });
  }

  /// LAUNCHBANNER+ §5/§8: evaluate eligibility, then present after a short,
  /// cancellable delay once Home is stably rendered.
  Future<void> _maybeScheduleLaunchCampaign() async {
    final campaign = _campaign.resolve(_promoRepo.getLaunchCampaign());
    await _campaign.initialise(campaign);
    if (!mounted) return;

    final session = store.session;
    final decision = await _campaign.evaluate(
      campaign: campaign,
      context: CampaignEvaluationContext(
        now: DateTime.now(),
        isAuthenticated: session != null,
        accountId: session?.customerID,
        appVersion: _appVersion,
        hasConfiguration: _campaign.hasConfiguration,
        shownThisSession: _campaign.shownThisSession,
        homeVisible: mounted,
        hasCriticalBooking: _hasCriticalBooking(),
      ),
    );
    if (!mounted) return;

    if (!decision.eligible) {
      _trackCampaign(HomeLaunchBannerSuppressedEvent(
        campaignId: campaign.id,
        campaignVersion: campaign.version,
        suppressionReason: decision.suppression.analyticsValue,
      ));
      return;
    }

    _trackCampaign(HomeLaunchBannerEligibleEvent(
      campaignId: campaign.id,
      campaignVersion: campaign.version,
    ));

    // Precache so the first frame of the modal is the artwork, not a blank
    // card (§31). Failure is non-fatal — the modal falls back natively.
    final asset = campaign.assetPath;
    if (asset != null) {
      unawaited(precacheImage(AssetImage(asset), context).catchError((_) {}));
    }

    _campaign.schedulePresentation(
      delay: const Duration(milliseconds: 800),
      // Re-checked at fire time: between scheduling and firing the customer
      // may have navigated away or another modal may have opened (§8).
      stillEligible: () => mounted && ModalRoute.of(context)?.isCurrent == true,
      present: () => _presentLaunchCampaign(campaign),
    );
  }

  Future<void> _presentLaunchCampaign(HomeCampaign campaign) async {
    final asset = campaign.assetPath;
    final ratio = campaign.assetAspectRatio;
    if (!mounted || asset == null || ratio == null) return;

    final accountId = store.session?.customerID;
    var impressionNumber = 0;

    final outcome = await ServanaLaunchBenefitsModal.show(
      context: context,
      assetPath: asset,
      assetAspectRatio: ratio,
      // §28: fires only once the campaign has actually rendered.
      onImpressionVerified: () async {
        final state = await _campaign.recordImpression(
          campaign: campaign,
          accountId: accountId,
          now: DateTime.now(),
        );
        impressionNumber = state.impressionCount;
        _trackCampaign(HomeLaunchBannerImpressionEvent(
          campaignId: campaign.id,
          campaignVersion: campaign.version,
          impressionNumber: impressionNumber,
        ));
      },
      onDisplayFailed: () => _trackCampaign(HomeLaunchBannerDisplayFailedEvent(
        campaignId: campaign.id,
        campaignVersion: campaign.version,
        result: 'image_load_failed',
      )),
    );

    if (!mounted) return;
    final now = DateTime.now();

    switch (outcome) {
      case LaunchBannerOutcome.cta:
        await _campaign.recordCtaCompleted(
            campaign: campaign, accountId: accountId, now: now);
        _trackCampaign(HomeLaunchBannerCtaSelectedEvent(
          campaignId: campaign.id,
          campaignVersion: campaign.version,
          impressionNumber: impressionNumber,
        ));
        if (!mounted) return;
        // §14: routed through the existing sealed-target dispatcher rather
        // than a parallel one, so the CTA cannot reach an unvalidated route.
        _handlePromotionTap(campaign.ctaTarget);

      case LaunchBannerOutcome.close:
        await _campaign.recordPermanentDismissal(
            campaign: campaign, accountId: accountId, now: now);
        _trackCampaign(HomeLaunchBannerClosedEvent(
          campaignId: campaign.id,
          campaignVersion: campaign.version,
          impressionNumber: impressionNumber,
        ));

      case LaunchBannerOutcome.remindLater:
        await _campaign.recordRemindLater(
            campaign: campaign, accountId: accountId, now: now);
        _trackCampaign(HomeLaunchBannerRemindLaterEvent(
          campaignId: campaign.id,
          campaignVersion: campaign.version,
          impressionNumber: impressionNumber,
        ));

      case LaunchBannerOutcome.backOrBarrier:
      case null:
        // §18: a reflexive back-swipe is not a rejection. Same cooldown as
        // remind-later, reported separately so the funnel stays honest.
        await _campaign.recordRemindLater(
            campaign: campaign, accountId: accountId, now: now);
        _trackCampaign(HomeLaunchBannerDismissedByBackEvent(
          campaignId: campaign.id,
          campaignVersion: campaign.version,
          impressionNumber: impressionNumber,
        ));
    }
  }

  /// §7: an OTP or payment-blocked booking outranks a promotion.
  bool _hasCriticalBooking() {
    try {
      return store.bookings.any((b) {
        final s = (b.jobOrderStatusToString).toUpperCase();
        return s.contains('OTP') || s.contains('PAYMENT');
      });
    } catch (_) {
      return false;
    }
  }

  /// Analytics must never surface to the customer or block Home (§29).
  void _trackCampaign(AnalyticsEvent event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  // STITCH-C05-001 / LEAK-C05-001: restores a pending BookingDraft after the
  // guest→checkout→auth-gate→login path, where the BlocListener fires before
  // this widget is first mounted and the state transition is therefore missed.
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

  // _scheduleSpotlight was removed with the "One app. More ways to get things
  // done." campaign overlay. It interrupted every launch with a full-screen
  // modal a second after Home appeared, before the customer had read anything,
  // and its only action duplicated the Explore Services CTA already on the
  // page. The campaign controller, eligibility rules and the spotlight widget
  // are left in place so a future campaign can use them deliberately.

  void _handlePromotionTap(HomePromotionTarget target) {
    switch (target) {
      case HomeTargetSearch():
        context.pushNamed(SearchScreen.routeName);
      case HomeTargetCategory(categoryKey: final key):
        _handleCategoryTap(key);
      case HomeTargetInformational():
        break; // not wired yet
      case HomeTargetNoNavigation():
        break;
    }
  }

  /// Navigates to a category, showing its promotional campaign first when one
  /// exists.
  ///
  /// The campaign is a preview, not a gate: whether the customer taps its call
  /// to action or dismisses it, the category route and any authentication it
  /// already enforces are unchanged. A category with no creative registered
  /// navigates immediately, exactly as before.
  ///
  /// Only an explicit tap on a Home category card reaches here — a deep link
  /// resolves the category route directly through the router and never sees a
  /// popup.
  /// Opens a catalog category that has no curated Home card.
  ///
  /// Routed by `catalog_categories.id`, never by slug: `CatalogRoutes` is
  /// keyed on the id so that renaming a category cannot break a link already
  /// in the field. The curated four keep `_handleCategoryTap`, which is what
  /// the category campaign registry is keyed on.
  void _openCatalogCategory(HomeCategory category) {
    context.pushNamed(
      CatalogRoutes.category,
      pathParameters: <String, String>{'categoryId': '${category.id}'},
    );
  }

  Future<void> _handleCategoryTap(String key) async {
    if (CategoryCampaignCoordinator.hasCampaignFor(key)) {
      final explore = await _categoryCampaigns.present(
        context: context,
        categoryKey: key,
      );
      // Dismissed, or a second tap that the guard rejected. Either way the
      // customer stays on Home with its scroll position untouched — no route
      // was pushed.
      if (!explore) return;
      // The modal's own route has finished popping by the time present()
      // completes, but this State can still have been disposed underneath it.
      if (!mounted) return;
    }
    _navigateToCategory(key);
  }

  /// The canonical destination for each category card.
  ///
  /// Unchanged by the campaign work, and deliberately kept as the single place
  /// that names a category route so a popup can never introduce a second one.
  void _navigateToCategory(String key) {
    switch (key) {
      case 'beauty_wellness':
        context.pushNamed(CategoryRoutes.beautyWellness);
      case 'hair_nails':
        context.pushNamed(CategoryRoutes.hairNails);
      case 'massage':
        context.pushNamed(CategoryRoutes.massage);
      case 'aircon':
        context.pushNamed(CategoryRoutes.aircon);
      default:
        context.pushNamed(SearchScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthenticationAuthenticated) {
          store.loadBookings();
          _restoreDraftIfPending();
          // STITCH B2: show resume prompt for any payment interrupted by process kill.
          final paymentCtx = dpLocator<PendingPaymentService>().consume();
          if (paymentCtx != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Resume payment for booking #${paymentCtx.bookingId}?'),
                duration: const Duration(seconds: 10),
                action: SnackBarAction(
                  label: 'Resume',
                  onPressed: () async {
                    final ok = await launchUrl(
                      Uri.parse(paymentCtx.checkoutUrl),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Could not open payment page. Try again later.'),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          }
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
              // ── Header: atmosphere + greeting + search ──────────────────
              SliverToBoxAdapter(child: _buildHeaderSection()),

              // ── Category grid ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        // Left gutter only. The header owns the gap above
                        // this heading (§9: one section owns the spacing, not
                        // both).
                        padding: EdgeInsets.only(
                          left: homeGutter(context),
                          bottom: AppSpacing.md,
                        ),
                        child: Text(
                          'Services',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: ColorPalette.secondaryText,
                          ),
                        ),
                      ),
                      Observer(builder: (ctx) {
                        final isAuth = store.session != null;
                        final bannerA =
                            _promoRepo.getBannerA(isAuthenticated: isAuth);
                        return Column(
                          children: [
                            ServanaHomeCategoryGrid(
                              animate: true,
                              onCategoryTap: _handleCategoryTap,
                            ),
                            // Catalog categories with no curated card. Renders
                            // nothing until the composition answers, so the
                            // grid above is never gated on it.
                            ListenableBuilder(
                              listenable: _composition,
                              builder: (context, _) => HomeMoreCategories(
                                state: _composition.state,
                                onTap: _openCatalogCategory,
                              ),
                            ),
                            if (bannerA != null) ...[
                              const SizedBox(height: 20),
                              ServanaPromotionBanner(
                                promotion: bannerA,
                                onCtaTap: () =>
                                    _handlePromotionTap(bannerA.target),
                              ),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Active booking card (auth + active booking only) ─────────
              SliverToBoxAdapter(child: _buildActiveBookingSection()),

              // ── Featured services (real data) ────────────────────────────
              SliverToBoxAdapter(child: _buildFeaturedSection()),

              // ── Banner B: category spotlight ─────────────────────────────
              SliverToBoxAdapter(
                child: Observer(builder: (ctx) {
                  final isAuth = store.session != null;
                  final bannerB =
                      _promoRepo.getBannerB(isAuthenticated: isAuth);
                  if (bannerB == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ServanaPromotionBanner(
                      promotion: bannerB,
                      onCtaTap: () => _handlePromotionTap(bannerB.target),
                    ),
                  );
                }),
              ),

              // ── Benefit section (replaces discovery card) ────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: ServanaBenefitSection(),
                ),
              ),

              // ── Banner C: reengagement ───────────────────────────────────
              SliverToBoxAdapter(
                child: Observer(builder: (ctx) {
                  final isAuth = store.session != null;
                  final bannerC =
                      _promoRepo.getBannerC(isAuthenticated: isAuth);
                  if (bannerC == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ServanaPromotionBanner(
                      promotion: bannerC,
                      onCtaTap: () => _handlePromotionTap(bannerC.target),
                    ),
                  );
                }),
              ),

              // §18: breathing room only.
              //
              // The Scaffold already reserves the navigation's own height for
              // page content, so this must NOT re-add it — doing so is the
              // double-count §18 warns about. 24 is the visible gap between the
              // last card and the bar, nothing more.
              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeaderSection() {
    return Builder(builder: (ctx) {
      // Content-driven, not calculated (§6).
      //
      // This used to be `const contentH = 76.0 + 80.0` — a hardcoded sum of
      // assumed child sizes: "header inner padding 16 top + 40 row + 20 bottom"
      // plus "search 52 + 28 bottom". The real content measures 161pt, which is
      // why the emulator showed "BOTTOM OVERFLOWED BY 5.0 PIXELS" at default
      // text size, before any of the conditions that were supposed to be the
      // risk — a long first name, bold text, 200% scaling or a localised
      // greeting. The arithmetic was simply wrong, and it would have been
      // wrong-and-worse for every one of those.
      //
      // The Stack now takes its height from the Column, and the atmosphere
      // fills whatever that turns out to be. Nothing to keep in sync.
      return Stack(
        children: [
          const Positioned.fill(child: ServanaHomeAtmosphere()),
          SafeArea(
            bottom: false,
            child: Observer(builder: (obsCtx) {
              final s = store.session;
              final parts = (s?.fullname ?? '')
                  .split(RegExp(r'\s+'))
                  .where((p) => p.isNotEmpty)
                  .toList();
              final first = parts.isNotEmpty ? parts.first : null;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListenableBuilder(
                    listenable: _notifCtrl,
                    builder: (_, __) => ServanaHomeHeader(
                      firstName: first,
                      isAuthenticated: s != null,
                      animate: true,
                      notificationCount: _notifCtrl.unreadCount,
                      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                      onNotificationTap: () =>
                          context.pushNamed(NotificationsScreen.routeName),
                    ),
                  ),
                  ServanaHomeSearch(
                    onTap: () => context.pushNamed(SearchScreen.routeName),
                    animate: true,
                    animationDelay: const Duration(milliseconds: 160),
                  ),
                  // §8: this section owns the ENTIRE gap down to the next
                  // one. It used to add 28 here while the Services heading
                  // added another 20 above itself, giving a 48pt trench that
                  // neither file could see on its own.
                  const SizedBox(height: AppSpacing.section),
                ],
              );
            }),
          ),
        ],
      );
    });
  }

  // ── Active booking card (auth + active booking only) ─────────────────────

  Widget _buildActiveBookingSection() {
    return Observer(builder: (ctx) {
      if (store.session == null) return const SizedBox.shrink();
      final active = store.bookings
          .where(
            (b) =>
                b.jobOrderStatus != JobOrderStatus.completed &&
                b.jobOrderStatus != JobOrderStatus.cancelled &&
                b.jobOrderStatus != JobOrderStatus.none,
          )
          .firstOrNull;
      if (active == null) return const SizedBox.shrink();

      return Padding(
        // Shared gutter (§12). This was a hardcoded 16 while the grid,
        // banners and benefit section all sat at 20, so the card was visibly
        // indented differently from everything above and below it.
        padding: EdgeInsets.fromLTRB(
          homeGutter(context),
          AppSpacing.section,
          homeGutter(context),
          0,
        ),
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
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
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
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
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
      // Interleaved, not concatenated-then-truncated.
      //
      // This was `[...bwItems, ...airconItems].take(12)`. Beauty & Wellness
      // alone seeds well over twelve options (migrations 002-005 add Massage,
      // Nails, Hair, Facial and Beauty Drip under service_id 2), so the window
      // filled before it ever reached the aircon items and "Featured Services"
      // could never feature an aircon service. The cap looked like a display
      // limit; it was acting as a category filter.
      //
      // Alternating draws from both lists keeps the same twelve-item budget
      // while guaranteeing each category is represented when it has anything to
      // show.
      final bw = bwItems.toList();
      final ac = airconItems.toList();
      final all = <_FeaturedItem>[];
      for (var i = 0;
          all.length < 12 && (i < bw.length || i < ac.length);
          i++) {
        if (i < bw.length) all.add(bw[i]);
        if (all.length < 12 && i < ac.length) all.add(ac[i]);
      }
      final isLoading = bwStore.isLoading || airconStore.isLoading;

      if (all.isEmpty && isLoading) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            homeGutter(context),
            AppSpacing.xl,
            homeGutter(context),
            0,
          ),
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
              padding: EdgeInsets.symmetric(horizontal: homeGutter(context)),
              child: _sectionHeader(
                'Featured Services',
                onSeeAll: () => context.pushNamed(SearchScreen.routeName),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 222,
              child: ListView.separated(
                // Same gutter as the heading above it, so the first card's
                // leading edge lines up with the section title (§13).
                padding: EdgeInsets.symmetric(horizontal: homeGutter(context)),
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
                    categoryLabel:
                        item.isAircon ? 'Aircon' : 'Beauty & Wellness',
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
              // No horizontal padding: the parent already applies the page
              // gutter, and TextButton's default inset pushed "See All" 8pt
              // inside the right-hand guide that every other section respects.
              padding: EdgeInsets.zero,
              // Keeps the accessible tap target without adding visual width.
              tapTargetSize: MaterialTapTargetSize.padded,
              minimumSize: const Size(48, 48),
              // "See All" is narrower than the 48pt minimum, and a button
              // centres its child by default — so the tap target that keeps
              // this control accessible was itself holding the label ~4pt
              // inside the guide, which is the misalignment this section set
              // out to remove. Pinning the child right puts the text on the
              // gutter while the 48pt box stays.
              alignment: Alignment.centerRight,
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
                decoration:
                    BoxDecoration(color: ColorPalette.secondaryBackground),
                child: Column(
                  children: [
                    const Gap(30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: homeGutter(context)),
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
                        padding: EdgeInsets.only(left: homeGutter(context)),
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
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final first = parts.isNotEmpty ? parts.first : n;
    final last = parts.length > 1 ? parts.last : '';
    final a = first.isNotEmpty ? first[0] : '?';
    final b = last.isNotEmpty ? last[0] : '';
    return (a + b).toUpperCase();
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
                          horizontal: 6,
                          vertical: 2,
                        ),
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
