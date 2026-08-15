import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/presentation/widgets/app_image.dart';
import 'package:client/modules/merchant_menu/presentation/screens/item_option_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class MerchantItems extends StatelessWidget {
  final MerchantServiceModel service;
  final String? heroKey;
  const MerchantItems({
    super.key,
    this.heroKey,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // The route destructures a record, not a bare model. Passing the model
        // alone failed its type check and bounced the customer Home — a tap
        // that silently did the opposite of what it said.
        context.goNamed(
          ItemOptionMenuScreen.routeName,
          extra: (service: service, joIId: null),
        );
      },
      child: SizedBox(
        height: 100,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 6 / 4,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorPalette.secondaryColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                clipBehavior: Clip.antiAlias,
                child: Hero(
                  tag: "merchantListImage$heroKey",
                  child: AppImage(
                    url: service.merchantServicePictureURL,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const Gap(15),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        service.merchantServiceName,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 17,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          context.goNamed(
                            ItemOptionMenuScreen.routeName,
                            extra: (service: service, joIId: null),
                          );
                        },
                        child: Icon(
                          Icons.add_circle_rounded,
                          color: ColorPalette.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    service.merchantServiceDescription,
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.secondaryText,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 14,
                    ),
                  ),
                  const Gap(5),
                  Text(
                    service.amount.toStringAsFixed(2),
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
