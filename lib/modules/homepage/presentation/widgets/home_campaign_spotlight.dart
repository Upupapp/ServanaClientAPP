import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/services/app_haptics.dart';
import '../../domain/home_promotion.dart';

Future<void> showCampaignSpotlight({
  required BuildContext context,
  required HomeCampaign campaign,
  required VoidCallback onDismiss,
  required VoidCallback onCtaTap,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close promotion',
    barrierColor: Colors.transparent,
    pageBuilder: (ctx, anim, _) => _CampaignSpotlightPage(
      campaign: campaign,
      animation: anim,
      onDismiss: () {
        Navigator.of(ctx).pop();
        onDismiss();
      },
      onCtaTap: () {
        Navigator.of(ctx).pop();
        onCtaTap();
      },
    ),
  );
}

class _CampaignSpotlightPage extends StatefulWidget {
  final HomeCampaign campaign;
  final Animation<double> animation;
  final VoidCallback onDismiss;
  final VoidCallback onCtaTap;

  const _CampaignSpotlightPage({
    required this.campaign,
    required this.animation,
    required this.onDismiss,
    required this.onCtaTap,
  });

  @override
  State<_CampaignSpotlightPage> createState() =>
      _CampaignSpotlightPageState();
}

class _CampaignSpotlightPageState extends State<_CampaignSpotlightPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stageCtrl;

  @override
  void initState() {
    super.initState();
    _stageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _stageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Full-screen background — fades in
          FadeTransition(
            opacity: widget.animation,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A1F6E), Color(0xFF061040)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar: close button always available
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Semantics(
                        label: 'Close promotion',
                        button: true,
                        child: GestureDetector(
                          onTap: widget.onDismiss,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content area
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildAtmosphere(reduced: reduced),
                          const SizedBox(height: 28),
                          _buildServiceChips(reduced: reduced),
                          const SizedBox(height: 32),
                          _buildMessage(reduced: reduced),
                          const SizedBox(height: 32),
                          _buildCta(reduced: reduced),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtmosphere({required bool reduced}) {
    Widget petals = SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorPalette.primaryColorDark.withOpacity(0.4),
            ),
          ),
          Icon(
            Icons.home_work_outlined,
            color: Colors.white.withOpacity(0.9),
            size: 48,
          ),
        ],
      ),
    );

    if (reduced) return petals;
    return petals
        .animate(controller: _stageCtrl)
        .fadeIn(duration: 300.ms, begin: 0)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildServiceChips({required bool reduced}) {
    const services = [
      (icon: Icons.spa_outlined, label: 'Beauty'),
      (icon: Icons.content_cut_outlined, label: 'Hair & Nails'),
      (icon: Icons.self_improvement_outlined, label: 'Massage'),
      (icon: Icons.ac_unit_rounded, label: 'Aircon'),
    ];

    Widget chips = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: services
          .map((s) => _ServiceChip(icon: s.icon, label: s.label))
          .toList(),
    );

    if (reduced) return chips;

    return chips
        .animate(controller: _stageCtrl, delay: 350.ms)
        .fadeIn(duration: 300.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildMessage({required bool reduced}) {
    Widget msg = Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            widget.campaign.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.campaign.subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.72),
            height: 1.5,
          ),
        ),
      ],
    );

    if (reduced) return msg;
    return msg
        .animate(controller: _stageCtrl, delay: 550.ms)
        .fadeIn(duration: 300.ms)
        .slideY(
          begin: 0.12,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildCta({required bool reduced}) {
    Widget cta = Column(
      children: [
        GestureDetector(
          onTap: () {
            AppHaptics.medium();
            widget.onCtaTap();
          },
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: ColorPalette.primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ColorPalette.primaryColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.campaign.ctaLabel,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: widget.onDismiss,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Maybe later',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.55),
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.30),
              ),
            ),
          ),
        ),
      ],
    );

    if (reduced) return cta;
    return cta
        .animate(controller: _stageCtrl, delay: 700.ms)
        .fadeIn(duration: 280.ms)
        .slideY(
          begin: 0.16,
          end: 0,
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _ServiceChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ServiceChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.85), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
