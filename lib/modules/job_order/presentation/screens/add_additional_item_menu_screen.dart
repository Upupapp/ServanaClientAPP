import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/presentation/widgets/custom_text_field.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/job_order/presentation/widgets/menu_item_widget.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_states.dart';

class AddAdditionalItemMenuScreen extends StatefulWidget {
  static String routeName = "AddAdditionalItemMenuScreen";
  static String route = "AddAdditionalItemMenuScreen";
  const AddAdditionalItemMenuScreen({super.key});

  @override
  State<AddAdditionalItemMenuScreen> createState() =>
      _AddAdditionalItemmenuScreenState();
}

class _AddAdditionalItemmenuScreenState
    extends State<AddAdditionalItemMenuScreen> {
  @override
  void initState() {
    super.initState();
  }

  String? searchKey;

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
                Text(
                  "Add Service",
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: CustomTextField(
                      label: "Search Item",
                      inputType: TextInputType.name,
                      onChange: (value) {
                        setState(() {
                          searchKey = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: BlocConsumer<StoreItemsBloc, StoreItemsState>(
                    listener: (context, state) {
                      // TODO: implement listener
                    },
                    builder: (context, state) {
                      final bloc = BlocProvider.of<StoreItemsBloc>(context);

                      var items = bloc.storeItemCategories;

                      if (searchKey != null) {
                        items = bloc.storeItemCategories
                            .where((element) => element.services
                                .where((element) => element.merchantServiceName
                                    .toLowerCase()
                                    .contains(searchKey!.toLowerCase()))
                                .isNotEmpty)
                            .toList();
                      }

                      return Column(
                        children: items
                            .map((e) => CategoryMenuCard(
                                  services: e.services,
                                  categoryName: e.name,
                                  searchKey: searchKey,
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryMenuCard extends StatelessWidget {
  final String categoryName;
  final List<MerchantServiceModel> services;

  const CategoryMenuCard({
    super.key,
    required this.services,
    required this.categoryName,
    this.searchKey,
  });

  final String? searchKey;

  @override
  Widget build(BuildContext context) {
    var items = services;
    if (searchKey != null) {
      items = services
          .where((element) => element.merchantServiceName
              .toLowerCase()
              .contains(searchKey!.toLowerCase()))
          .toList();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryName,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: MenuItemWidget(
              onTap: () {
                final joBloc = BlocProvider.of<JobOrderBloc>(context);
                joBloc.add(
                  ConfirmAddOptionToJOEvent(
                    e,
                    [],
                  ),
                );
                context.pop();
                // joBloc.add(
                //   ConfirmAddOptionToJOEvent(
                //     e,
                //     joBloc.selectedOptions
                //         .map(
                //           (e) => StoreOptionItem(
                //             id: e.merchantOptionItemID,
                //             name: e.merchantOptionItemName,
                //             price: e.optionAmount,
                //             transportation: 0,
                //           ),
                //         )
                //         .toList(),
                //   ),
                // );
                // context.pop();
              },
              item: e,
            ),
          ),
        ),
      ],
    );
  }
}
