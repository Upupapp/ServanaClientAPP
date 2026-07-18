import 'package:client/modules/homepage/presentation/screens/home_screen.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:quickalert/models/quickalert_animtype.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_states.dart';
import 'package:client/modules/job_order/presentation/widgets/qr_done_dialog.dart';

class QRPaymentScreen extends StatefulWidget {
  static String routeName = "QRPaymentScreen";
  static String route = "QRPaymentScreen";
  const QRPaymentScreen({super.key});

  @override
  State<QRPaymentScreen> createState() => _QRPaymentScreenState();
}

class _QRPaymentScreenState extends State<QRPaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<JobOrderBloc, JOState>(
          listener: (context, state) {
            // TODO: implement listener
          },
          builder: (context, state) {
            var bloc = BlocProvider.of<JobOrderBloc>(context);
            return Column(
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
                  children: [
                    const SizedBox(
                      width: 25,
                    ),
                    Text(
                      "QR PH",
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "Scan on any banking or wallet apps that supports QR PH.",
                                  maxLines: 4,
                                  style: TextStyle(
                                    fontFamily: FontPalette.primaryFontFamily,
                                    color: ColorPalette.secondaryText,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 25,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 50),
                            child: GestureDetector(
                              onLongPress: () {
                                QuickAlert.show(
                                  context: context,
                                  type: QuickAlertType.success,
                                  animType: QuickAlertAnimType.scale,
                                  barrierDismissible: false,
                                  confirmBtnColor: ColorPalette.primaryColor,
                                  disableBackBtn: true,
                                  confirmBtnTextStyle: TextStyle(
                                    color: ColorPalette.primaryButtonTextColor,
                                  ),
                                  onConfirmBtnTap: () {
                                    bloc.add(const DoneJOEvent(1));
                                    context.goNamed(HomeScreen.routeName);
                                  },
                                  text: "Payment Success!",
                                );
                              },
                              child: Image.asset(
                                "assets/icons/qr_ph.png",
                              ),
                            ),
                          ),
                          const Gap(50),
                          Row(
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
                                "600.00",
                                style: TextStyle(
                                  color: ColorPalette.secondaryText,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 19,
                                ),
                              ),
                            ],
                          ),
                          Row(
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
                                "200.00",
                                style: TextStyle(
                                  color: ColorPalette.secondaryText,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 19,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Discount:",
                                style: TextStyle(
                                  color: ColorPalette.secondaryText,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "- 100.00",
                                style: TextStyle(
                                  color: ColorPalette.secondaryText,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 19,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Downpayment:",
                                style: TextStyle(
                                  color: ColorPalette.secondaryText,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "- 300.00",
                                style: TextStyle(
                                  color: ColorPalette.secondaryText,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 19,
                                ),
                              ),
                            ],
                          ),
                          const Gap(10),
                          DottedLine(
                            direction: Axis.horizontal,
                            lineLength: double.infinity,
                            lineThickness: 2.0,
                            dashColor: ColorPalette.accentText,
                          ),
                          const Gap(5),
                          Row(
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
                                "400",
                                style: TextStyle(
                                  color: ColorPalette.primaryButtonTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                PrimaryButton(
                  width: 250,
                  text: "Done",
                  onClick: () {
                    QRDoneDialog.showDialog(
                      context: context,
                      onConfirm: () {
                        bloc.add(const DoneJOEvent(1));
                        context.goNamed(HomeScreen.routeName);
                      },
                    );
                  },
                ),
                const Gap(25),
              ],
            );
          },
        ),
      ),
    );
  }
}
