import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_states.dart';
import 'package:client/modules/job_order/presentation/screens/cash_payment_screen.dart';
import 'package:client/modules/job_order/presentation/screens/qr_payment_screen.dart';
import 'package:client/modules/job_order/presentation/widgets/chip_container.dart';
import 'package:client/modules/job_order/presentation/widgets/payment_method_card.dart';

class CheckoutJobOrderScreen extends StatefulWidget {
  static String routeName = "CheckoutJobOrderScreen";
  static String route = "CheckoutJobOrderScreen";
  const CheckoutJobOrderScreen({super.key});

  @override
  State<CheckoutJobOrderScreen> createState() => _CheckoutJobOrderScreenState();
}

class _CheckoutJobOrderScreenState extends State<CheckoutJobOrderScreen> {
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
                      "Payment method",
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
                                  "Select Payment Method to pay balance on final bill.",
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
                          Row(
                            children: [
                              Text(
                                "Wallet",
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  fontWeight: FontWeight.bold,
                                  color: ColorPalette.accentText,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          const Gap(10),
                          Row(children: [
                            ChipContainer(
                              imageIcon: "assets/payment_icons/maya.png",
                              isSelected: bloc.paymentMethod == "maya",
                              onTap: () {
                                bloc.add(
                                    const UpdatedPaymentMethodJOEvent("maya"));
                              },
                            ),
                            const Gap(10),
                            ChipContainer(
                              imageIcon: "assets/payment_icons/gcash.png",
                              isSelected: bloc.paymentMethod == "gcash",
                              padding: const EdgeInsets.only(
                                  top: 8, bottom: 8, right: 10, left: 10),
                              size: 20,
                              onTap: () {
                                bloc.add(
                                    const UpdatedPaymentMethodJOEvent("gcash"));
                              },
                            ),
                            const Gap(10),
                            ChipContainer(
                              imageIcon: "assets/payment_icons/grab_pay.png",
                              isSelected: bloc.paymentMethod == "grab_pay",
                              padding: const EdgeInsets.only(
                                  top: 4, bottom: 2, right: 10, left: 10),
                              size: 30,
                              onTap: () {
                                bloc.add(const UpdatedPaymentMethodJOEvent(
                                    "grab_pay"));
                              },
                            ),
                          ]),
                          const SizedBox(
                            height: 25,
                          ),
                          Row(
                            children: [
                              Text(
                                "Others",
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  fontWeight: FontWeight.bold,
                                  color: ColorPalette.accentText,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          const Gap(10),
                          PaymentMethodCard(
                            name: "Cash",
                            icon: Image.asset("assets/icons/cash.png"),
                            value: (bloc.paymentMethod == "cash"),
                            onToggle: (value) {
                              bloc.add(
                                  const UpdatedPaymentMethodJOEvent("cash"));
                            },
                          ),
                          const Gap(15),
                          PaymentMethodCard(
                            name: "QR PH",
                            icon: Image.asset("assets/icons/scanner_dark.png"),
                            value: (bloc.paymentMethod == "qrph"),
                            onToggle: (value) {
                              bloc.add(
                                  const UpdatedPaymentMethodJOEvent("qrph"));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                PrimaryButton(
                  width: 250,
                  text: "Continue",
                  trailing: Icon(
                    Icons.arrow_forward,
                    size: 17,
                    color: ColorPalette.primaryButtonTextColor,
                  ),
                  onClick: () {
                    switch (bloc.paymentMethod) {
                      case "cash":
                        context.goNamed(CashPaymentScreen.routeName);
                        break;
                      default:
                        context.goNamed(QRPaymentScreen.routeName);
                        break;
                    }
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
