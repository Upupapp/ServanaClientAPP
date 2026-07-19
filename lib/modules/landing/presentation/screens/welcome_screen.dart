import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/widgets/servana_banner.dart';
import 'package:client/common/presentation/widgets/servana_primary_button.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/common/services/motion_tokens.dart';
import 'package:client/common/services/onboarding_state_service.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:client/modules/authentication/presentation/screens/authentication_screen.dart';
import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
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
  final _pageController = PageController();
  int _index = 0;

  static const _pages = <_WelcomePage>[
    _WelcomePage(
      bg: 'assets/images/welcome/page_1_bg.png',
      gradientStops: [0.058, 0.607, 0.738],
      headline: 'Every service\nyou need.',
      subtext:
          'Discover and book trusted home and personal services, whenever you need them.',
      semanticLabel: 'Page 1 of 3: Discover Servana services',
      visual: _WelcomeVisual.serviceCategories,
    ),
    _WelcomePage(
      bg: 'assets/images/welcome/page_2_bg.png',
      gradientStops: [0.058, 0.552, 0.854],
      headline: 'Find the right\nservice, fast.',
      subtext:
          'Aircon care, beauty and wellness, cleaning, plumbing, repairs — all on Servana.',
      semanticLabel: 'Page 2 of 3: Browse service categories',
      visual: _WelcomeVisual.bookingJourney,
    ),
    _WelcomePage(
      bg: 'assets/images/welcome/page_3_bg.png',
      gradientStops: [0.058, 0.552, 0.854],
      headline: 'Simple booking.\nClear updates.',
      subtext:
          'Choose your schedule, confirm your booking, and track your provider in real time.',
      semanticLabel: 'Page 3 of 3: How booking works',
      visual: _WelcomeVisual.benefits,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    AppHaptics.selection();
    setState(() => _index = i);
  }

  Future<void> _browseAsGuest() async {
    AppHaptics.medium();
    await OnboardingStateService.setStatus(OnboardingStatus.skippedToBrowse);
    if (!mounted) return;
    BlocProvider.of<AuthenticationBloc>(context).add(AuthBrowseAsGuest());
    context.goNamed(HomeScreen.routeName);
  }

  Future<void> _goToSignIn() async {
    AppHaptics.selection();
    await OnboardingStateService.setStatus(OnboardingStatus.completed);
    if (!mounted) return;
    context.goNamed(AuthenticationScreen.routeName);
  }

  Future<void> _goToCreateAccount() async {
    AppHaptics.selection();
    await OnboardingStateService.setStatus(OnboardingStatus.completed);
    if (!mounted) return;
    context.goNamed(AuthenticationScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AppMotionTokens.reducedMotion(context);
    final page = _pages[_index];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Sliding background photos ──────────────────────────────────
          // Photos provide the mood; they slide on horizontal swipe while the
          // gradient overlay and UI content stay fixed.
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, i) => Semantics(
              label: _pages[i].semanticLabel,
              image: true,
              child: Image.asset(
                _pages[i].bg,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF001140)),
              ),
            ),
          ),

          // ── Gradient overlay ───────────────────────────────────────────
          // Bottom-heavy navy gradient ensures white text is always legible
          // regardless of the background photo's content.
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
                    stops: page.gradientStops,
                  ),
                ),
              ),
            ),
          ),

          // ── UI content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ServanaBanner(scale: 0.9, color: Colors.white),
                      const Spacer(),
                      Semantics(
                        label: 'Sign in to your account',
                        button: true,
                        child: TextButton(
                          onPressed: _goToSignIn,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(44, 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
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

                // ── Service visual (middle) ───────────────────────────────
                Expanded(
                  child: AnimatedSwitcher(
                    duration: reducedMotion
                        ? Duration.zero
                        : AppMotionTokens.emphasis,
                    switchInCurve: AppMotionTokens.enterEase,
                    switchOutCurve: AppMotionTokens.exitEase,
                    child: _ServiceVisual(
                      key: ValueKey('visual_$_index'),
                      visual: page.visual,
                      reducedMotion: reducedMotion,
                    ),
                  ),
                ),

                // ── Headline + subtext ───────────────────────────────────
                AnimatedSwitcher(
                  duration: reducedMotion
                      ? Duration.zero
                      : AppMotionTokens.standard,
                  transitionBuilder: (child, animation) {
                    if (reducedMotion) return child;
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
                  child: _PageTextBlock(
                    key: ValueKey('text_$_index'),
                    page: page,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Primary CTA: Browse Services ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Semantics(
                    label: 'Browse services without signing in',
                    button: true,
                    child: ServanaPrimaryButton(
                      label: 'Browse Services',
                      onPressed: _browseAsGuest,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Secondary CTA: Create Account ────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Semantics(
                    label: 'Create a new Servana account',
                    button: true,
                    child: ServanaOutlinedButton(
                      label: 'Create Account',
                      darkSurface: true,
                      onPressed: _goToCreateAccount,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Page indicator ───────────────────────────────────────
                Semantics(
                  label: 'Page ${_index + 1} of ${_pages.length}',
                  child: Center(
                    child: _PageIndicator(
                      count: _pages.length,
                      currentIndex: _index,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────

class _WelcomePage {
  final String bg;
  final List<double> gradientStops;
  final String headline;
  final String subtext;
  final String semanticLabel;
  final _WelcomeVisual visual;

  const _WelcomePage({
    required this.bg,
    required this.gradientStops,
    required this.headline,
    required this.subtext,
    required this.semanticLabel,
    required this.visual,
  });
}

enum _WelcomeVisual { serviceCategories, bookingJourney, benefits }

// ── Text block ────────────────────────────────────────────────────────────────

class _PageTextBlock extends StatelessWidget {
  const _PageTextBlock({super.key, required this.page});
  final _WelcomePage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            page.headline,
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
            page.subtext,
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

// ── Service visuals ───────────────────────────────────────────────────────────

class _ServiceVisual extends StatelessWidget {
  const _ServiceVisual({
    super.key,
    required this.visual,
    required this.reducedMotion,
  });

  final _WelcomeVisual visual;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: switch (visual) {
          _WelcomeVisual.serviceCategories =>
            _ServiceCategoriesVisual(reducedMotion: reducedMotion),
          _WelcomeVisual.bookingJourney =>
            _BookingJourneyVisual(reducedMotion: reducedMotion),
          _WelcomeVisual.benefits =>
            _BenefitsVisual(reducedMotion: reducedMotion),
        },
      ),
    );
  }
}

// Page 1 — Service category chips
class _ServiceCategoriesVisual extends StatelessWidget {
  const _ServiceCategoriesVisual({required this.reducedMotion});
  final bool reducedMotion;

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
      children: [
        for (var i = 0; i < _services.length; i++)
          reducedMotion
              ? _ServiceChip(
                  icon: _services[i].$1,
                  label: _services[i].$2,
                )
              : _ServiceChip(
                  icon: _services[i].$1,
                  label: _services[i].$2,
                )
                  .animate(
                    delay: Duration(milliseconds: i * 55),
                  )
                  .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.14, end: 0, duration: 340.ms, curve: Curves.easeOut),
      ],
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

// Page 2 — 4-step booking journey
class _BookingJourneyVisual extends StatelessWidget {
  const _BookingJourneyVisual({required this.reducedMotion});
  final bool reducedMotion;

  static const _steps = [
    (Icons.search_rounded, 'Find'),
    (Icons.calendar_month_rounded, 'Book'),
    (Icons.check_circle_outline_rounded, 'Confirm'),
    (Icons.location_on_outlined, 'Track'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          _StepDot(
            icon: _steps[i].$1,
            label: _steps[i].$2,
            delay: Duration(milliseconds: i * 75),
            reducedMotion: reducedMotion,
          ),
          if (i < _steps.length - 1)
            Expanded(
              child: reducedMotion
                  ? Container(
                      height: 1.5,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: const Color(0x55FFFFFF),
                    )
                  : Container(
                      height: 1.5,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: const Color(0x55FFFFFF),
                    )
                      .animate(
                        delay: Duration(milliseconds: i * 75 + 110),
                      )
                      .fadeIn(duration: 280.ms),
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
    required this.reducedMotion,
  });

  final IconData icon;
  final String label;
  final Duration delay;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x2BFFFFFF),
            border: Border.all(color: const Color(0x77FFFFFF), width: 1.5),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
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

    if (reducedMotion) return child;

    return child
        .animate(delay: delay)
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .slideY(begin: 0.12, end: 0, duration: 340.ms, curve: Curves.easeOut);
  }
}

// Page 3 — Benefit highlights
class _BenefitsVisual extends StatelessWidget {
  const _BenefitsVisual({required this.reducedMotion});
  final bool reducedMotion;

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
            reducedMotion: reducedMotion,
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
    required this.reducedMotion,
  });

  final IconData icon;
  final String label;
  final Duration delay;
  final bool reducedMotion;

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

    if (reducedMotion) return child;

    return child
        .animate(delay: delay)
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .slideX(begin: -0.08, end: 0, duration: 340.ms, curve: Curves.easeOut);
  }
}

// ── Page indicator ────────────────────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 28.0 : 8.0,
          height: 6.0,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : const Color(0x66FFFFFF),
            borderRadius: BorderRadius.circular(isActive ? 4.0 : 8.0),
          ),
        );
      }),
    );
  }
}
