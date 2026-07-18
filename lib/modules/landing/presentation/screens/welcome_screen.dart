import 'dart:math' as math;

import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/widgets/servana_banner.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_event.dart';
import 'package:client/modules/authentication/presentation/screens/authentication_screen.dart';
import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  static const String routeName = "Welcome";
  static const String route = "/welcome";

  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
  int _index = 0;

  // Figma frames are 430×932; everything below is in design pixels and gets
  // scaled by `constraints.maxWidth / _designW` at build-time.
  static const double _designW = 430;
  static const double _designH = 932;

  // Bg photos are exported from Figma pre-cropped to the 430:932 frame aspect
  // (860×1864 px, 2×), so they fill the design canvas directly with no
  // imageTransform maths needed on our side.
  static const _pages = <_PageSpec>[
    _PageSpec(
      bg: 'assets/images/welcome/page_1_bg.png',
      gradientStops: [0.058, 0.607, 0.738],
      headline: 'Your Gateway to Every Service You Need.',
      subtext:
          'Book trusted professionals for repairs, cleaning—all in one convenient app.',
    ),
    _PageSpec(
      bg: 'assets/images/welcome/page_2_bg.png',
      gradientStops: [0.058, 0.552, 0.854],
      headline: 'Simplify Your Life with On-Demand Services',
      subtext:
          'Discover, book, and manage home services with ease, anytime and anywhere.',
    ),
    _PageSpec(
      bg: 'assets/images/welcome/page_3_bg.png',
      gradientStops: [0.058, 0.552, 0.854],
      headline: 'Everything You Need, One Tap Away.',
      subtext:
          'Connect with trusted service providers and book jobs quickly, all in one place.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToAuth() => context.goNamed(AuthenticationScreen.routeName);

  /// Skip the onboarding and browse as a guest — goes straight to the home
  /// feed without requiring a sign-in.
  void _browseAsGuest() {
    BlocProvider.of<AuthenticationBloc>(context).add(AuthBrowseAsGuest());
    context.goNamed(HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // `min` of both axes — see splash_screen for the rationale. Keeps
          // the design canvas inside every viewport (phones, tablets, web)
          // and letterboxes whichever axis has excess space.
          final scale = math.min(
            constraints.maxWidth / _designW,
            constraints.maxHeight / _designH,
          );
          return Center(
            child: ClipRect(
              child: SizedBox(
                width: _designW * scale,
                height: _designH * scale,
                child: Stack(
                  children: [
                    // Pager owns bg + gradient + headline + subtext per page.
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) =>
                          _PageContent(spec: _pages[i], scale: scale),
                    ),
                    // Persistent overlays — banner / skip / button / dots
                    // stay put while pages slide underneath, matching the
                    // Figma intent (each frame draws them at the same coords).
                    Positioned(
                      left: 26 * scale,
                      top: 70 * scale,
                      child: ServanaBanner(scale: scale),
                    ),
                    Positioned(
                      top: 17 * scale,
                      right: 26 * scale,
                      child: GestureDetector(
                        onTap: _browseAsGuest,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * scale,
                            vertical: 4 * scale,
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF99A1AF),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Get Started — Figma `Rectangle 146` at design (29, 762,
                    // 372, 54) with 1 dp #8CA0FF stroke and 20 dp radius.
                    Positioned(
                      left: 29 * scale,
                      top: 762 * scale,
                      width: 372 * scale,
                      height: 54 * scale,
                      child: ElevatedButton(
                        onPressed: _goToAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F44F2),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20 * scale),
                            side: const BorderSide(
                              color: Color(0xFF8CA0FF),
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.w600,
                            height: 22.4 / 20.0,
                          ),
                        ),
                      ),
                    ),
                    // Page dots — Figma `Paee Pointers` at ~design (178, 842).
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 842 * scale,
                      child: Center(
                        child: _PageDots(
                          count: _pages.length,
                          currentIndex: _index,
                          scale: scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PageSpec {
  const _PageSpec({
    required this.bg,
    required this.gradientStops,
    required this.headline,
    required this.subtext,
  });

  /// Bg photo, pre-cropped in Figma to the 430:932 frame aspect.
  final String bg;

  /// Three stops for the brand gradient overlay. Colours are constant
  /// (orange/navy/deep-navy with pre-multiplied 0.6 frame opacity); only the
  /// stop positions vary per page.
  final List<double> gradientStops;

  final String headline;
  final String subtext;
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.spec, required this.scale});

  final _PageSpec spec;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Bg photo fills the canvas — Figma already applied the crop on
        // export, so no FractionallySizedBox / Positioned offset needed.
        Positioned.fill(
          child: Image.asset(spec.bg, fit: BoxFit.cover),
        ),
        // Brand gradient overlay (Figma frame fill #2). Alpha is pre-mixed:
        // each stop's Figma opacity × 0.6 frame opacity → 0x3D / 0x7A / 0x99.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Color(0x3DF99343),
                  Color(0x7A001A66),
                  Color(0x99001140),
                ],
                stops: spec.gradientStops,
              ),
            ),
          ),
        ),
        // Headline — `Frame 1321316836` at design (29, 521, 371, 165). The
        // text bounds carry a y=-14 offset in Figma (the descender extends
        // above the frame), and Figma anchors text to the bottom of the box,
        // so we wrap in a bottom-aligned container.
        Positioned(
          left: 35.5 * scale,
          top: 507 * scale,
          width: 299 * scale,
          height: 175 * scale,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              spec.headline,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 40 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 55.0 / 40.0,
                letterSpacing: -1.6, // Figma -4% × 40 px
              ),
            ),
          ),
        ),
        // Subtext — `Frame 1321316840` at design (29, 686, 371, 149).
        Positioned(
          left: 36 * scale,
          top: 686 * scale,
          width: 357 * scale,
          height: 149 * scale,
          child: Text(
            spec.subtext,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 16 * scale,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 26.0 / 16.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.currentIndex,
    required this.scale,
  });

  final int count;
  final int currentIndex;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(horizontal: 3 * scale),
          width: (isActive ? 37 : 12) * scale,
          height: 6 * scale,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1F44F2)
                : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(
              (isActive ? 9 : 15) * scale,
            ),
          ),
        );
      }),
    );
  }
}
