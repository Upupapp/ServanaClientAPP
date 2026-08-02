import 'package:client/common/constants/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';

class ServanaBenefitSection extends StatelessWidget {
  const ServanaBenefitSection({super.key});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);

    const steps = [
      _BenefitStep(
        icon: Icons.search_rounded,
        title: 'Choose a service',
        desc:
            'Browse available home and personal services by category or search.',
      ),
      _BenefitStep(
        icon: Icons.calendar_today_outlined,
        title: 'Select a schedule',
        desc: 'Pick a date and time that works for you.',
      ),
      _BenefitStep(
        icon: Icons.check_circle_outline_rounded,
        title: 'Review your booking',
        desc: 'Confirm your details before submitting.',
      ),
      _BenefitStep(
        icon: Icons.notifications_outlined,
        title: 'Manage updates',
        desc: 'Track your booking and receive real-time status updates.',
      ),
    ];

    // §16: vertical padding removed here.
    //
    // The section stacked three separate vertical gaps — the parent's top gap,
    // this container's padding, and this inner 8 — so the space above the
    // heading was the sum of all three rather than any one intended value.
    // Horizontal stays, and now comes from the shared gutter so the section
    // aligns with the grid and banners above it.
    Widget content = Padding(
      padding: EdgeInsets.symmetric(horizontal: homeGutter(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking services should feel simple.',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (i) {
            Widget step = _BenefitStepRow(
              step: steps[i],
              isLast: i == steps.length - 1,
            );
            if (!reduced) {
              step = step
                  .animate(delay: Duration(milliseconds: i * 80))
                  .fadeIn(duration: 280.ms)
                  .slideX(
                    begin: -0.08,
                    end: 0,
                    duration: 280.ms,
                    curve: Curves.easeOutCubic,
                  );
            }
            return step;
          }),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: ColorPalette.primaryBackground),
      child: content,
    );
  }
}

class _BenefitStep {
  final IconData icon;
  final String title;
  final String desc;

  const _BenefitStep({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

class _BenefitStepRow extends StatelessWidget {
  final _BenefitStep step;
  final bool isLast;

  const _BenefitStepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryColorDark.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    step.icon,
                    color: ColorPalette.primaryColorDark,
                    size: 18,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryColor.withOpacity(0.30),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.desc,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
