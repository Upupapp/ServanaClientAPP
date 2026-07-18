import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_events.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SelectPaymentMethodScreen extends StatefulWidget {
  static String routeName = "SelectPaymentMethodScreen";
  static String route = "SelectPaymentMethodScreen";
  const SelectPaymentMethodScreen({super.key});

  @override
  State<SelectPaymentMethodScreen> createState() =>
      _SelectPaymentMethodScreenState();
}

class _SelectPaymentMethodScreenState extends State<SelectPaymentMethodScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<JobOrderBloc, JOState>(listener: (context, state) {
          // TODO: implement listener
        }, builder: (context, state) {
          final bloc = BlocProvider.of<JobOrderBloc>(context);
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
                    "Select Payment Method",
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
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      // Row(
                      //   children: [
                      //     Flexible(
                      //       child: Text(
                      //         "Enter your personal information to create your merchant account.",
                      //         maxLines: 4,
                      //         style: TextStyle(
                      //           fontFamily: FontPalette.primaryFontFamily,
                      //           color: ColorPalette.secondaryText,
                      //           fontSize: 15,
                      //         ),
                      //       ),
                      //     ),
                      //     const SizedBox(
                      //       width: 25,
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(
                        height: 25,
                      ),
                      ListTile(
                        onTap: () {
                          // bloc.mop = MOP.CCDB;
                        },
                        title: const Text(
                          "Credit/Debit Card",
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        trailing: Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: bloc.paymentMethod == "card",
                            checkColor: ColorPalette.primaryText,
                            activeColor: ColorPalette.primaryColor,
                            shape: const CircleBorder(),
                            onChanged: (value) {
                              bloc.add(const UpdatedPaymentMethodJOEvent(
                                "card",
                              ));
                            },
                          ),
                        ),
                        leading: Icon(
                          Icons.credit_card,
                          size: 30,
                          color: ColorPalette.primaryColor,
                        ),
                      ),
                      ListTile(
                        onTap: () {
                          // bloc.mop = MOP.CCDB;
                        },
                        title: const Text(
                          "GCASH",
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        trailing: Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: bloc.paymentMethod == "gcash",
                            checkColor: ColorPalette.primaryText,
                            activeColor: ColorPalette.primaryColor,
                            shape: const CircleBorder(),
                            onChanged: (value) {
                              bloc.add(const UpdatedPaymentMethodJOEvent(
                                "gcash",
                              ));
                            },
                          ),
                        ),
                        leading: Image.asset(
                          "assets/payment_icons/gcash-logo.png",
                          width: 30,
                        ),
                      ),
                      ListTile(
                        onTap: () {
                          // bloc.mop = MOP.CCDB;
                        },
                        title: const Text(
                          "Maya",
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        trailing: Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: bloc.paymentMethod == "maya",
                            checkColor: ColorPalette.primaryText,
                            activeColor: ColorPalette.primaryColor,
                            shape: const CircleBorder(),
                            onChanged: (value) {
                              bloc.add(const UpdatedPaymentMethodJOEvent(
                                "maya",
                              ));
                            },
                          ),
                        ),
                        leading: Image.asset(
                          "assets/payment_icons/maya.png",
                          width: 30,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 200,
                        child: PrimaryButton(
                          text: "Confirm",
                          onClick: () {
                            // Return to JobOrderScreen after selecting a payment method.
                            context.pop();
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        }),
      ),
    );
  }
}
