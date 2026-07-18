import 'package:client/common/constants/color_palette.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ticket_clippers/ticket_clippers.dart';

class DiscountTicket extends StatelessWidget {
  const DiscountTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: TicketRoundedEdgeClipper(
        edge: Edge
            .horizontal, // edge can be horizontal, vertical, top, left, right, bottom and all.
        position: 30,
        radius: 10,
      ),
      child: Container(
        height: 65,
        width: 130,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: ColorPalette.primaryColor),
        child: Row(
          children: [
            const Gap(20),
            DottedLine(
              direction: Axis.vertical,
              lineLength: double.infinity,
              lineThickness: 2.0,
              dashColor: ColorPalette.accentText.withOpacity(.5),
            ),
            Expanded(
                child: Stack(
              children: [
                Positioned(
                  top: 7,
                  left: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AMEX20",
                        style: TextStyle(
                          color: ColorPalette.primaryButtonTextColor
                              .withOpacity(.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          height: 1,
                        ),
                      ),
                      Text(
                        "Payments",
                        style: TextStyle(
                          color: ColorPalette.primaryButtonTextColor
                              .withOpacity(.5),
                          fontWeight: FontWeight.w600,
                          height: 1,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: ColorPalette.primaryButtonTextColor
                                .withOpacity(.5),
                            size: 15,
                          ),
                          const Gap(1),
                          Text(
                            "1:30PM - 5:00PM",
                            style: TextStyle(
                              color: ColorPalette.primaryButtonTextColor
                                  .withOpacity(.5),
                              fontWeight: FontWeight.w500,
                              height: 1,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Every Thursday",
                        style: TextStyle(
                          color: ColorPalette.primaryButtonTextColor
                              .withOpacity(.5),
                          fontWeight: FontWeight.w600,
                          height: 1,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
