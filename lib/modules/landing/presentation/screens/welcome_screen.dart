import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/servana_banner.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/application/consent_gate_service.dart';
import 'package:client/common/presentation/widgets/servana_primary_button.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/common/services/motion_tokens.dart';
import 'package:client/common/services/onboarding_state_service.dart';
import 'package:client/core/analytics/events/home_events.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
import 'package:client/modules/landing/domain/welcome_motion_mode.dart';
import 'package:client/modules/landing/domain/welcome_scene_spec.dart';
import 'package:client/modules/landing/presentation/controllers/welcome_experience_controller.dart';
import 'package:client/modules/landing/presentation/widgets/welcome_page_indicator.dart';
import 'package:client/modules/landing/presentation/widgets/welcome_parallax_layer.dart';
import 'package:client/modules/landing/presentation/widgets/welcome_traveling_overlay.dart';
import 'package:client/modules/registration/presentation/screens/create_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  static const String routeName = 'Welcome';
  static const String route = '/welcome';

  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final WelcomeExperienceController _ctrl;

  static const _scenes = WelcomeSceneSpec.scenes;

  // Maps each scene index to its visual treatment.
  static const _sceneVisuals = [
    WelcomeSceneVisual.serviceCategories, // Scene 0: service chip grid
    WelcomeSceneVisual.serviceCards, // Scene 1: 4-step booking journey
    WelcomeSceneVisual.bookingJourney, // Scene 2: confirmed-booking benefits
  ];

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    final mode = AppMotionTokens.platformReducedMotion
        ? WelcomeMotionMode.staticMode
        : WelcomeMotionMode.full;
    _ctrl = WelcomeExperienceController(motionMode: mode);
    _track(const OnboardingStartedEvent(entrySource: 'app_launch'));
    _track(const OnboardingCardViewedEvent(cardKey: 'scene_0', stepNumber: 0));
    _maybeShowConsentGate();
  }

  void _maybeShowConsentGate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      dpLocator<ConsentGateService>().maybeShow(
        context,
        dpLocator<AnalyticsCoordinator>(),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Gradient stops interpolated continuously during swipe ──────────────────

  List<double> _stops() {
    final off = _ctrl.pageProgress;
    final lo = off.floor().clamp(0, _scenes.length - 1);
    final hi = off.ceil().clamp(0, _scenes.length - 1);
    if (lo == hi) return _scenes[lo].gradientStops;
    final t = off - lo;
    final a = _scenes[lo].gradientStops;
    final b = _scenes[hi].gradientStops;
    return [
      a[0] + (b[0] - a[0]) * t,
      a[1] + (b[1] - a[1]) * t,
      a[2] + (b[2] - a[2]) * t,
    ];
  }

  // ── Navigation actions ─────────────────────────────────────────────────────

  Future<void> _browseAsGuest() async {
    if (_ctrl.navigationLocked) return;
    _ctrl.lock();
    try {
      AppHaptics.medium();
      _track(OnboardingSkippedEvent(stepNumber: _ctrl.currentPage));
      await OnboardingStateService.setStatus(OnboardingStatus.skippedToBrowse);
      if (!mounted) return;
      BlocProvider.of<AuthenticationBloc>(context).add(AuthBrowseAsGuest());
      context.goNamed(HomeScreen.routeName);
    } finally {
      if (mounted) _ctrl.unlock();
    }
  }

  Future<void> _goToCreateAccount() async {
    if (_ctrl.navigationLocked) return;
    _ctrl.lock();
    try {
      AppHaptics.selection();
      _track(const OnboardingCompletedEvent());
      await OnboardingStateService.setStatus(OnboardingStatus.completed);
      if (!mounted) return;
      context.goNamed(CreateAccountScreen.routeName);
    } finally {
      if (mounted) _ctrl.unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStatic = _ctrl.motionMode.isStatic;

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final page = _ctrl.currentPage;
          final locked = _ctrl.navigationLocked;
          final stops = _stops();

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Background photos ──────────────────────────────────────
              // Each photo is wrapped in WelcomeParallaxLayer so it shifts
              // slightly against the scroll direction, creating depth.
              PageView.builder(
                controller: _ctrl.pageController,
                itemCount: _scenes.length,
                onPageChanged: (page) {
                  _ctrl.onPageChanged(page);
                  _track(OnboardingCardViewedEvent(
                    cardKey: 'scene_$page',
                    stepNumber: page,
                  ));
                },
                physics: const BouncingScrollPhysics(),
                itemBuilder: (_, i) {
                  final img = Semantics(
                    label: _scenes[i].semanticDescription,
                    image: true,
                    child: SizedBox.expand(
                      child: Image.asset(
                        _scenes[i].backgroundAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF001140)),
                      ),
                    ),
                  );
                  if (isStatic) return img;
                  return WelcomeParallaxLayer(
                    controller: _ctrl,
                    pageIndex: i,
                    parallaxFactor: 0.15,
                    verticalFactor: 0.02,
                    child: img,
                  );
                },
              ),

              // ── Gradient overlay ───────────────────────────────────────
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const [
                          Color(0x00000000),
                          Color(0x40001A66),
                          Color(0xCC001140),
                        ],
                        stops: stops,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Traveling overlay: ribbon + blue petal + service chips ─
              if (!isStatic) WelcomeTravelingOverlay(controller: _ctrl),

              // ── UI layer ───────────────────────────────────────────────
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Top bar ──────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const ServanaBanner(
                                  scale: 0.9, color: Colors.white),
                              const Spacer(),
                              // Skip → Browse Services (§70: never Sign In)
                              Semantics(
                                label: 'Skip onboarding and browse services',
                                button: true,
                                child: TextButton(
                                  onPressed: locked ? null : _browseAsGuest,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(44, 44),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                  ),
                                  child: const Text(
                                    'Skip',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Scene-specific visual (middle) ────────────────
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: isStatic
                                ? Duration.zero
                                : AppMotionTokens.emphasis,
                            switchInCurve: AppMotionTokens.enterEase,
                            switchOutCurve: AppMotionTokens.exitEase,
                            child: _SceneVisual(
                              key: ValueKey('visual_$page'),
                              visual: _sceneVisuals[page],
                              isStatic: isStatic,
                            ),
                          ),
                        ),

                        // ── Headline + subtext ────────────────────────────
                        AnimatedSwitcher(
                          duration: isStatic
                              ? Duration.zero
                              : AppMotionTokens.standard,
                          transitionBuilder: (child, animation) {
                            if (isStatic) return child;
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: AppMotionTokens.enterEase,
                              ),
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.07),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: AppMotionTokens.enterEase,
                                )),
                                child: child,
                              ),
                            );
                          },
                          child: _TextBlock(
                            key: ValueKey('text_$page'),
                            scene: _scenes[page],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Primary CTA: Browse Services ──────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Semantics(
                            label: 'Browse services without signing in',
                            child: ServanaPrimaryButton(
                              label: 'Browse Services',
                              onPressed: locked ? null : _browseAsGuest,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Secondary CTA: Create Account ─────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Semantics(
                            label: 'Create a new Servana account',
                            child: ServanaOutlinedButton(
                              label: 'Create Account',
                              darkSurface: true,
                              onPressed: locked ? null : _goToCreateAccount,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Page indicator ────────────────────────────────
                        Center(
                          child: WelcomePageIndicator(
                            controller: _ctrl,
                            pageCount: _scenes.length,
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Text block ────────────────────────────────────────────────────────────────

class _TextBlock extends StatelessWidget {
  const _TextBlock({super.key, required this.scene});
  final WelcomeSceneSpec scene;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            scene.headline,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.18,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            scene.subtext,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xCCFFFFFF),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scene visual dispatch ─────────────────────────────────────────────────────

class _SceneVisual extends StatelessWidget {
  const _SceneVisual({
    super.key,
    required this.visual,
    required this.isStatic,
  });

  final WelcomeSceneVisual visual;
  final bool isStatic;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: switch (visual) {
          WelcomeSceneVisual.serviceCategories =>
            _ServiceCategoriesVisual(isStatic: isStatic),
          WelcomeSceneVisual.serviceCards =>
            _BookingJourneyVisual(isStatic: isStatic),
          WelcomeSceneVisual.bookingJourney =>
            _BenefitsVisual(isStatic: isStatic),
        },
      ),
    );
  }
}

// ── Scene 0: service category chips ──────────────────────────────────────────

class _ServiceCategoriesVisual extends StatelessWidget {
  const _ServiceCategoriesVisual({required this.isStatic});
  final bool isStatic;

  static const _services = [
    (Icons.ac_unit_rounded, 'Aircon'),
    (Icons.cleaning_services_rounded, 'Cleaning'),
    (Icons.spa_rounded, 'Beauty'),
    (Icons.plumbing_rounded, 'Plumbing'),
    (Icons.handyman_rounded, 'Repairs'),
    (Icons.local_florist_rounded, 'Gardening'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: List.generate(_services.length, (i) {
        final chip = _ServiceChip(
            icon: _services[i].$1, label: _services[i].$2);
        if (isStatic) return chip;
        return chip
            .animate(delay: Duration(milliseconds: i * 55))
            .fadeIn(duration: 380.ms, curve: Curves.easeOut)
            .slideY(
                begin: 0.14, end: 0, duration: 340.ms, curve: Curves.easeOut);
      }),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x2BFFFFFF),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0x55FFFFFF), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scene 1: 4-step booking journey ──────────────────────────────────────────

class _BookingJourneyVisual extends StatelessWidget {
  const _BookingJourneyVisual({required this.isStatic});
  final bool isStatic;

  static const _steps = [
    (Icons.search_rounded, 'Find'),
    (Icons.calendar_month_rounded, 'Book'),
    (Icons.check_circle_outline_rounded, 'Confirm'),
    (Icons.location_on_outlined, 'Track'),
  ];

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final dotSize = narrow ? 40.0 : 52.0;
    final iconSize = narrow ? 18.0 : 22.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          _StepDot(
            icon: _steps[i].$1,
            label: _steps[i].$2,
            delay: Duration(milliseconds: i * 75),
            isStatic: isStatic,
            dotSize: dotSize,
            iconSize: iconSize,
          ),
          if (i < _steps.length - 1)
            Expanded(
              child: (() {
                final line = Container(
                  height: 1.5,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: const Color(0x55FFFFFF),
                );
                return isStatic
                    ? line
                    : line
                        .animate(delay: Duration(milliseconds: i * 75 + 110))
                        .fadeIn(duration: 280.ms);
              })(),
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.icon,
    required this.label,
    required this.delay,
    required this.isStatic,
    required this.dotSize,
    required this.iconSize,
  });

  final IconData icon;
  final String label;
  final Duration delay;
  final bool isStatic;
  final double dotSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x2BFFFFFF),
            border: Border.all(color: const Color(0x77FFFFFF), width: 1.5),
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );

    if (isStatic) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .slideY(begin: 0.12, end: 0, duration: 340.ms, curve: Curves.easeOut);
  }
}

// ── Scene 2: benefit rows ─────────────────────────────────────────────────────

class _BenefitsVisual extends StatelessWidget {
  const _BenefitsVisual({required this.isStatic});
  final bool isStatic;

  static const _benefits = [
    (Icons.verified_user_rounded, 'Verified professionals'),
    (Icons.chat_bubble_outline_rounded, 'Easy communication'),
    (Icons.shield_outlined, 'Secure payments'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _benefits.length; i++)
          _BenefitRow(
            icon: _benefits[i].$1,
            label: _benefits[i].$2,
            delay: Duration(milliseconds: i * 80),
            isStatic: isStatic,
          ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.label,
    required this.delay,
    required this.isStatic,
  });

  final IconData icon;
  final String label;
  final Duration delay;
  final bool isStatic;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x22FFFFFF),
              border: Border.all(color: const Color(0x55FFFFFF), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (isStatic) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .slideX(begin: -0.08, end: 0, duration: 340.ms, curve: Curves.easeOut);
  }
}
