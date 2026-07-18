import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/presentation/widgets/app_image.dart';

class StoreItemCardWidget extends StatelessWidget {
  final void Function()? onTap;

  final MerchantServiceModel item;
  final bool isOrdinalEditMode;
  final Function(int id, bool value)? onItemToggled;

  const StoreItemCardWidget({
    super.key,
    this.onTap,
    required this.item,
    this.isOrdinalEditMode = false,
    this.onItemToggled,
  });

  @override
  Key? get key => Key("${item.hashCode}");

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        width: double.maxFinite,
        height: 120,
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            if (isOrdinalEditMode)
              const Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu),
                    ],
                  ),
                  Gap(5),
                ],
              ),
            Expanded(
              child: Row(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: AppImage(
                      url: item.merchantServicePictureURL,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            item.merchantServiceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColorPalette.accentText,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Gap(5),
                        Text(
                          "${item.amount}",
                          style: TextStyle(
                            color: ColorPalette.accentText,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          item.merchantServiceDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ColorPalette.accentText,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        // Text.rich(
                        //   TextSpan(
                        //     text: "Status: ",
                        //     style: TextStyle(
                        //       color: ColorPalette.accentText,
                        //       fontSize: 15,
                        //       fontWeight: FontWeight.w400,
                        //     ),
                        //     children: [
                        //       TextSpan(
                        //         text: item.isActive,
                        //         style: TextStyle(
                        //           color: ColorPalette.primaryColorDark,
                        //           fontWeight: FontWeight.w600,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.add_circle_rounded,
                      color: ColorPalette.primaryColorDark,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
