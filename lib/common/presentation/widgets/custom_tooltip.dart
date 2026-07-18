import 'package:flutter/material.dart';
import 'package:overlay_tooltip/overlay_tooltip.dart';
import 'package:client/common/constants/color_palette.dart';

class CustomToolTip extends StatelessWidget {
  final TooltipController controller;
  final String title;

  const CustomToolTip({
    super.key,
    required this.controller,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentDisplayIndex = controller.nextPlayIndex + 1;
    final totalLength = controller.playWidgetLength;
    final hasNextItem = currentDisplayIndex < totalLength;
    final hasPreviousItem = currentDisplayIndex != 1;
    final canPause = currentDisplayIndex < totalLength;

    return Container(
      width: size.width * .7,
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(
              text: title,
            ),
            WidgetSpan(
              child: Opacity(
                opacity: totalLength == 1 ? 0 : 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '$currentDisplayIndex OF $totalLength',
                    style: TextStyle(
                        color: ColorPalette.accentText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            )
          ])),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Opacity(
                opacity: hasPreviousItem ? 1 : 0,
                child: TextButton(
                  onPressed: () {
                    controller.previous();
                  },
                  style: TextButton.styleFrom(
                      backgroundColor:
                          ColorPalette.secondaryText.withOpacity(.20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Prev',
                      style: TextStyle(
                        color: ColorPalette.primaryText,
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: canPause ? 1 : 0,
                child: TextButton(
                  onPressed: () {
                    controller.pause();
                  },
                  style: TextButton.styleFrom(
                      backgroundColor: ColorPalette.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Pause',
                      style: TextStyle(
                        color: ColorPalette.primaryText,
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.next();
                },
                style: TextButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    hasNextItem ? 'Next' : 'Got It',
                    style: TextStyle(
                      color: ColorPalette.primaryButtonTextColor,
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
