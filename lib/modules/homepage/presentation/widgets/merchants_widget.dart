import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/merchant_light.dart';
import 'package:client/common/helpers/location_helper.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/app_image.dart';
import 'package:client/modules/homepage/presentation/stores/hompage_store.dart';
import 'package:client/modules/store_items/presentation/screens/store_items_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class MerchantsWidget extends StatelessWidget {
  final String? heroKey;
  final MerchantLight merchant;
  MerchantsWidget({
    super.key,
    this.heroKey,
    required this.merchant,
  });
  final store = dpLocator<HomeStore>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.pushNamed(StoreItemsScreen.routeName, extra: (
          merchantId: merchant.merchantID,
          merchantName: merchant.merchantName,
          categoryName: null,
        ));
        store.loadBookings();
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
                  tag: "merchantListImage_${heroKey ?? merchant.merchantID}",
                  child: AppImage(
                    url: merchant.listImage,
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
                  Text(
                    merchant.merchantName,
                    maxLines: 4,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.secondaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: ColorPalette.primaryColor,
                        size: 20,
                      ),
                      Text(
                        merchant.rating > 0
                            ? merchant.rating.toStringAsFixed(1)
                            : "no rating",
                        maxLines: 4,
                        style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Gap(5),
                  Text(
                    "${LocationHelper.distanceBetween(lat1: merchant.latitude, long1: merchant.longitude, lat2: store.currentLocation?.latitude ?? 0, long2: store.currentLocation?.longitude ?? 0).toStringAsFixed(1)}km",
                    maxLines: 4,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  // Row(
                  //   mainAxisSize: MainAxisSize.min,
                  //   children: [
                  //     Container(
                  //       height: 25,
                  //       padding:
                  //           const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  //       decoration: BoxDecoration(
                  //         border: Border.all(
                  //           color: ColorPalette.accentText,
                  //         ),
                  //         borderRadius: BorderRadius.circular(5),
                  //       ),
                  //       child: Row(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           Icon(
                  //             Icons.discount_outlined,
                  //             color: ColorPalette.primaryColor,
                  //             size: 15,
                  //           ),
                  //           const Gap(5),
                  //           Text(
                  //             "AMEX20",
                  //             maxLines: 4,
                  //             style: TextStyle(
                  //               fontFamily: FontPalette.primaryFontFamily,
                  //               fontSize: 13,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     )
                  //   ],
                  // )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
