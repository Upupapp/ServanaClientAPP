import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/services/app_haptics.dart';

class ServanaHomeSearch extends StatefulWidget {
  final VoidCallback onTap;
  final bool animate;
  final Duration animationDelay;

  const ServanaHomeSearch({
    super.key,
    required this.onTap,
    required this.animate,
    this.animationDelay = Duration.zero,
  });

  @override
  State<ServanaHomeSearch> createState() => _ServanaHomeSearchState();
}

class _ServanaHomeSearchState extends State<ServanaHomeSearch> {
  static const _hints = [
    'Search for a service...',
    'Search aircon cleaning...',
    'Search massage services...',
    'Search hair and nail care...',
  ];
  int _hintIndex = 0;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _startHintRotation);
  }

  void _startHintRotation() {
    if (!mounted) return;
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) return;
    _hintTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);

    Widget searchBar = GestureDetector(
      onTap: () {
        AppHaptics.selection();
        widget.onTap();
      },
      child: Container(
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Semantics(
          label: 'Search for a service',
          button: true,
          excludeSemantics: true,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search_rounded, color: ColorPalette.primaryColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Align(
                    key: ValueKey(_hintIndex),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _hints[_hintIndex],
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 14,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              Icon(Icons.tune_rounded, color: Colors.grey.shade300, size: 20),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );

    if (!widget.animate || reduced) return searchBar;

    return searchBar
        .animate()
        .fadeIn(duration: 240.ms, delay: widget.animationDelay)
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 240.ms,
          delay: widget.animationDelay,
          curve: Curves.easeOutCubic,
        );
  }
}
