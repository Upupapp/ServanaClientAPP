import 'dart:async';
import 'dart:math' as math;

import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/app_haptics.dart';
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
  static const String routeName = 'Splash';
  static const String route = '/splash';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _portalController;
  late final Animation<double> _portalProgress;

  bool _reducedMotion = false;
  bool _hasSession = false;
  bool _skipWelcome = false;
  bool _sessionCheckDone = false;
  bool _logoDone = false;
  bool _portalDone = false;
  bool _navigated = false;
  bool _showPortal = false;
  bool _chevronHapticFired = false;

  // Animation timeline (2200 ms total):
  //   0.000 – 0.500 : petals fly in from off-screen and assemble  (easeOutCubic)
  //   0.100 – 0.400 : v7 central diagonal fades in                (easeOut)
  //   0.567 – 0.650 : textured petals cross-fade to flat blue     (easeInOut)
  //   0.650 – 0.900 : chevron drops in from above                 (easeInCubic)
  //   0.650 – 0.700 : chevron opacity fade-in                     (easeOut)
  static const Duration _totalDuration = AppMotionTokens.splashFull;

  @override
  void initState() {
    super.initState();
    _reducedMotion = AppMotionTokens.platformReducedMotion;

    _controller = AnimationController(vsync: this, duration: _totalDuration);
    _portalController = AnimationController(
      vsync: this,
      duration: AppMotionTokens.splashPortal,
    );
    _portalProgress = CurvedAnimation(
      parent: _portalController,
      curve: Curves.easeInCubic,
    );

    _portalController.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _portalDone = true;
        _maybeNavigate();
      }
    });

    if (_reducedMotion) {
      _controller.value = 1.0;
      Future.delayed(AppMotionTokens.splashReduced, () {
        if (mounted) {
          _logoDone = true;
          _maybeNavigate();
        }
      });
    } else {
      _controller.addListener(_onAnimProgress);
      _controller.addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _logoDone = true;
          _maybeNavigate();
        }
      });
      _controller.forward();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        BlocProvider.of<AuthenticationBloc>(context).add(AuthCheckSession());
      }
    });
    _checkSession();
  }

  // Fire a light haptic exactly once when the chevron locks in at t=0.900.
  void _onAnimProgress() {
    if (!_chevronHapticFired && _controller.value >= 0.900) {
      _chevronHapticFired = true;
      AppHaptics.light();
    }
  }

  /// The splash must always resolve, even when the work behind it does not.
  ///
  /// `_maybeNavigate` is gated on `_sessionCheckDone`. Reading the session goes
  /// through the Android keystore via a platform channel, and an unbounded
  /// `await` on a wedged channel never throws — so the `catch` below cannot
  /// help, the flag never flips, and the app sits on this screen indefinitely
  /// with no error and no way forward. Observed on a clean emulator: the
  /// session check never completed and not one network request was issued.
  ///
  /// A timeout converts an indefinite hang into a normal guest start. Being
  /// wrongly treated as signed-out is recoverable in one tap; an app that never
  /// opens is not.
  static const Duration _sessionCheckBudget = Duration(seconds: 6);

  Future<void> _checkSession() async {
    bool hasSession = false;
    bool skipWelcome = false;
    try {
      final session =
          await SessionService.getSession().timeout(_sessionCheckBudget);
      hasSession = session != null;
      if (!hasSession) {
        skipWelcome = await OnboardingStateService.hasCompletedOrSkipped()
            .timeout(_sessionCheckBudget);
      }
    } catch (_) {
      // Includes TimeoutException. Falling through to the guest path is the
      // point: the screen resolves either way.
    }
    if (!mounted) return;
    dpLocator<AuthStateService>().update(
      hasSession ? AuthStatus.authenticated : AuthStatus.guest,
    );
    _hasSession = hasSession;
    _skipWelcome = skipWelcome;
    _sessionCheckDone = true;
    _maybeNavigate();
  }

  void _maybeNavigate() {
    if (_navigated || !_sessionCheckDone || !_logoDone) return;

    if (_hasSession || _skipWelcome) {
      // Authenticated or returning guest → skip welcome, go home.
      _navigated = true;
      if (mounted) context.goNamed(HomeScreen.routeName);
      return;
    }

    // First-launch path: open portal then navigate to WelcomeScreen.
    if (!_reducedMotion) {
      if (!_showPortal && mounted) {
        setState(() => _showPortal = true);
        _portalController.forward();
      }
      if (!_portalDone) return;
    }

    _navigated = true;
    if (mounted) context.goNamed(WelcomeScreen.routeName);
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimProgress);
    _controller.dispose();
    _portalController.dispose();
    super.dispose();
  }

  // ── Animation math helpers ──────────────────────────────────────────────────

  // Evaluate a curve over the sub-interval [t0, t1] of [0, 1].
  static double _it(double p, double t0, double t1, Curve c) =>
      c.transform(((p - t0) / (t1 - t0)).clamp(0.0, 1.0));

  static Rect _lerpRect(Rect a, Rect b, double t) => Rect.fromLTWH(
        a.left + (b.left - a.left) * t,
        a.top + (b.top - a.top) * t,
        a.width + (b.width - a.width) * t,
        a.height + (b.height - a.height) * t,
      );

  // ── Responsive rect helpers ─────────────────────────────────────────────────

  // End rect: center = logoCenter + (dx*lh, dy*lh), size = (w*ls, h*ls).
  // dx, dy are fractions of logoHalf; w, h are fractions of logoSize (=2*lh).
  static Rect _endRect(double lcx, double lcy, double lh, double dx, double dy,
      double w, double h) {
    final ls = lh * 2;
    return Rect.fromCenter(
      center: Offset(lcx + dx * lh, lcy + dy * lh),
      width: w * ls,
      height: h * ls,
    );
  }

  // Start rect: center = (fx*sw, fy*sh), size = (ws*ls, hs*ls).
  static Rect _startRect(double sw, double sh, double ls, double fx, double fy,
      double ws, double hs) {
    return Rect.fromCenter(
      center: Offset(fx * sw, fy * sh),
      width: ws * ls,
      height: hs * ls,
    );
  }

  // ── Petal normalized data ───────────────────────────────────────────────────
  //
  // _petalEnd: [dx, dy, w, h]
  //   dx, dy — center offset from logoCenter as fraction of logoHalf
  //   w,  h  — petal size as fraction of logoSize (= logoHalf × 2)
  //   Derived from Figma "Log in" node 128:31, canvas 430×932,
  //   logo bbox 169.6×169.3 at (130, 381), center (214.8, 465.65).
  //
  // _petalStartCenter: [fx, fy]
  //   Center of the start position as fraction of (screenWidth, screenHeight).
  //   Values < 0 or > 1 place the petal off-screen in that axis.
  //
  // _petalStartSize: [ws, hs]
  //   Start size as fraction of logoSize.
  //   v1–v6: ≈1.0 (full design petal size 186×175 / 169.6).
  //   v7: 0.047 (starts as a nearly-invisible 4 × 4 dp dot at logo center).

  static const _petalEnd = [
    [-0.499, 0.137, 0.501, 0.531], // v1: lower-left large petal
    [-0.036, -0.719, 0.304, 0.280], // v2: upper-center small
    [-0.361, -0.406, 0.332, 0.320], // v3: upper-left small
    [0.511, -0.150, 0.485, 0.507], // v4: right large
    [0.386, 0.374, 0.319, 0.344], // v5: lower-right medium
    [0.044, 0.705, 0.310, 0.291], // v6: lower-center medium
    [0.035, -0.005, 0.333, 0.321], // v7: central diagonal (near center)
  ];

  static const _petalStartCenter = [
    [-0.830, 0.323], // v1: far off-screen left
    [1.844, -0.013], // v2: far off-screen right-top
    [0.356, -0.389], // v3: off-screen top
    [1.844, 0.707], // v4: far off-screen right-bottom
    [0.484, 1.435], // v5: off-screen bottom
    [-0.830, 0.894], // v6: far off-screen left-bottom
    [0.500, 0.500], // v7: screen center (grows from dot)
  ];

  static const _petalStartSize = [
    [1.097, 1.032], // v1: 186×175 / 169.6
    [1.097, 1.032], // v2
    [1.097, 1.032], // v3
    [1.097, 1.032], // v4
    [1.097, 1.032], // v5
    [1.097, 1.032], // v6
    [0.047, 0.047], // v7: 4 × 4 dp dot / 169.6
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (_, cst) {
          final sw = cst.maxWidth;
          final sh = cst.maxHeight;
          // logoHalf = half the logo diameter, proportional to shortest screen edge.
          // At 430 × 932 (Figma canvas) this matches the original 84.8 dp exactly.
          final lh = math.min(sw, sh) * 0.197;
          final ls = lh * 2; // logoSize
          final lcx = sw * 0.50; // logo center x
          final lcy = sh * 0.50; // logo center y

          return AnimatedBuilder(
            animation: Listenable.merge([_controller, _portalController]),
            builder: (_, __) {
              final p = _controller.value;

              final petalT = _it(p, 0.000, 0.500, Curves.easeOutCubic);
              final v7OpT = _it(p, 0.100, 0.400, Curves.easeOut);
              final blueT = _it(p, 0.567, 0.650, Curves.easeInOut);
              final chevronT = _it(p, 0.650, 0.900, Curves.easeInCubic);
              final chevronOpT = _it(p, 0.650, 0.700, Curves.easeOut);

              // Petal interpolated rects.
              final petalRects = List<Rect>.generate(7, (i) {
                final end = _endRect(lcx, lcy, lh, _petalEnd[i][0],
                    _petalEnd[i][1], _petalEnd[i][2], _petalEnd[i][3]);
                final start = _startRect(
                    sw,
                    sh,
                    ls,
                    _petalStartCenter[i][0],
                    _petalStartCenter[i][1],
                    _petalStartSize[i][0],
                    _petalStartSize[i][1]);
                return _lerpRect(start, end, petalT);
              });

              // Blue logo: full SVG width, taller due to 24 × 33.05 viewBox.
              final blueLogo =
                  Rect.fromLTWH(lcx - lh, lcy - 1.761 * lh, ls, lh * 2.754);

              // Chevron SVG shares the same viewBox dimensions as the blue logo.
              final chevronEnd =
                  Rect.fromLTWH(lcx - lh, lcy - 1.812 * lh, ls, lh * 2.754);
              // Start well above the screen so the drop reads as a long fall.
              final chevronStart = Rect.fromLTWH(
                  lcx - lh, lcy - 1.812 * lh - sh * 0.55, ls, lh * 2.754);
              final chevronRect = _lerpRect(chevronStart, chevronEnd, chevronT);

              // Portal radius: expands from logo center to the farthest screen corner.
              final portalRadius = _showPortal
                  ? [
                        math.sqrt(lcx * lcx + lcy * lcy),
                        math.sqrt((sw - lcx) * (sw - lcx) + lcy * lcy),
                        math.sqrt(lcx * lcx + (sh - lcy) * (sh - lcy)),
                        math.sqrt(
                            (sw - lcx) * (sw - lcx) + (sh - lcy) * (sh - lcy)),
                      ].reduce(math.max) *
                      1.05 *
                      _portalProgress.value
                  : 0.0;

              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  // ── Portal: Scene 1 background expands from logo center ──────
                  if (_showPortal && portalRadius > 0)
                    ExcludeSemantics(
                      child: ClipOval(
                        clipper: _CircleClipper(
                          center: Offset(lcx, lcy),
                          radius: portalRadius,
                        ),
                        child: const SizedBox.expand(
                          child: Image(
                            image: AssetImage(
                                'assets/images/welcome/page_1_bg.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  // ── Petals v1–v7 ────────────────────────────────────────────
                  for (var i = 0; i < 7; i++)
                    Positioned(
                      left: petalRects[i].left,
                      top: petalRects[i].top,
                      width: petalRects[i].width,
                      height: petalRects[i].height,
                      child: ExcludeSemantics(
                        child: Opacity(
                          opacity: i == 6 ? v7OpT : 1.0,
                          child: Image.asset(
                            'assets/images/splash/vector_${i + 1}.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),

                  // ── Flat blue logo overlay (crossfade over textured petals) ──
                  if (blueT > 0)
                    Positioned(
                      left: blueLogo.left,
                      top: blueLogo.top,
                      width: blueLogo.width,
                      height: blueLogo.height,
                      child: ExcludeSemantics(
                        child: Opacity(
                          opacity: blueT,
                          child: SvgPicture.asset(
                            'assets/images/splash/logo_blue.svg',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),

                  // ── Orange chevron (drops from above after petals settle) ────
                  if (chevronOpT > 0)
                    Positioned(
                      left: chevronRect.left,
                      top: chevronRect.top,
                      width: chevronRect.width,
                      height: chevronRect.height,
                      child: ExcludeSemantics(
                        child: Opacity(
                          opacity: chevronOpT,
                          child: SvgPicture.asset(
                            'assets/images/splash/logo_orange.svg',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Circle clip ───────────────────────────────────────────────────────────────

/// Clips to a circle of [radius] centered at [center].
/// Used by the portal transition to reveal the welcome background.
class _CircleClipper extends CustomClipper<Rect> {
  const _CircleClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Rect getClip(Size size) => Rect.fromCircle(center: center, radius: radius);

  @override
  bool shouldReclip(_CircleClipper old) =>
      old.center != center || old.radius != radius;
}
