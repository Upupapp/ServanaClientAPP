import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/presentation/widgets/custom_drop_down_menu.dart';
import 'package:client/common/presentation/widgets/app_image.dart';
import 'package:client/common/presentation/widgets/secondary_button.dart';
import 'package:client/modules/merchant_menu/presentation/widgets/discount_ticket_widget.dart';
import 'package:client/modules/merchant_menu/presentation/widgets/merchnat_items.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class MerchantMenuScreen extends StatefulWidget {
  static String routeName = "MerchantMenuScreen";
  static String route = "MerchantMenuScreen";

  const MerchantMenuScreen({super.key});

  @override
  State<MerchantMenuScreen> createState() => _MerchantMenuScreenState();
}

class _MerchantMenuScreenState extends State<MerchantMenuScreen> {
  @override
  Widget build(BuildContext context) {
    const double toolbarHeight = 125;
    var top = 0.0;
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              backgroundColor: ColorPalette.secondaryBackground,
              surfaceTintColor: ColorPalette.transparent,
              collapsedHeight: toolbarHeight,
              pinned: true,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () {
                    context.pop();
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.favorite_outline_rounded,
                    color: ColorPalette.primaryColorDark,
                  ),
                )
              ],
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  top = constraints.biggest.height;
                  bool isCollapsed =
                      (MediaQuery.of(context).padding.top + toolbarHeight) ==
                          top;

                  return FlexibleSpaceBar(
                    centerTitle: true,
                    title: isCollapsed
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Merchant name",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ColorPalette.secondaryText,
                                  fontSize: 20,
                                ),
                              ),
                              const Gap(20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Gap(25),
                                  const Expanded(
                                    child: SizedBox(
                                      height: 45,
                                      child: CustomDropDownMenu(
                                        iconSize: 25,
                                        borderRadius: 15,
                                        items: [
                                          (key: "test", name: "test"),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Gap(10),
                                  SizedBox(
                                    height: 45,
                                    child: SecondaryButton(
                                      text: "Search",
                                      forgroundColor: ColorPalette.accentText,
                                      leading: Icon(
                                        Icons.search,
                                        color: ColorPalette.accentText,
                                      ),
                                      borderRadius: 15,
                                    ),
                                  ),
                                  const Gap(25),
                                ],
                              )
                            ],
                          )
                        : null,
                    background: const Stack(
                      children: [
                        Positioned.fill(
                          child: AppImage(
                            url: null,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ];
        },
        body: BlocConsumer<StoreItemsBloc, StoreItemsState>(
            listener: (context, state) {
          // TODO: implement listener
        }, builder: (contex, state) {
          final bloc = BlocProvider.of<StoreItemsBloc>(context);
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Gap(25),
                    Text(
                      "Merchant name",
                      style: TextStyle(
                        color: ColorPalette.secondaryText,
                        fontWeight: FontWeight.w500,
                        fontSize: 28,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "1.5km",
                      style: TextStyle(
                        color: ColorPalette.secondaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Gap(25),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Gap(25),
                    Icon(
                      Icons.star,
                      color: ColorPalette.primaryColor,
                    ),
                    const Gap(5),
                    Text(
                      "4.5",
                      style: TextStyle(
                        color: ColorPalette.primaryButtonTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                    ),
                    const Gap(5),
                    Text(
                      "•",
                      style: TextStyle(
                        color: ColorPalette.primaryButtonTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Gap(5),
                    Text(
                      "Ratings & Reviews",
                      style: TextStyle(
                        color: ColorPalette.primaryButtonTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: ColorPalette.primaryColorDark,
                      size: 18,
                    ),
                    const Gap(25),
                  ],
                ),
                const Gap(5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Gap(25),
                    Icon(
                      Icons.discount_rounded,
                      color: ColorPalette.primaryColor,
                    ),
                    const Gap(5),
                    Text(
                      "Deals and promotions",
                      style: TextStyle(
                        color: ColorPalette.primaryButtonTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: ColorPalette.primaryColorDark,
                      size: 18,
                    ),
                    const Gap(25),
                  ],
                ),
                const Gap(5),
                const SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Gap(25),
                      DiscountTicket(),
                      Gap(10),
                      DiscountTicket(),
                      Gap(10),
                      DiscountTicket(),
                      Gap(10),
                      DiscountTicket(),
                      Gap(25),
                    ],
                  ),
                ),
                ...List.generate(
                  bloc.storeItemCategories.length,
                  (catIndex) => Padding(
                    padding:
                        const EdgeInsets.only(left: 25, right: 25, bottom: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Gap(20),
                        Text(
                          bloc.storeItemCategories[catIndex].name,
                          style: TextStyle(
                            color: ColorPalette.secondaryText,
                            fontWeight: FontWeight.w500,
                            fontSize: 22,
                          ),
                        ),
                        ...List.generate(
                          bloc.storeItemCategories[catIndex].services.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: MerchantItems(
                              service: bloc.storeItemCategories[catIndex]
                                  .services[index],
                              heroKey: bloc.storeItemCategories[catIndex]
                                  .services[index].merchantServiceID
                                  .toString(),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        }),
      ),
    );
  }
}
