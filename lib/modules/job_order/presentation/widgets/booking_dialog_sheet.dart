import 'dart:io';

import 'package:client/common/data/models/merchant_light.dart';
import 'package:client/modules/homepage/presentation/widgets/merchants_widget.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/helpers/date_time_helper.dart';
import 'package:client/common/helpers/location_helper.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_states.dart';
import 'package:client/modules/job_order/presentation/widgets/employee_list_card.dart';
import 'package:client/modules/job_order/presentation/widgets/service_list_tile_widget.dart';
import 'package:client/modules/messaging/presentation/screens/booking_chat_screen.dart';
import 'package:go_router/go_router.dart';

class BookingDialogSheet extends StatefulWidget {
  const BookingDialogSheet({super.key});

  @override
  State<BookingDialogSheet> createState() => _BookingDialogSheetState();
}

class _BookingDialogSheetState extends State<BookingDialogSheet> {
  final GlobalKey _contentKey = GlobalKey();
  final double _maxChildHeight = .95;

  final _dateFormat = 'EEE MMM. d, yyyy h:mm aa';

  // double _getContentHeight() {
  //   final RenderBox renderBox =
  //       _contentKey.currentContext!.findRenderObject() as RenderBox;
  //   return renderBox.size.height;
  // }

  // void _maxChildSize(BuildContext context) {
  //   double screenHeight = MediaQuery.of(context).size.height;
  //   double contentHeight = _getContentHeight();
  //   double maxChildSize = contentHeight / screenHeight;
  //   maxChildSize = maxChildSize.clamp(0.2, 1.0);
  //   setState(() {
  //     _maxChildHeight = maxChildSize;
  //   });
  // }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .34,
      minChildSize: .34,
      maxChildSize: _maxChildHeight,
      expand: false,
      snap: true,
      snapSizes: [(_maxChildHeight / 2), _maxChildHeight],
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              BlocConsumer<JobOrderBloc, JOState>(
                builder: (context, state) {
                  var bloc = BlocProvider.of<JobOrderBloc>(context);
                  if (bloc.merchant == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorPalette.secondaryBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: MerchantsWidget(
                      merchant: MerchantLight(
                          merchantID: bloc.merchant!.merchantID,
                          merchantName: bloc.merchant!.merchantName,
                          listImage: bloc.merchant!.listImage,
                          rating: bloc.merchant!.rating,
                          latitude: bloc.merchant!.latitude ?? 0,
                          longitude: bloc.merchant!.longitude ?? 0,
                          discounts: []),
                    ),
                  );
                },
                listener: (context, state) {},
              ),
              Container(
                decoration: BoxDecoration(
                  color: ColorPalette.secondaryBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  key: _contentKey,
                  children: [
                    const Gap(20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 5,
                          width: 100,
                          decoration: BoxDecoration(
                            color: ColorPalette.secondaryBorder,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                    const Gap(20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        children: [
                          // Expanded: the Text.rich this builds overflowed the row by 104px at
                          // text scale 1.3. Anchored on the enclosing Row deliberately — the
                          // first BlocConsumer in this file sits in a Column inside a
                          // SingleChildScrollView, where a flex child throws instead.
                          Expanded(
                            child: BlocConsumer<JobOrderBloc, JOState>(
                              listener: (context, state) {
                                // TODO: implement listener
                              },
                              builder: (context, state) {
                                var bloc =
                                    BlocProvider.of<JobOrderBloc>(context);
                                return Text.rich(
                                  TextSpan(
                                    text: "Booking: ",
                                    children: [
                                      TextSpan(
                                        text: bloc.jobOrder?.jobOrderNumber ??
                                            (() {
                                              final id = bloc.jobOrderId;
                                              if (id == null || id.isEmpty) {
                                                return "—";
                                              }
                                              // Avoid RangeError when id is shorter than 10.
                                              final start = id.length > 10
                                                  ? id.length - 10
                                                  : 0;
                                              return id.substring(start);
                                            })(),
                                        style: TextStyle(
                                          color: ColorPalette
                                              .primaryButtonTextColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    color: ColorPalette.secondaryText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                          const Spacer(),
                          BlocConsumer<JobOrderBloc, JOState>(
                            builder: (context, state) {
                              switch (state) {
                                case ReadyJOState():
                                  return Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: ColorPalette.primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "READY",
                                      style: TextStyle(
                                        color: ColorPalette.primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  );
                                case DeployedJOState():
                                  return Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: ColorPalette.primaryColorDark,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "DEPLOYED",
                                      style: TextStyle(
                                        color: ColorPalette.primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  );
                                case InProgressJOState():
                                  return Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: ColorPalette.primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "IN PROGRESS",
                                      style: TextStyle(
                                        color: ColorPalette.primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  );
                                case PausedJOState():
                                  return Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: ColorPalette.primaryColor
                                          .withOpacity(.85),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "PAUSED",
                                      style: TextStyle(
                                        color: ColorPalette.primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  );
                                case TopayJOState():
                                  return Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: ColorPalette.primaryColor
                                          .withOpacity(.85),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "TO PAY",
                                      style: TextStyle(
                                        color: ColorPalette.primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  );
                                case DoneJOState():
                                  return Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: ColorPalette.primaryColorDark,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "COMPLETE",
                                      style: TextStyle(
                                        color: ColorPalette.primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  );
                                default:
                                  return Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: ColorPalette.primaryColor
                                          .withOpacity(.85),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "ACCEPTED",
                                      style: TextStyle(
                                        color: ColorPalette.primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  );
                              }
                            },
                            listener: (context, state) {},
                          ),
                        ],
                      ),
                    ),
                    const Gap(20),
                    BlocConsumer<JobOrderBloc, JOState>(
                      builder: (context, state) {
                        var bloc = BlocProvider.of<JobOrderBloc>(context);

                        if (state is PausedJOState) {
                          return Container(
                            color: ColorPalette.secondaryBorder,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    color: ColorPalette.secondaryBorder,
                                    child: Center(
                                      child: Text(
                                        "Schedule: ${DateFormat(_dateFormat).format(bloc.jobOrder?.scheduleDate ?? DateTime.now())}",
                                        style: TextStyle(
                                          color: ColorPalette.secondaryText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Gap(10),
                                  Text(
                                    "Time Paused:",
                                    style: TextStyle(
                                      color: ColorPalette.secondaryText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  StreamBuilder(
                                      stream: bloc.timer,
                                      builder: (context, snapShot) {
                                        Duration? data = bloc.timePaused
                                            ?.difference((bloc.timeStarted ??
                                                DateTime.now()));
                                        return Text(
                                          DateTimeHelper.formatDuration(
                                              data ?? const Duration(hours: 0)),
                                          style: TextStyle(
                                            color: ColorPalette
                                                .primaryButtonTextColor,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state is DoneJOState ||
                            state is CheckoutJOEvent ||
                            state is TopayJOState) {
                          return Container(
                            color: ColorPalette.secondaryBorder,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    color: ColorPalette.secondaryBorder,
                                    child: Center(
                                      child: Text(
                                        "Schedule: ${DateFormat(_dateFormat).format(bloc.jobOrder?.scheduleDate ?? DateTime.now())}",
                                        style: TextStyle(
                                          color: ColorPalette.secondaryText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Gap(10),
                                  Text(
                                    "Total Time:",
                                    style: TextStyle(
                                      color: ColorPalette.secondaryText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  StreamBuilder(
                                      stream: bloc.timer,
                                      builder: (context, snapShot) {
                                        Duration? data = bloc.timePaused
                                            ?.difference(bloc.timeStarted ??
                                                DateTime.now());
                                        return Text(
                                          DateTimeHelper.formatDuration(
                                              data ?? Duration.zero),
                                          style: TextStyle(
                                            color: ColorPalette
                                                .primaryButtonTextColor,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state is ResumedJOEvent ||
                            state is InProgressJOState) {
                          return Container(
                            color: ColorPalette.secondaryBorder,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    color: ColorPalette.secondaryBorder,
                                    child: Center(
                                      child: Text(
                                        "Schedule: ${DateFormat(_dateFormat).format(bloc.jobOrder?.scheduleDate ?? DateTime.now())}",
                                        style: TextStyle(
                                          color: ColorPalette.secondaryText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Gap(10),
                                  Text(
                                    "Time Elapsed:",
                                    style: TextStyle(
                                      color: ColorPalette.secondaryText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  StreamBuilder(
                                      stream: bloc.timer,
                                      builder: (context, snapShot) {
                                        Duration data =
                                            (snapShot.data as Duration?) ??
                                                const Duration(seconds: 0);
                                        return Text(
                                          DateTimeHelper.formatDuration(data),
                                          style: TextStyle(
                                            color: ColorPalette
                                                .primaryButtonTextColor,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }),
                                ],
                              ),
                            ),
                          );
                        }
                        return Container(
                          color: ColorPalette.secondaryBorder,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 20),
                          child: Center(
                            child: Text(
                              "Schedule: ${DateFormat(_dateFormat).format(bloc.jobOrder?.scheduleDate ?? DateTime.now())}",
                              style: TextStyle(
                                color: ColorPalette.secondaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                      listener: (context, state) {},
                    ),
                    const Gap(15),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: BlocConsumer<JobOrderBloc, JOState>(
                              listener: (context, state) {},
                              builder: (context, state) {
                                var bloc =
                                    BlocProvider.of<JobOrderBloc>(context);
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    const Gap(10),
                                    // CarouselImagePicker(
                                    //   onImagePicked: (file) {
                                    //     var photo = JOPhotoModel(
                                    //       isFromMerchant: true,
                                    //       photoFile: XFile(file.path),
                                    //     );
                                    //     bloc.add(AddedPhotoJOEvent(photo));
                                    //   },
                                    // ),
                                    // const Gap(10),
                                    ...bloc.joPhotos.map(
                                      (e) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
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
                                                    color: ColorPalette
                                                        .primaryColor
                                                        .withOpacity(.5),
                                                    child: Center(
                                                      child: Text(
                                                        "Added by Merchant",
                                                        style: TextStyle(
                                                          color: ColorPalette
                                                              .primaryText
                                                              .withOpacity(.7),
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPalette.primaryColor,
                            foregroundColor:
                                ColorPalette.primaryButtonTextColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            final bloc = BlocProvider.of<JobOrderBloc>(context);
                            final jo = bloc.jobOrder;
                            if (jo == null) return;
                            context.pushNamed(
                              BookingChatScreen.routeName,
                              pathParameters: {"jobOrderId": jo.jobOrderID},
                              extra: bloc.merchant?.merchantName,
                            );
                          },
                          icon: const Icon(Icons.message_rounded),
                          label: Text(
                            "Message provider",
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(15),
                    BlocConsumer<JobOrderBloc, JOState>(
                      listener: (context, state) {
                        // TODO: implement listener
                      },
                      builder: (context, state) {
                        var bloc = BlocProvider.of<JobOrderBloc>(context);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              // Expanded: 386px of overflow at 1.3 — the longest label in this sheet.
                              Expanded(
                                child: Text(
                                  "Distance From Office: ${bloc.jobOrder?.distanceFromOffice.toStringAsFixed(1)} km",
                                  style: TextStyle(
                                    color: ColorPalette.secondaryText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Gap(15),
                    Row(
                      children: [
                        Expanded(
                          child: BlocConsumer<JobOrderBloc, JOState>(
                            listener: (context, state) {
                              // TODO: implement listener
                            },
                            builder: (context, state) {
                              var bloc = BlocProvider.of<JobOrderBloc>(context);
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      ColorPalette.primaryColor.withOpacity(.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  "Note: ${bloc.jobOrder?.note ?? 'No notes'}",
                                  style: TextStyle(
                                    color: ColorPalette.secondaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const Gap(15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Container(
                        width: double.maxFinite,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: ColorPalette.secondaryAccentColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: LayoutBuilder(builder: (context, constraints) {
                          return Column(
                            children: [
                              const Gap(5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Expanded: 36px of overflow at text scale 2.0.
                                  Expanded(
                                    child: Text(
                                      "Services",
                                      style: TextStyle(
                                        fontFamily:
                                            FontPalette.primaryFontFamily,
                                        fontWeight: FontWeight.bold,
                                        color: ColorPalette.secondaryText,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                color: ColorPalette.secondaryAccentColor,
                                thickness: 1,
                              ),
                              BlocConsumer<JobOrderBloc, JOState>(
                                listener: (context, state) {},
                                builder: (context, state) {
                                  var bloc =
                                      BlocProvider.of<JobOrderBloc>(context);
                                  return Column(
                                    children: bloc.joServices
                                        .map(
                                          (e) => ServiceListTile(
                                            size: Size(constraints.maxWidth,
                                                constraints.maxHeight),
                                            isServiceAddedByMerchant: false,
                                            // e.addedByMerchant,
                                            servicePrice: e.amount,
                                            jobOrderItemId:
                                                e.jobOrderItemID.toString(),
                                            serviceName: e.serviceName,
                                            optionItems: e.selectedOptions,
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                              const Gap(10),
                            ],
                          );
                        }),
                      ),
                    ),
                    const Gap(20),
                    BlocConsumer<JobOrderBloc, JOState>(
                      listener: (context, state) {},
                      builder: (context, state) {
                        var bloc = BlocProvider.of<JobOrderBloc>(context);
                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Row(
                                children: [
                                  // Expanded: this label overflowed its row by 59px at text scale 1.3.
                                  Expanded(
                                    child: Text(
                                      "Subtotal:",
                                      style: TextStyle(
                                        color: ColorPalette.secondaryText,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    LocationHelper.localizedPrice(
                                        bloc.subtotal),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Row(
                                children: [
                                  // Expanded: 95px of overflow.
                                  Expanded(
                                    child: Text(
                                      "Transportation:",
                                      style: TextStyle(
                                        color: ColorPalette.secondaryText,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    LocationHelper.localizedPrice(
                                        bloc.transportation),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Row(
                                children: [
                                  // Expanded: 246px of overflow at text scale 2.0.
                                  Expanded(
                                    child: Text(
                                      "Discount:",
                                      style: TextStyle(
                                        color: ColorPalette.secondaryText,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    LocationHelper.localizedPrice(0),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Row(
                                children: [
                                  // Expanded: 37px of overflow.
                                  Expanded(
                                    child: Text(
                                      "Downpayment:",
                                      style: TextStyle(
                                        color: ColorPalette.secondaryText,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    LocationHelper.localizedPrice(0),
                                    style: TextStyle(
                                      color: ColorPalette.secondaryText,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 19,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(10),
                            DottedLine(
                              direction: Axis.horizontal,
                              lineLength: double.infinity,
                              lineThickness: 2.0,
                              dashColor: ColorPalette.accentText,
                            ),
                            const Gap(5),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Row(
                                children: [
                                  // Expanded: 153px of overflow at text scale 2.0.
                                  Expanded(
                                    child: Text(
                                      "Total:",
                                      style: TextStyle(
                                        color: ColorPalette.secondaryText,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    LocationHelper.localizedPrice(bloc.total),
                                    style: TextStyle(
                                      color:
                                          ColorPalette.primaryButtonTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        );
                      },
                    ),
                    const Gap(5),
                    DottedLine(
                      direction: Axis.horizontal,
                      lineLength: double.infinity,
                      lineThickness: 2.0,
                      dashColor: ColorPalette.accentText,
                    ),
                    const Gap(5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Expanded: 106px of overflow.
                          Expanded(
                            child: Text(
                              "Payment:",
                              style: TextStyle(
                                color: ColorPalette.secondaryText,
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Gap(10),
                          Image.asset(
                            "assets/icons/cash.png",
                            width: 20,
                            fit: BoxFit.contain,
                          ),
                          const Gap(5),
                          // Flexible as well. "Payment:" is already Expanded,
                          // but this value grows too, so the row was still 13px
                          // over at text scale 1.3. Bounding only one side of a
                          // row leaves the other free to overflow it.
                          Flexible(
                            child: Text(
                              "Cash on Site",
                              style: TextStyle(
                                color: ColorPalette.secondaryText,
                                fontWeight: FontWeight.w500,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      color: ColorPalette.accentText,
                    ),
                    const Gap(15),
                    BlocConsumer<JobOrderBloc, JOState>(
                      builder: (context, state) {
                        var bloc = BlocProvider.of<JobOrderBloc>(context);
                        if (bloc.assignedPersonel.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              children: [
                                // Expanded: 135px of overflow.
                                Expanded(
                                  child: Text(
                                    "No assigned personnel",
                                    style: TextStyle(
                                      color: ColorPalette.secondaryText,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            children: [
                              Text(
                                "Assigned Personnel:",
                                style: TextStyle(
                                  color: ColorPalette.secondaryText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      listener: (BuildContext context, JOState state) {},
                    ),
                    const Gap(5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: BlocConsumer<JobOrderBloc, JOState>(
                          builder: (context, state) {
                            var bloc = BlocProvider.of<JobOrderBloc>(context);
                            return Column(
                              children: bloc.assignedPersonel
                                  .map(
                                    (e) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 15),
                                      child: EmployeeListCard(
                                        name: e.fullname,
                                        contactNo: e.contactNumber,
                                        photoUrl: e.profilePictureURL,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                          listener: (context, state) {}),
                    ),
                    const Gap(200),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
