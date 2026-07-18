import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/data/models/job_order_item.dart';
import 'package:client/common/helpers/location_helper.dart';
import 'package:client/common/presentation/widgets/confirmation_dialog.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';

class ServiceListTile extends StatelessWidget {
  const ServiceListTile({
    super.key,
    required this.serviceName,
    required this.optionItems,
    this.onItemOrdinalUpdated,
    required this.size,
    required this.servicePrice,
    this.isServiceAddedByMerchant = false,
    this.jobOrderItemId,
    this.isAddedByUser = false,
  });
  final String serviceName;
  final String? jobOrderItemId;
  final double servicePrice;
  final bool isAddedByUser;
  final Size size;
  final bool isServiceAddedByMerchant;
  final List<SelectedOption> optionItems;
  final void Function(int oldIndex, int newIndex, String value)?
      onItemOrdinalUpdated;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                serviceName,
                style: TextStyle(
                  color: ColorPalette.secondaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isServiceAddedByMerchant) ...[
                const Gap(5),
                Text(
                  "by merchant",
                  style: TextStyle(
                    color: ColorPalette.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              const Gap(10),
              Text(
                LocationHelper.localizedPrice(servicePrice),
                style: TextStyle(
                  color: ColorPalette.secondaryText,
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        if (!isAddedByUser)
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 10),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 5),
              itemCount: optionItems.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          ConfirmationDialog.showDialog(
                            context: context,
                            msg: "",
                            title:
                                "Remove ${optionItems[index].merchantOptionItemName}?",
                            onConfirm: () {
                              var bloc = BlocProvider.of<JobOrderBloc>(context);
                              bloc.add(
                                RemoveOptionToJOEvent(
                                  StoreOptionItem(
                                    merchantOptionItemID:
                                        optionItems[index].merchantOptionItemID,
                                    merchantOptionItemName: optionItems[index]
                                        .merchantOptionItemName,
                                    amount: optionItems[index].optionAmount,
                                    baseFair: 0,
                                  ),
                                  optionItems[index].jobOrderOptionItemID,
                                ),
                              );
                              bloc.add(LoadJOEvent(bloc.jobOrder!.jobOrderID));
                            },
                          );
                        },
                        child: Icon(
                          Icons.delete,
                          color: ColorPalette.danger,
                          size: 20,
                        ),
                      ),
                      const Gap(10),
                      Text(
                        optionItems[index].merchantOptionItemName,
                        style: TextStyle(
                          color: ColorPalette.accentText,
                          fontSize: 17,
                        ),
                      ),
                      // if (!isServiceAddedByMerchant &&
                      //     optionItems[index].addedByMerchant) ...[
                      //   const Gap(5),
                      //   Text(
                      //     "by merchant",
                      //     style: TextStyle(
                      //       color: ColorPalette.primaryColor,
                      //       fontSize: 10,
                      //       fontWeight: FontWeight.w500,
                      //     ),
                      //   ),
                      // ],
                      const Spacer(),
                      Text(
                        LocationHelper.localizedPrice(
                            optionItems[index].optionAmount),
                        style: TextStyle(
                          color: ColorPalette.accentText,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        // Padding(
        //   padding: const EdgeInsets.only(bottom: 10),
        //   child: GestureDetector(
        //     onTap: () async {
        //       final joBloc = BlocProvider.of<JobOrderBloc>(context);
        //       joBloc.add(LoadServiceOptionsJOEven(service.merchantServiceID));
        //       await context.pushNamed(
        //         ItemOptionMenuScreen.routeName,
        //         extra: (
        //           joIId: jobOrderItemId,
        //           service: service,
        //         ),
        //       );
        //       joBloc.add(LoadJOEvent(joBloc.jobOrderId!));
        //     },
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.start,
        //       children: [
        //         const Gap(20),
        //         Image.asset(
        //           "assets/icons/plus.png",
        //           height: 15,
        //         ),
        //         const Gap(5),
        //         Text(
        //           "Add Option",
        //           style: TextStyle(
        //               color: ColorPalette.primaryColorDark,
        //               fontSize: 10,
        //               fontWeight: FontWeight.w500),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
