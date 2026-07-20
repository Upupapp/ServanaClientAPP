import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_states.dart';
import 'package:client/modules/merchant_menu/presentation/widgets/merchnat_items.dart';
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
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.secondaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.primaryColorDark,
          ),
        ),
        title: Text(
          "Menu",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: BlocBuilder<StoreItemsBloc, StoreItemsState>(
        builder: (context, state) {
          final bloc = BlocProvider.of<StoreItemsBloc>(context);

          if (state is StoreItemLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bloc.storeItemCategories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 48,
                      color: ColorPalette.secondaryText.withOpacity(.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No items available",
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.secondaryText,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "This merchant hasn't added any items yet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 13,
                        color: ColorPalette.secondaryText.withOpacity(.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
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
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
