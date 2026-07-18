import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/job_order_item.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/presentation/screens/address_form_screen.dart';
import 'package:client/common/presentation/widgets/custom_text_field.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/modules/job_order/data/models/jo_photo_model.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_states.dart';
import 'package:client/modules/job_order/presentation/screens/add_additional_item_menu_screen.dart';
import 'package:client/modules/job_order/presentation/screens/select_payment_method_screen.dart';
import 'package:client/modules/job_order/presentation/widgets/carousel_image_picker.dart';
import 'package:client/modules/job_order/presentation/widgets/service_list_tile_widget.dart';
import 'package:client/modules/merchant_menu/presentation/widgets/option_menu_card.dart';
import 'package:client/modules/store_items/data/models/store_option_items.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_states.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

class JobOrderScreen extends StatefulWidget {
  static String routeName = "JobOrderScreen";
  static String route = "JobOrderScreen/:id/:name";
  const JobOrderScreen(
      {super.key,
      required this.service,
      required this.merchantId,
      required this.merchantName});

  final MerchantServiceModel service;
  final String merchantId;
  final String merchantName;

  @override
  State<JobOrderScreen> createState() => _JobOrderScreenState();
}

class _JobOrderScreenState extends State<JobOrderScreen> {
  final GlobalKey _contentKey = GlobalKey();
  final _dateFormat = 'MMM. d, yyyy kk:mm aa';

  late final JobOrderBloc _bloc;
  final _notedController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedAddress;
  LatLong? _selectedLocation;

  @override
  void initState() {
    _bloc = context.read<JobOrderBloc>();
    _bloc.joServices.clear();
    _bloc.joServices.add(
      JobOrderItem(
        jobOrderItemID: widget.service.merchantServiceID,
        serviceId: widget.service.merchantServiceID.toString(),
        serviceName: widget.service.merchantServiceName,
        transportaion: widget.service.baseFair.toDouble(),
        quantity: 1,
        amount: widget.service.amount.toDouble(),
        discount: 0,
        selectedOptions: [],
      ),
    );
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final confirmed = await _ensureLocationConfirmed();
      if (!mounted) return;
      if (!confirmed) {
        context.pop();
      }
    });
  }

  @override
  void dispose() {
    // Avoid looking up inherited widgets in dispose (can crash during route transitions).
    _bloc.add(const LoadingJOEvent());
    _notedController.dispose();
    super.dispose();
  }

  Future<AddressFormResult?> _openLocationDetailsScreen() async {
    return Navigator.of(context).push<AddressFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddressFormScreen(
          title: 'Location Details',
          actionLabel: 'Next',
          initialAddress: _selectedAddress,
          initialLocation: _selectedLocation,
          showGps: true,
        ),
      ),
    );
  }

  Future<bool> _ensureLocationConfirmed() async {
    // If we already have a location + address, skip the gate.
    if (_selectedLocation != null &&
        (_selectedAddress ?? '').trim().isNotEmpty) {
      return true;
    }

    final res = await _openLocationDetailsScreen();
    if (!mounted || res == null) return false;

    setState(() {
      _selectedAddress = res.address;
      _selectedLocation = res.location;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          key: _contentKey,
          children: [
            const Gap(50),
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
              children: [
                const SizedBox(
                  width: 25,
                ),
                Text(
                  widget.merchantName,
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
              children: [
                const Gap(25),
                Icon(
                  Icons.schedule,
                  color: ColorPalette.primaryColor,
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Schedule",
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: ColorPalette.secondaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        (_selectedDate != null)
                            ? DateFormat(_dateFormat).format(_selectedDate ??
                                DateTime.now().add(const Duration(days: 1)))
                            : "Select Schedule",
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: ColorPalette.secondaryText,
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 360)),
                    );

                    TimeOfDay? selectedTime;

                    if (selectedDate != null) {
                      selectedTime = await showTimePicker(
                        // ignore: use_build_context_synchronously
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                    }

                    if (selectedTime != null && selectedDate != null) {
                      setState(() {
                        _selectedDate = selectedDate.copyWith(
                          hour: selectedTime?.hour,
                          minute: selectedTime?.minute,
                        );
                      });
                    }
                  },
                  icon: Icon(
                    Icons.edit,
                    size: 25,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
              ],
            ),
            const Gap(5),
            Row(
              children: [
                const Gap(25),
                Icon(
                  Icons.location_on,
                  color: ColorPalette.primaryColorDark,
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Location",
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: ColorPalette.secondaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        (_selectedAddress ?? '').trim().isEmpty
                            ? "Select location"
                            : _selectedAddress!,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: ColorPalette.secondaryText,
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final res = await _openLocationDetailsScreen();
                    if (!mounted || res == null) return;
                    setState(() {
                      _selectedAddress = res.address;
                      _selectedLocation = res.location;
                    });
                  },
                  icon: Icon(
                    Icons.edit,
                    size: 25,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
              ],
            ),
            const Gap(10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomTextField(
                label: "Note",
                controller: _notedController,
                maxLines: 5,
              ),
            ),
            const Gap(20),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: BlocConsumer<JobOrderBloc, JOState>(
                      listener: (context, state) async {
                        if (state is DoneJOState) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Job order submitted.'),
                            ),
                          );
                          if (context.canPop()) context.pop();
                        }
                      },
                      builder: (context, state) {
                        var bloc = BlocProvider.of<JobOrderBloc>(context);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Gap(10),
                            CarouselImagePicker(
                              onImagePicked: (file) {
                                var photo = JOPhotoModel(
                                  isFromMerchant: true,
                                  photoFile: XFile(file.path),
                                );
                                bloc.add(AddedPhotoJOEvent(photo));
                              },
                            ),
                            const Gap(10),
                            ...bloc.joPhotos.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: SizedBox(
                                  width: 250,
                                  height: 300,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.file(
                                          File(e.photoFile!.path),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (e.isFromMerchant)
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 25,
                                            color: ColorPalette.primaryColor
                                                .withOpacity(.5),
                                            child: Center(
                                              child: Text(
                                                "Added by Merchant",
                                                style: TextStyle(
                                                  color: ColorPalette
                                                      .primaryText
                                                      .withOpacity(.7),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Gap(15),
            Row(
              children: [
                const Gap(25),
                Text(
                  "Booking Summary",
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const Gap(15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      BlocConsumer<StoreItemsBloc, StoreItemsState>(
                        listener: (context, state) {},
                        builder: (context, state) {
                          {
                            return BlocConsumer<JobOrderBloc, JOState>(
                              listener: (context, state) {},
                              builder: (context, state) {
                                var bloc =
                                    BlocProvider.of<JobOrderBloc>(context);
                                var itemsBloc =
                                    BlocProvider.of<StoreItemsBloc>(context);
                                return Column(
                                  children: bloc.joServices.map((e) {
                                    final service =
                                        itemsBloc.storeItemCategories.fold(
                                            <MerchantServiceModel>[],
                                            (previousValue, element) => [
                                                  ...previousValue,
                                                  ...element.services
                                                ]).firstWhere((element) =>
                                            element.merchantServiceName ==
                                            e.serviceName);
                                    return Column(
                                      children: [
                                        ServiceListTile(
                                          size: Size(constraints.maxWidth,
                                              constraints.maxHeight),
                                          isServiceAddedByMerchant: false,
                                          isAddedByUser: true,
                                          // e.addedByMerchant,
                                          servicePrice: e.amount,
                                          jobOrderItemId:
                                              e.jobOrderItemID.toString(),
                                          serviceName: e.serviceName,
                                          optionItems: e.selectedOptions,
                                        ),
                                        if (service.selectionOptions.isNotEmpty)
                                          const Row(
                                            children: [
                                              Gap(10),
                                              Text(
                                                "Options",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        const Gap(5),
                                        ...service.selectionOptions.map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.only(
                                                left: 10.0),
                                            child: OptionMenuCard(
                                              opitonName: e.merchantOptionName,
                                              options: e.selectedOptionItems
                                                  .map(
                                                    (o) => StoreOptionItem(
                                                      merchantOptionItemID: o
                                                          .merchantOptionItemID,
                                                      merchantServiceID: service
                                                          .merchantServiceID
                                                          .toString(),
                                                      merchantOptionID:
                                                          o.merchantOptionID,
                                                      merchantOptionItemName: o
                                                          .merchantOptionItemName,
                                                      amount:
                                                          o.amount.toDouble(),
                                                      baseFair:
                                                          o.baseFair.toDouble(),
                                                    ),
                                                  )
                                                  .toList(),
                                              isRequired: e.isRequired,
                                              minimumSelection: e.minimumOption,
                                              maximumSelection: e.maximumOption,
                                              optionGroupId: e.merchantOptionID,
                                              jobOrderItemId: "",
                                              serviceId: widget
                                                  .service.merchantServiceID,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 5.0, top: 10),
                                          child: DottedLine(
                                            direction: Axis.horizontal,
                                            lineLength: double.infinity,
                                            lineThickness: 2.0,
                                            dashColor: ColorPalette.accentText,
                                          ),
                                        )
                                      ],
                                    );
                                  }).toList(),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const Gap(10),
            BlocConsumer<JobOrderBloc, JOState>(
                listener: (context, state) {},
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: GestureDetector(
                      onTap: () async {
                        // final bloc = BlocProvider.of<JobOrderBloc>(context);
                        await context.pushNamed(
                            AddAdditionalItemMenuScreen.routeName,
                            pathParameters: {
                              "id": widget.merchantId,
                              "name": widget.merchantName
                            });
                        // bloc.add(LoadJOEvent(bloc.jobOrderId!));
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_rounded,
                            color: ColorPalette.primaryColorDark,
                            size: 22,
                          ),
                          const Gap(5),
                          Text(
                            "Add Service",
                            style: TextStyle(
                                color: ColorPalette.primaryColorDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            const Gap(20),
            DottedLine(
              direction: Axis.horizontal,
              lineLength: double.infinity,
              lineThickness: 2.0,
              dashColor: ColorPalette.accentText,
            ),
            const Gap(15),
            BlocConsumer<JobOrderBloc, JOState>(
              listener: (context, state) {},
              builder: (context, state) {
                var bloc = BlocProvider.of<JobOrderBloc>(context);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Text(
                            "Subtotal:",
                            style: TextStyle(
                              color: ColorPalette.secondaryText,
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            bloc.subtotal.toStringAsFixed(2),
                            style: TextStyle(
                              color: ColorPalette.secondaryText,
                              fontWeight: FontWeight.w500,
                              fontSize: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Text(
                            "Transportation::",
                            style: TextStyle(
                              color: ColorPalette.secondaryText,
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            bloc.transportation.toStringAsFixed(2),
                            style: TextStyle(
                              color: ColorPalette.secondaryText,
                              fontWeight: FontWeight.w500,
                              fontSize: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const Gap(5),
            Divider(
              thickness: .5,
              color: ColorPalette.accentText,
            ),
            const Gap(15),
            Row(
              children: [
                const Gap(25),
                Text(
                  "Payment Details",
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const Gap(15),
            GestureDetector(
              onTap: () {
                context.pushNamed(SelectPaymentMethodScreen.routeName);
              },
              child: Row(
                children: [
                  const Gap(25),
                  SvgPicture.asset(
                    "assets/payment_icons/visa_icon.svg",
                    height: 30,
                  ),
                  const Gap(10),
                  Text(
                    "************1396",
                    style: TextStyle(
                      color: ColorPalette.secondaryText,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      context.pushNamed(SelectPaymentMethodScreen.routeName);
                    },
                    icon: Icon(
                      Icons.chevron_right,
                      size: 35,
                      color: ColorPalette.primaryColorDark,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Gap(25),
                Icon(
                  Icons.percent_rounded,
                  color: ColorPalette.primaryColorDark,
                  size: 24,
                ),
                const Gap(10),
                Text(
                  "Use vouchers to get discounts",
                  style: TextStyle(
                    color: ColorPalette.secondaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.chevron_right,
                    size: 35,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
              ],
            ),
            const Gap(50),
            DottedLine(
              direction: Axis.horizontal,
              lineLength: double.infinity,
              lineThickness: 2.0,
              dashColor: ColorPalette.accentText,
            ),
            const Gap(15),
            BlocConsumer<JobOrderBloc, JOState>(
                listener: (context, state) {},
                builder: (context, state) {
                  var bloc = BlocProvider.of<JobOrderBloc>(context);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Text(
                          "Total:",
                          style: TextStyle(
                            color: ColorPalette.secondaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          bloc.total.toStringAsFixed(2),
                          style: TextStyle(
                            color: ColorPalette.accentText,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            const Gap(25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: PrimaryButton(
                text: "Book Now",
                onClick: () {
                  var bloc = BlocProvider.of<JobOrderBloc>(context);

                  final errors = <String>[];
                  if (_selectedDate == null) {
                    errors.add("Please select schedule.");
                  }
                  if (_selectedLocation == null ||
                      (_selectedAddress ?? '').trim().isEmpty) {
                    errors.add("Please confirm your service location.");
                  }

                  if (errors.isNotEmpty) {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.error,
                      title: "Error",
                      desc: errors.join("\n"),
                    ).show();
                    return;
                  }

                  bloc.add(
                    JoRequestEvent(
                      widget.merchantId,
                      widget.merchantName,
                      _selectedDate!,
                      _selectedLocation!,
                      _selectedAddress!.trim(),
                      _notedController.text,
                    ),
                  );
                },
                width: double.maxFinite,
              ),
            ),
            const Gap(15),
          ],
        ),
      ),
    );
  }
}
