import 'package:client/common/data/models/merchant_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:input_quantity/input_quantity.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/merchant_service_option.dart';
import 'package:client/common/presentation/widgets/custom_text_field.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/job_order/presentation/screens/job_order_screen.dart';
import 'package:client/modules/job_order/presentation/widgets/menu_item_widget.dart';
import 'package:client/modules/job_order/presentation/widgets/option_menu_card.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_states.dart';

class ItemOptionMenuScreen extends StatefulWidget {
  static String routeName = "ItemOptionMenuScreen";
  static String route = "ItemOptionMenuScreen";
  final MerchantServiceModel service;
  const ItemOptionMenuScreen(
      {super.key, required this.service, this.jobOrderItemId});

  final String? jobOrderItemId;

  @override
  State<ItemOptionMenuScreen> createState() => _ItemOptionMenuScreenState();
}

class _ItemOptionMenuScreenState extends State<ItemOptionMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    context.pop();
                  },
                  icon: Icon(
                    Icons.chevron_left,
                    size: 40,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: MenuItemWidget(
                item: widget.service,
              ),
            ),
            const Gap(15),
            Expanded(
                child: SingleChildScrollView(
              child: BlocConsumer<StoreOptionsBloc, StoreOptionsState>(
                  listener: (context, state) {},
                  builder: (context, state) {
                    final optionsbloc =
                        BlocProvider.of<StoreOptionsBloc>(context);
                    optionsbloc.optionsToLink.clear();
                    optionsbloc.optionsToLink.addAll(
                      widget.service.selectionOptions.map(
                        (e) => MerchantServiceOptionModel(
                          merchantOptionID: e.merchantOptionID,
                          merchantID: "",
                          merchantOptionName: e.merchantOptionName,
                          isRequired: e.isRequired,
                          minimumOption: e.minimumOption,
                          maximumOption: e.maximumOption,
                          optionItems: e.selectedOptionItems
                              .map((e2) => StoreOptionItem(
                                  merchantOptionID: e2.merchantOptionItemID,
                                  merchantOptionItemName:
                                      e2.merchantOptionItemName,
                                  amount: e2.amount.toDouble(),
                                  baseFair: e2.baseFair.toDouble()))
                              .toList(),
                          merchantServiceID: widget.service.merchantServiceID,
                          ordinal: e.ordinal,
                          createdDate: DateTime.now(),
                        ),
                      ),
                    );

                    final joBloc = BlocProvider.of<JobOrderBloc>(context);
                    return Column(
                      children: [
                        ...optionsbloc.optionsToLink.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(
                              left: 25,
                              right: 25,
                              top: 15,
                            ),
                            child: OptionMenuCard(
                              opitonName: e.merchantOptionName,
                              options: e.optionItems,
                              isRequired: e.isRequired,
                              minimumSelection: e.minimumOption,
                              maximumSelection: e.maximumOption,
                              optionGroupId: e.merchantOptionID,
                              jobOrderItemId: widget.jobOrderItemId,
                              serviceId: widget.service.merchantServiceID,
                            ),
                          ),
                        ),
                        const Gap(25),
                        if (widget.jobOrderItemId == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: CustomTextField(
                              label: "Notes",
                              inputType: TextInputType.multiline,
                              maxLines: 10,
                              onChange: (value) {},
                            ),
                          ),
                        const Gap(30),
                        InputQty.int(
                          minVal: 1,
                          qtyFormProps: QtyFormProps(
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          decoration: QtyDecorationProps(
                            qtyStyle: QtyStyle.classic,
                            plusBtn: Icon(
                              Icons.add_circle_rounded,
                              color: ColorPalette.primaryColor,
                              size: 30,
                            ),
                            minusBtn: Icon(
                              Icons.remove_circle_rounded,
                              color: ColorPalette.primaryColor,
                              size: 30,
                            ),
                            btnColor: ColorPalette.primaryColor,
                            isBordered: false,
                            orientation: ButtonOrientation.horizontal,
                          ),
                          onQtyChanged: (val) {},
                        ),
                        const Gap(30),
                        if (widget.jobOrderItemId == null)
                          PrimaryButton(
                            width: 250,
                            text: "Add Item",
                            onClick: () {
                              joBloc.add(
                                ConfirmAddOptionToJOEvent(
                                  widget.service,
                                  joBloc.selectedOptions
                                      .map(
                                        (e) => StoreOptionItem(
                                          merchantOptionItemID:
                                              e.merchantOptionItemID,
                                          merchantOptionItemName:
                                              e.merchantOptionItemName,
                                          amount: e.optionAmount,
                                          baseFair: 0,
                                        ),
                                      )
                                      .toList(),
                                ),
                              );
                              context.goNamed(JobOrderScreen.routeName);
                            },
                          )
                        else
                          PrimaryButton(
                            width: 250,
                            text: "Done",
                            onClick: () {
                              joBloc.add(LoadJOEvent(joBloc.jobOrderId!));
                              context.pop();
                            },
                          ),
                        const Gap(25),
                      ],
                    );
                  }),
            ))
          ],
        ),
      ),
    );
  }
}
