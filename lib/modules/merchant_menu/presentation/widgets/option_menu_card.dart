import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_states.dart';
import 'package:client/modules/merchant_menu/presentation/widgets/opiton_menu_item_list_card_widget.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

class OptionMenuCard extends StatelessWidget {
  final String opitonName;
  final bool isRequired;
  final int minimumSelection;
  final int maximumSelection;
  final int optionGroupId;
  final int serviceId;
  final String? jobOrderItemId;
  final List<StoreOptionItem> options;
  const OptionMenuCard({
    super.key,
    required this.opitonName,
    required this.options,
    required this.isRequired,
    required this.minimumSelection,
    required this.maximumSelection,
    required this.optionGroupId,
    required this.serviceId,
    this.jobOrderItemId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobOrderBloc, JOState>(
      listener: (context, state) {},
      builder: (context, state) {
        var bloc = BlocProvider.of<JobOrderBloc>(context);
        return Column(
          children: [
            Row(
              children: [
                Text(
                  opitonName,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                  ),
                ),
                const Gap(5),
                Text(
                  "${isRequired ? 'Required' : 'Optional'}:$minimumSelection",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorPalette.accentText,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            ...options.map(
              (e) {
                ////todo: remove during APIs retrofit

                return OptionMenuItemListCard(
                  title: e.merchantOptionItemName,
                  price: e.amount,
                  // isLoading: state is LoadingJOState,
                  value: bloc.isOptionSelected(e, jobOrderItemId),
                  onToggle: (value) {
                    if (value) {
                      bloc.add(AddOptionToJOEvent(e, jobOrderItemId));
                    } else {
                      bloc.add(RemoveOptionToJOEvent(e));
                    }
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
