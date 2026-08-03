import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/events/booking_events.dart';
import 'package:client/modules/categories/domain/category_experience.dart';
import 'package:client/modules/categories/domain/category_reveal_policy.dart';
import 'package:flutter/material.dart';

class CategoryRevealOverlay extends StatefulWidget {
  final CategoryPresentationConfig config;
  final RevealDecision decision;
  final VoidCallback onDismiss;

  const CategoryRevealOverlay({
    super.key,
    required this.config,
    required this.decision,
    required this.onDismiss,
  });

  @override
  State<CategoryRevealOverlay> createState() => _CategoryRevealOverlayState();
}

class _CategoryRevealOverlayState extends State<CategoryRevealOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _scaleCtrl;
  late final AnimationController _decorCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _decor;

  bool _tapProtected = true;

  bool get _reduced => widget.decision == RevealDecision.reducedReveal;

  @override
  void initState() {
    super.initState();
    final dur = _reduced
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 600);
    final decorDur =
        _reduced ? Duration.zero : const Duration(milliseconds: 1200);

    _fadeCtrl = AnimationController(vsync: this, duration: dur);
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _decorCtrl = AnimationController(vsync: this, duration: decorDur);

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutCubic),
    );
    _decor = CurvedAnimation(parent: _decorCtrl, curve: Curves.easeInOut);

    _fadeCtrl.forward();
    if (!_reduced) {
      _scaleCtrl.forward();
      Future.delayed(
          const Duration(milliseconds: 200), () => _decorCtrl.forward());
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _tapProtected = false);
    });

    _track(
        CategoryRevealShownEvent(categoryKey: widget.config.categoryId.name));
  }

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _decorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.config.theme.primaryAccent;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        widget.config.theme.heroGradientStart,
        widget.config.theme.heroGradientEnd,
      ],
    );

    return Semantics(
      label: widget.config.semanticAnnouncement ?? widget.config.revealHeadline,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tapProtected ? null : widget.onDismiss,
          child: Material(
            color: Colors.black.withOpacity(0.72),
            child: SafeArea(
              child: Center(
                child: _reduced
                    ? _buildCard(gradient, accent)
                    : ScaleTransition(
                        scale: _scale,
                        child: _buildCard(gradient, accent),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(LinearGradient gradient, Color accent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.32),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (!_reduced)
              _CategoryDecoration(config: widget.config, progress: _decor),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    widget.config.revealHeadline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.config.revealSubtext,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _DismissButton(
                    onDismiss: widget.onDismiss,
                    tapProtected: _tapProtected,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  final VoidCallback onDismiss;
  final bool tapProtected;
  const _DismissButton({required this.onDismiss, required this.tapProtected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: tapProtected ? null : onDismiss,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.18),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Explore now',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

class _CategoryDecoration extends StatelessWidget {
  final CategoryPresentationConfig config;
  final Animation<double> progress;

  const _CategoryDecoration({required this.config, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, __) => CustomPaint(
        painter: _DecorationPainter(
          categoryId: config.categoryId,
          accent: config.theme.secondaryAccent,
          progress: progress.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DecorationPainter extends CustomPainter {
  final dynamic categoryId;
  final Color accent;
  final double progress;

  _DecorationPainter({
    required this.categoryId,
    required this.accent,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withOpacity(0.12 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw concentric arcs that grow with progress
    for (var i = 0; i < 3; i++) {
      final radius = (size.width * 0.4 + i * 48) * progress;
      canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.1),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DecorationPainter old) =>
      old.progress != progress || old.accent != accent;
}
