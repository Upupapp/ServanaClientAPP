import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/services/app_haptics.dart';
import 'package:client/common/services/motion_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Full-screen reveal overlay for category entry.
///
/// Mount this inside a [Stack] as `Positioned.fill` on top of the category
/// screen content. It self-dismisses via [onDismiss] after the configured
/// hold duration. Supply [isFirstView] from [CategoryExperienceHistory].
///
/// The overlay never blocks back navigation — it is transparent to the
/// Navigator stack.  Tap anywhere to dismiss early (with 300 ms rapid-tap
/// protection). Reduced-motion skips all decorative animations and collapses
/// the hold to 120 ms so screen-reader users are not made to wait.
class CategoryRevealOverlay extends StatefulWidget {
  const CategoryRevealOverlay({
    super.key,
    required this.config,
    required this.isFirstView,
    required this.onDismiss,
  });

  final CategoryConfig config;
  final bool isFirstView;
  final VoidCallback onDismiss;

  @override
  State<CategoryRevealOverlay> createState() => _CategoryRevealOverlayState();
}

class _CategoryRevealOverlayState extends State<CategoryRevealOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeOut;
  bool _exiting = false;
  bool _tapProtected = true;

  @override
  void initState() {
    super.initState();
    _fadeOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    // Announce category name for assistive tech immediately after frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final label =
          widget.config.semanticAnnouncement ?? widget.config.title;
      SemanticsService.announce(label, TextDirection.ltr);
    });

    final reducedMotion = AppMotionTokens.platformReducedMotion;

    // Zero-duration config (e.g. generic repeat view) → instant dismiss.
    final holdDuration = reducedMotion
        ? const Duration(milliseconds: 120)
        : (widget.isFirstView
            ? widget.config.firstViewRevealDuration
            : widget.config.repeatViewRevealDuration);

    if (holdDuration == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDismiss();
      });
      return;
    }

    // Single restrained haptic on first-view settle only.
    if (widget.isFirstView && !reducedMotion) {
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted) AppHaptics.categoryRevealSettled();
      });
    }

    // Lift rapid-tap protection after 300 ms so deliberate taps can dismiss.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _tapProtected = false);
    });

    Future.delayed(holdDuration, _beginExit);
  }

  Future<void> _beginExit() async {
    if (!mounted || _exiting) return;
    _exiting = true;
    await _fadeOut.forward();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _fadeOut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AppMotionTokens.reducedMotion(context);

    return GestureDetector(
      onTap: _tapProtected ? null : _beginExit,
      child: AnimatedBuilder(
        animation: _fadeOut,
        builder: (context, child) => Opacity(
          opacity: _exiting ? (1.0 - _fadeOut.value) : 1.0,
          child: child,
        ),
        child: _buildContent(context, reducedMotion),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool reducedMotion) {
    final minimal = !widget.isFirstView || reducedMotion;
    return switch (widget.config.id) {
      ServiceCategoryId.beautyWellness =>
        _BeautyContent(config: widget.config, minimal: minimal),
      ServiceCategoryId.hairAndNails =>
        _HairNailsContent(config: widget.config, minimal: minimal),
      ServiceCategoryId.massage =>
        _MassageContent(config: widget.config, minimal: minimal),
      ServiceCategoryId.aircon =>
        _AirconContent(config: widget.config, minimal: minimal),
      ServiceCategoryId.generic =>
        _GenericContent(config: widget.config),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared text widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RevealHeadline extends StatelessWidget {
  const _RevealHeadline({required this.text, required this.minimal});

  final String text;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final t = Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: FontPalette.primaryFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: Colors.white,
        height: 1.15,
      ),
    );
    if (minimal) return t;
    return t
        .animate(delay: 150.ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(begin: 0.18, end: 0.0, duration: 320.ms, curve: Curves.easeOut);
  }
}

class _RevealSubtext extends StatelessWidget {
  const _RevealSubtext({required this.text, required this.minimal});

  final String text;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final t = Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: FontPalette.primaryFontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: Colors.white.withOpacity(0.82),
        height: 1.55,
      ),
    );
    if (minimal) return t;
    return t.animate(delay: 300.ms).fadeIn(duration: 380.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Beauty & Wellness — flagship reveal
// Warm radial bloom + headline + subtext on deep blue.
// ─────────────────────────────────────────────────────────────────────────────

class _BeautyContent extends StatelessWidget {
  const _BeautyContent({required this.config, required this.minimal});

  final CategoryConfig config;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.25),
          radius: 1.3,
          colors: [
            const Color(0xFF4A6EDD),
            config.primaryColor,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative glow blooms — skip on minimal.
          if (!minimal) ...[
            Positioned(
              top: size.height * 0.12,
              left: size.width * 0.08,
              child: _GlowDisk(
                color: Colors.white.withOpacity(0.10),
                size: 200,
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1.0, 1.0),
                    duration: 720.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 600.ms),
            ),
            Positioned(
              bottom: size.height * 0.22,
              right: size.width * 0.05,
              child: _GlowDisk(
                color: config.accentColor.withOpacity(0.16),
                size: 130,
              )
                  .animate(delay: 100.ms)
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                    duration: 660.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeIn(duration: 520.ms),
            ),
          ],
          // Text centred over decorative layer.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RevealHeadline(text: config.revealHeadline, minimal: minimal),
                  const SizedBox(height: 16),
                  _RevealSubtext(text: config.revealSubtext, minimal: minimal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowDisk extends StatelessWidget {
  const _GlowDisk({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hair & Nails — ribbon line sweep
// A horizontal accent line sweeps across from left, flanking the headline.
// ─────────────────────────────────────────────────────────────────────────────

class _HairNailsContent extends StatelessWidget {
  const _HairNailsContent({required this.config, required this.minimal});

  final CategoryConfig config;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.primaryColor,
            Color.lerp(config.primaryColor, Colors.black, 0.18)!,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RevealHeadline(text: config.revealHeadline, minimal: minimal),
              minimal
                  ? const SizedBox(height: 16)
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: Container(height: 1.5, color: config.accentColor)
                            .animate(delay: 180.ms)
                            .slideX(
                              begin: -1.0,
                              end: 0.0,
                              duration: 380.ms,
                              curve: Curves.easeOut,
                            )
                            .fadeIn(duration: 300.ms),
                      ),
                    ),
              _RevealSubtext(text: config.revealSubtext, minimal: minimal),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Massage — calm ripple rings
// Three concentric rings expand outward from centre and fade.
// ─────────────────────────────────────────────────────────────────────────────

class _MassageContent extends StatelessWidget {
  const _MassageContent({required this.config, required this.minimal});

  final CategoryConfig config;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            config.primaryColor,
            Color.lerp(config.primaryColor, Colors.black, 0.22)!,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple rings — skip on minimal.
          if (!minimal)
            for (int i = 0; i < 3; i++)
              _RippleRing(
                color: config.accentColor.withOpacity(0.35 - i * 0.08),
                diameter: 100.0 + i * 70.0,
                delay: Duration(milliseconds: i * 160),
              ),
          // Text on top.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RevealHeadline(text: config.revealHeadline, minimal: minimal),
                const SizedBox(height: 16),
                _RevealSubtext(text: config.revealSubtext, minimal: minimal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RippleRing extends StatelessWidget {
  const _RippleRing({
    required this.color,
    required this.diameter,
    required this.delay,
  });

  final Color color;
  final double diameter;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    )
        .animate(delay: delay)
        .scale(
          begin: const Offset(0.25, 0.25),
          end: const Offset(1.0, 1.0),
          duration: 750.ms,
          curve: Curves.easeOut,
        )
        .fadeOut(duration: 600.ms, delay: 200.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aircon — cool airflow lines
// Four horizontal lines sweep in from the left at staggered delays.
// ─────────────────────────────────────────────────────────────────────────────

class _AirconContent extends StatelessWidget {
  const _AirconContent({required this.config, required this.minimal});

  final CategoryConfig config;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.primaryColor,
            Color.lerp(config.primaryColor, const Color(0xFF2A5A8C), 0.6)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Airflow lines — skip on minimal.
          if (!minimal)
            for (int i = 0; i < 4; i++)
              Positioned(
                top: size.height * (0.33 + i * 0.055),
                left: 0,
                right: 0,
                child: Container(
                  height: 1.0,
                  color: Colors.white.withOpacity(0.18 - i * 0.03),
                )
                    .animate(delay: Duration(milliseconds: i * 85))
                    .slideX(
                      begin: -1.0,
                      end: 0.4,
                      duration: 460.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeIn(duration: 280.ms)
                    .then(delay: 80.ms)
                    .fadeOut(duration: 180.ms),
              ),
          // Text centred.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RevealHeadline(text: config.revealHeadline, minimal: minimal),
                  const SizedBox(height: 16),
                  _RevealSubtext(text: config.revealSubtext, minimal: minimal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic — safe fallback for unknown categories
// Minimal Servana blue, headline + subtext only, instant on repeat.
// ─────────────────────────────────────────────────────────────────────────────

class _GenericContent extends StatelessWidget {
  const _GenericContent({required this.config});

  final CategoryConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            config.primaryColor,
            Color.lerp(config.primaryColor, Colors.black, 0.12)!,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RevealHeadline(text: config.revealHeadline, minimal: false),
              const SizedBox(height: 16),
              _RevealSubtext(text: config.revealSubtext, minimal: false),
            ],
          ),
        ),
      ),
    );
  }
}
