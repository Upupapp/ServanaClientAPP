import 'dart:ui';

import 'package:client/modules/job_order/presentation/screens/job_order_screen.dart';
import 'package:client/modules/job_order/presentation/widgets/bedroom_selector_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/presentation/widgets/custom_text_field.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_events.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_states.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_states.dart';
import 'package:client/modules/store_items/presentation/widgets/store_item_widget.dart';
import 'package:client/modules/store_items/presentation/widgets/option_list_card_widget.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_options_screen.dart';

class StoreItemsScreen extends StatefulWidget {
  static String routeName = "StoreItems";
  static String route = "StoreItems";

  final String merchantId;
  final String merchantName;
  final String? categoryName;

  const StoreItemsScreen({
    super.key,
    required this.merchantId,
    required this.merchantName,
    this.categoryName,
  });

  @override
  State<StoreItemsScreen> createState() => _StoreItemsScreenState();
}

class _StoreItemsScreenState extends State<StoreItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  String? searchKey;
  String? _selectedCategoryName;

  @override
  void initState() {
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      (context as Element).markNeedsBuild();
    });

    BlocProvider.of<StoreItemsBloc>(context)
        .add(StoreItemLoadEvent(widget.merchantId));

    _selectedCategoryName = widget.categoryName;
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isInItemTab = (tabController.index == 0);
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      label: "Search ${isInItemTab ? 'Services' : 'Option'} ",
                      inputType: TextInputType.name,
                      onChange: (value) {
                        setState(() {
                          final v = value.trim();
                          searchKey = v.isEmpty ? null : v;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (isInItemTab)
              BlocBuilder<StoreItemsBloc, StoreItemsState>(
                builder: (context, state) {
                  final bloc = BlocProvider.of<StoreItemsBloc>(context);

                  // Filter categories by main category if specified
                  var categories = bloc.storeItemCategories;
                  if (widget.categoryName != null) {
                    categories = bloc.storeItemCategories
                        .where((c) => c.services.any((s) =>
                            s.merchantCategoryName == widget.categoryName))
                        .toList();
                  }

                  if (categories.isEmpty) return const SizedBox.shrink();

                  // Don't show chips if there's only one category (like Aircon Repair)
                  if (categories.length <= 1) return const SizedBox.shrink();

                  final allSelected = _selectedCategoryName == null;
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      height: 42,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text("All"),
                              selected: allSelected,
                              onSelected: (_) {
                                setState(() => _selectedCategoryName = null);
                              },
                            ),
                          ),
                          ...categories.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c.name),
                                selected: _selectedCategoryName == c.name,
                                onSelected: (_) {
                                  setState(
                                      () => _selectedCategoryName = c.name);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        BlocConsumer<StoreItemsBloc, StoreItemsState>(
                          listener:
                              (BuildContext context, StoreItemsState state) {
                            if (state is StoreItemLoadingState) {
                              context.loaderOverlay.show();
                            } else {
                              context.loaderOverlay.hide();
                            }
                          },
                          builder: (context, state) {
                            final bloc =
                                BlocProvider.of<StoreItemsBloc>(context);

                            return LoaderOverlay(
                              overlayWidgetBuilder: (progress) {
                                return BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    color: const Color.fromARGB(255, 54, 53, 53)
                                        .withOpacity(.5),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SpinKitRing(
                                          color: ColorPalette.primaryColor,
                                        ),
                                        const Text(
                                          "Loading...",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 20,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: SingleChildScrollView(
                                child: Builder(builder: (context) {
                                  final query = searchKey?.toLowerCase();

                                  // First filter by main category if widget.categoryName is set
                                  // (e.g., "Beauty & Wellness" or "Aircon Repair")
                                  var filteredCategories =
                                      bloc.storeItemCategories;

                                  if (widget.categoryName != null) {
                                    // Filter categories whose services belong to the main category
                                    filteredCategories =
                                        bloc.storeItemCategories
                                            .map((c) {
                                              final servicesInCategory = c
                                                  .services
                                                  .where((s) =>
                                                      s.merchantCategoryName ==
                                                      widget.categoryName)
                                                  .toList();
                                              return c.copyWith(
                                                  services: servicesInCategory);
                                            })
                                            .where((c) => c.services.isNotEmpty)
                                            .toList();
                                  }

                                  // Then filter by selected subcategory chip (if any) and search term
                                  final categories = filteredCategories
                                      .where((c) =>
                                          _selectedCategoryName == null ||
                                          c.name == _selectedCategoryName)
                                      .map((c) {
                                        if (query == null) return c;
                                        final filteredServices = c.services
                                            .where((s) => s.merchantServiceName
                                                .toLowerCase()
                                                .contains(query))
                                            .toList();
                                        return c.copyWith(
                                            services: filteredServices);
                                      })
                                      .where((c) => c.services.isNotEmpty)
                                      .toList();

                                  // Check if any services exist
                                  final hasServices = categories
                                      .any((c) => c.services.isNotEmpty);

                                  if (!hasServices) {
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 40),
                                      child: Center(
                                        child: Text("No services found"),
                                      ),
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Show services grouped by subcategory with headers
                                      for (final category in categories) ...[
                                        // Category/Subcategory header
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          child: Text(
                                            category.name,
                                            style: TextStyle(
                                              color: ColorPalette.accentText,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        // Services under this category
                                        ...category.services.map(
                                          (s) => Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20,
                                                right: 20,
                                                bottom: 10),
                                            child: StoreItemCardWidget(
                                              item: s,
                                              onTap: () async {
                                                // Redirect B&W services to dedicated booking flow
                                                if (s.merchantCategoryName ==
                                                    'Beauty & Wellness') {
                                                  if (!context.mounted) return;
                                                  context.pushNamed(
                                                    BwOptionsScreen.routeName,
                                                    extra: s.merchantServiceID,
                                                  );
                                                  return;
                                                }
                                                final result =
                                                    await BedroomSelectorBottomSheet
                                                        .show(
                                                  context,
                                                  service: s,
                                                );
                                                if (result != null &&
                                                    context.mounted) {
                                                  context.goNamed(
                                                    JobOrderScreen.routeName,
                                                    extra: s,
                                                    pathParameters: {
                                                      "id": widget.merchantId,
                                                      "name":
                                                          widget.merchantName,
                                                    },
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                    ],
                                  );
                                }),
                              ),
                            );
                          },
                        ),

                        /// second page
                        BlocConsumer<StoreOptionsBloc, StoreOptionsState>(
                          listener:
                              (BuildContext context, StoreOptionsState state) {
                            if (state is LoadingStoreOptionsState) {
                              context.loaderOverlay.show();
                            } else {
                              context.loaderOverlay.hide();
                            }
                          },
                          builder: (context, state) {
                            final bloc =
                                BlocProvider.of<StoreOptionsBloc>(context);

                            var options = bloc.options;

                            if (searchKey != null) {
                              options = bloc.options
                                  .where((element) => element.optionItems
                                      .where((element) => element
                                          .merchantOptionItemName
                                          .toLowerCase()
                                          .contains(searchKey!.toLowerCase()))
                                      .isNotEmpty)
                                  .toList();
                            }

                            return SingleChildScrollView(
                              child: Column(
                                children: options.map(
                                  (e) {
                                    var items = e.optionItems;

                                    if (searchKey != null) {
                                      items = e.optionItems
                                          .where((element) => element
                                              .merchantOptionItemName
                                              .toLowerCase()
                                              .contains(
                                                  searchKey!.toLowerCase()))
                                          .toList();
                                    }
                                    return Container(
                                      margin: const EdgeInsets.only(
                                          left: 20, right: 20, bottom: 10),
                                      child: LayoutBuilder(
                                          builder: (context, constraints) {
                                        return OptionListCardWidget(
                                          size: Size(constraints.maxWidth,
                                              constraints.maxHeight),
                                          optionGroupName: e.merchantOptionName,
                                          optionItems: items,
                                        );
                                      }),
                                    );
                                  },
                                ).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
