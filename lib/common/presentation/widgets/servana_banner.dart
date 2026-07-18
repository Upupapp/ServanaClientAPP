import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Servana wordmark used at the top-left of the welcome / auth surfaces and
/// reusable anywhere the brand needs to appear inline. Mirrors the Figma
/// `ServanaBanner` group (e.g. node 42:383): the 24×33.0525 logo glyph
/// (orange chevron + blue petals) followed by 7 dp gap + "Servana" wordmark.
///
/// Both SVGs share the same 24×33.0525 viewBox covering the full mark, so
/// stacking them in one box places each path at its correct position
/// without any per-piece offset maths.
class ServanaBanner extends StatelessWidget {
  const ServanaBanner({
    super.key,
    this.scale = 1.0,
    this.color = Colors.white,
  });

  /// Multiplier applied to every dimension/font size, used by the welcome
  /// screen to keep the banner in sync with its 430×932 design canvas.
  final double scale;

  /// Wordmark colour. Defaults to white (used on photo backgrounds); pass
  /// the brand blue when rendering on a light surface.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24 * scale,
          height: 33.0525 * scale,
          child: Stack(
            children: [
              SvgPicture.asset(
                'assets/images/splash/logo_orange.svg',
                fit: BoxFit.contain,
              ),
              SvgPicture.asset(
                'assets/images/splash/logo_blue.svg',
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        SizedBox(width: 7 * scale),
        Text(
          'Servana',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontSize: 20 * scale,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
