import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_events.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_states.dart';
import 'package:client/modules/store_items/presentation/widgets/opiton_item_list_card_widget.dart';

class LinkOptionGroupDialog extends StatelessWidget {
  const LinkOptionGroupDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.primaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BlocConsumer<StoreOptionsBloc, StoreOptionsState>(
        listener: (context, state) {
          // TODO: implement listener
        },
        builder: (context, state) {
          final bloc = BlocProvider.of<StoreOptionsBloc>(context);
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Gap(25),
              Row(
                children: [
                  const SizedBox(
                    width: 25,
                  ),
                  Text(
                    "Link Option Group",
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const Gap(15),
              ...bloc.options
                  .map((e) => [
                        const Gap(10),
                        OptionItemListCard(
                          title: e.merchantOptionName,
                          value: bloc.optionsToLink.contains(e),
                          onToggle: (value) {
                            if (value) {
                              bloc.add(
                                  AddStoreOptionToLinkListEvent(option: e));
                            } else {
                              bloc.add(
                                  RemoveStoreOptionToLinkListEvent(option: e));
                            }
                          },
                          subTitle:
                              "${e.isRequired ? "Required" : "Optional"}: ${e.optionItems.map((e) => e.merchantOptionItemName).join(', ')}",
                        ),
                      ])
                  .expand((element) => element),
              const Gap(30),
              PrimaryButton(
                width: 250,
                text: "Done",
                onClick: () {
                  context.pop();
                },
              ),
              const Gap(25),
            ],
          );
        },
      ),
    );
  }
}
