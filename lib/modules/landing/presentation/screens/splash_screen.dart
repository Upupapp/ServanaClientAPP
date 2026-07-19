import 'dart:math' as math;

import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/common/services/motion_tokens.dart';
import 'package:client/common/services/onboarding_state_service.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
import 'package:client/modules/landing/presentation/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = "Splash";
  static const String route = "/splash";

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<Rect?> _v1, _v2, _v3, _v4, _v5, _v6, _v7;
  late final Animation<double> _v7Opacity;
  late final Animation<double> _blueOpacity;
  late final Animation<Rect?> _chevron;
  late final Animation<double> _chevronOpacity;

  bool _reducedMotion = false;
  bool _hasSession = false;
  bool _skipWelcome = false;
  bool _sessionCheckDone = false;
  bool _animDone = false;
  bool _navigated = false;

  // Figma "Log in" frame is 430 × 932; all rects below are in design pixels.
  static const double _designW = 430.0;
  static const double _designH = 932.0;

  // Step 0 — scattered start. Figma positions petals just barely off-frame;
  // we push them ~250 dp further along their dominant direction so the fly-in
  // reads as a longer trajectory rather than a quick edge-pop.
  // (Original Figma values are kept in the comments for reference.)
  static const Rect _v1Start = Rect.fromLTWH(-450, 214, 186, 175);   // was -189
  static const Rect _v2Start = Rect.fromLTWH(700, -100, 186, 175);   // was 432, 23
  static const Rect _v3Start = Rect.fromLTWH(60, -450, 186, 175);    // was -178
  static const Rect _v4Start = Rect.fromLTWH(700, 571, 186, 175);    // was 430
  static const Rect _v5Start = Rect.fromLTWH(115, 1250, 186, 175);   // was 933
  static const Rect _v6Start = Rect.fromLTWH(-450, 746, 186, 175);   // was -186
  static const Rect _v7Start = Rect.fromLTWH(216, 463, 4, 4);        // V7 stays


  // Step 1 — settled logo (Figma node 128:31). The seven shapes form the
  // Servana blue mark inside the 169.6 × 169.3 bbox at (130, 381).
  static const Rect _v1End = Rect.fromLTWH(130, 432.2529, 85, 90);
  static const Rect _v2End = Rect.fromLTWH(186, 381, 51.5552, 47.4109);
  static const Rect _v3End = Rect.fromLTWH(156, 404.1108, 56.3418, 54.3076);
  static const Rect _v4End = Rect.fromLTWH(217, 410, 82.2350, 85.9252);
  static const Rect _v5End = Rect.fromLTWH(220.5, 468.1943, 54.0817, 58.3057);
  static const Rect _v6End = Rect.fromLTWH(192.2952, 500.7471, 52.5, 49.2625);
  static const Rect _v7End = Rect.fromLTWH(189.5, 438, 56.4937, 54.4514);

  // logo_blue.svg / logo_orange.svg share a 24 × 33.0525 viewBox covering the
  // full Servana mark (chevron + petals). To position either piece in design
  // coordinates without distortion, render the full SVG at the petal width
  // (169.6) and let the empty portion render transparent. The blue path
  // occupies SVG-y 9.156 → 33.05, so its render top sits 64.69 dp above the
  // petal bbox top of y=381 → render top = 316.31.
  static const double _blueLogoW = 169.6101837158203;
  static const double _blueLogoH = 169.6101837158203 * 33.0525 / 24.0; // 233.55
  static const Rect _blueLogoRect = Rect.fromLTWH(130, 316.31, _blueLogoW, _blueLogoH);

  // Chevron drop — Figma nodes 154:69 (step 2, off-screen above) and 154:101
  // (step 3, settled). Chevron path occupies SVG-y 0 → 15.47, so the full SVG
  // is rendered at chevron width and the chevron top aligns with the SVG top.
  static const double _chevronW = 169.92066955566406;
  static const double _chevronH = 169.92066955566406 * 33.0525 / 24.0; // 234.04
  static const Rect _chevronStart = Rect.fromLTWH(130, -110, _chevronW, _chevronH);
  static const Rect _chevronEnd = Rect.fromLTWH(129, 312, _chevronW, _chevronH);

  // Animation timeline (2200 ms total). All interval ratios are unchanged from
  // the original Figma spec — only the total duration was shortened (was 3000ms).
  //   0    – 1100 : petals morph step 0 → step 1            (0.000 – 0.500)
  //   1100 – 1247 : settle hold (textured collage)
  //   1247 – 1430 : crossfade textured petals → flat blue   (0.567 – 0.650)
  //   1430 – 1980 : chevron drops step 2 → step 3           (0.650 – 0.900)
  //   1980 – 2200 : full-logo hold before navigating
  static const Duration _totalDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();
    _reducedMotion = AppMotionTokens.platformReducedMotion;
    _controller = AnimationController(vsync: this, duration: _totalDuration);

    final petalMorph = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.500, curve: Curves.easeOutCubic),
    );

    _v1 = RectTween(begin: _v1Start, end: _v1End).animate(petalMorph);
    _v2 = RectTween(begin: _v2Start, end: _v2End).animate(petalMorph);
    _v3 = RectTween(begin: _v3Start, end: _v3End).animate(petalMorph);
    _v4 = RectTween(begin: _v4Start, end: _v4End).animate(petalMorph);
    _v5 = RectTween(begin: _v5Start, end: _v5End).animate(petalMorph);
    _v6 = RectTween(begin: _v6Start, end: _v6End).animate(petalMorph);
    _v7 = RectTween(begin: _v7Start, end: _v7End).animate(petalMorph);

    // V7 begins invisible (Figma opacity 0) and fades in as it grows from the
    // 4×4 dot to the central diagonal box.
    _v7Opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.40, curve: Curves.easeOut),
    );

    // Solid blue logo fades over the textured petals — step 1's collage fill
    // gives way to step 2's flat #2D56CC mark before the chevron drops.
    _blueOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.567, 0.650, curve: Curves.easeInOut),
    );

    final chevronDrop = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.650, 0.900, curve: Curves.easeInCubic),
    );
    _chevron = RectTween(begin: _chevronStart, end: _chevronEnd)
        .animate(chevronDrop);
    // Quick fade-in at the start of the drop so the chevron doesn't pop in
    // mid-flight on devices where the off-screen portion is visible.
    _chevronOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.650, 0.700, curve: Curves.easeOut),
    );

    if (_reducedMotion) {
      // Snap to the fully assembled logo immediately — no petal fly-in, no
      // chevron drop. Reduced-motion users still see the brand mark for a
      // brief moment before navigating (COMMAND 04 §5).
      _controller.value = 1.0;
      Future.delayed(AppMotionTokens.splashReduced, () {
        if (mounted) {
          _animDone = true;
          _maybeNavigate();
        }
      });
    } else {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animDone = true;
          _maybeNavigate();
        }
      });
      _controller.forward();
    }

    // Sync the AuthenticationBloc state after the first frame so widgets that
    // listen to BLoC state see AuthenticationAuthenticated / AuthenticationGuest
    // rather than the initial AuthenticationUninitialized on cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        BlocProvider.of<AuthenticationBloc>(context).add(AuthCheckSession());
      }
    });

    _checkSession();
  }

  Future<void> _checkSession() async {
    bool hasSession = false;
    bool skipWelcome = false;
    try {
      final session = await SessionService.getSession();
      hasSession = session != null;
      if (!hasSession) {
        // Returning guests who already completed onboarding skip the welcome
        // flow and land directly on the guest home feed (COMMAND 04 §3).
        skipWelcome = await OnboardingStateService.hasCompletedOrSkipped();
      }
    } catch (_) {
      // Hive / encryption / plugin init failure — fall through to Welcome.
    }
    if (!mounted) return;
    // Inform the router guard of the auth status so protected routes can
    // redirect correctly even before the BLoC's AuthCheckSession is fired.
    dpLocator<AuthStateService>().update(
      hasSession ? AuthStatus.authenticated : AuthStatus.guest,
    );
    _hasSession = hasSession;
    _skipWelcome = skipWelcome;
    _sessionCheckDone = true;
    _maybeNavigate();
  }

  void _maybeNavigate() {
    if (_navigated || !_sessionCheckDone || !_animDone) return;
    _navigated = true;
    if (_hasSession || _skipWelcome) {
      // Authenticated users → home feed.
      // Returning guests who already saw onboarding → home feed as guest.
      context.goNamed(HomeScreen.routeName);
    } else {
      context.goNamed(WelcomeScreen.routeName);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Scale the 430×932 design canvas to fit the device. `min` of both
          // axes keeps the canvas inside the viewport on every aspect — phones
          // (taller than 9:19.5) hit the width axis as before, while older
          // 16:9 phones, tablets, and Flutter web hit the height axis and get
          // a clean letterbox instead of clipping the bottom of the canvas.
          final scale = math.min(
            constraints.maxWidth / _designW,
            constraints.maxHeight / _designH,
          );
          return Center(
            child: ClipRect(
              child: SizedBox(
                width: _designW * scale,
                height: _designH * scale,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        _vector('vector_1.png', _v1.value!, scale, 1.0),
                        _vector('vector_2.png', _v2.value!, scale, 1.0),
                        _vector('vector_3.png', _v3.value!, scale, 1.0),
                        _vector('vector_4.png', _v4.value!, scale, 1.0),
                        _vector('vector_5.png', _v5.value!, scale, 1.0),
                        _vector('vector_6.png', _v6.value!, scale, 1.0),
                        _vector(
                          'vector_7.png',
                          _v7.value!,
                          scale,
                          _v7Opacity.value,
                        ),
                        if (_blueOpacity.value > 0) _buildBlueLogo(scale),
                        if (_chevronOpacity.value > 0) _buildChevron(scale),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _vector(String asset, Rect rect, double scale, double opacity) {
    return Positioned(
      left: rect.left * scale,
      top: rect.top * scale,
      width: rect.width * scale,
      height: rect.height * scale,
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          'assets/images/splash/$asset',
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Widget _buildBlueLogo(double scale) {
    return Positioned(
      left: _blueLogoRect.left * scale,
      top: _blueLogoRect.top * scale,
      width: _blueLogoRect.width * scale,
      height: _blueLogoRect.height * scale,
      child: Opacity(
        opacity: _blueOpacity.value,
        child: SvgPicture.asset(
          'assets/images/splash/logo_blue.svg',
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Widget _buildChevron(double scale) {
    final rect = _chevron.value!;
    return Positioned(
      left: rect.left * scale,
      top: rect.top * scale,
      width: rect.width * scale,
      height: rect.height * scale,
      child: Opacity(
        opacity: _chevronOpacity.value,
        child: SvgPicture.asset(
          'assets/images/splash/logo_orange.svg',
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
