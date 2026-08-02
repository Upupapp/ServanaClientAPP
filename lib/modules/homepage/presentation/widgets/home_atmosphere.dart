import 'package:flutter/material.dart';
import 'package:client/common/constants/color_palette.dart';

class ServanaHomeAtmosphere extends StatefulWidget {
  /// Fixed height, or null to fill whatever the parent measures.
  ///
  /// Null is the Home header's case: its height is content-driven now, so the
  /// backdrop cannot be told a number up front (§6). A `SizedBox(height: null)`
  /// simply takes its constraints, which under `Positioned.fill` is the whole
  /// Stack.
  final double? height;
  const ServanaHomeAtmosphere({super.key, this.height});

  @override
  State<ServanaHomeAtmosphere> createState() => _ServanaHomeAtmosphereState();
}

class _ServanaHomeAtmosphereState extends State<ServanaHomeAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return RepaintBoundary(
      child: IgnorePointer(
        child: SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              // Layer 0: static gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3058C8),
                      Color(0xFF1A3480),
                      Color(0xFF0F2060),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              // Layer 1: large petal geometry (top-right)
              Positioned(
                right: -40,
                top: -30,
                child: _buildPetal(
                  size: 200,
                  opacity: 0.08,
                  reduced: reduced,
                  phaseOffset: 0,
                ),
              ),
              // Layer 2: smaller petal (bottom-left)
              Positioned(
                left: -50,
                bottom: -20,
                child: _buildPetal(
                  size: 140,
                  opacity: 0.06,
                  reduced: reduced,
                  phaseOffset: 0.5,
                ),
              ),
              // Layer 3: orange accent line
              Positioned(
                left: 24,
                bottom: 28,
                child: _buildAccentLine(reduced: reduced),
              ),
              // Layer 4: soft radial overlay (center-top)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.8,
                      colors: [
                        Colors.white.withOpacity(0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetal({
    required double size,
    required double opacity,
    required bool reduced,
    required double phaseOffset,
  }) {
    final petal = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
    if (reduced) return petal;
    return AnimatedBuilder(
      animation: _ambientCtrl,
      builder: (_, child) {
        final v = (_ambientCtrl.value + phaseOffset) % 1.0;
        final dy = (v < 0.5 ? v * 2 : (1 - v) * 2) * 8 - 4; // -4 to +4
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: petal,
    );
  }

  Widget _buildAccentLine({required bool reduced}) {
    final line = Container(
      height: 2,
      width: 80,
      decoration: BoxDecoration(
        color: ColorPalette.primaryColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(1),
      ),
    );
    if (reduced) return line;
    return AnimatedBuilder(
      animation: _ambientCtrl,
      builder: (_, child) {
        final opacity = 0.25 + (_ambientCtrl.value * 0.15);
        return Opacity(opacity: opacity, child: child);
      },
      child: line,
    );
  }
}
