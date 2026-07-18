import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/widgets/custom_text_field.dart';
import 'package:client/common/presentation/widgets/primary_button.dart';
import 'package:client/modules/payments/presentation/formatters/credit_card_number_formatter.dart';
import 'package:client/modules/payments/presentation/formatters/short_date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:u_credit_card/u_credit_card.dart';

class AddCreditCardScreen extends StatefulWidget {
  static String routeName = "AddCreditCardScreen";
  static String route = "AddCreditCardScreen";
  const AddCreditCardScreen({super.key});

  @override
  State<AddCreditCardScreen> createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  final nameController = TextEditingController();
  final cardNumber = TextEditingController();
  final expiry = TextEditingController();
  final cvv = TextEditingController();
  bool isCvvFocused = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
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
                  "Add Credit/Debit card",
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
                physics: const ClampingScrollPhysics(),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      const Gap(20),
                      // AspectRatio(
                      //     aspectRatio: 16 / 9,
                      //     child: ScannerWidget(controller: scannerController)),
                      const Gap(20),
                      GestureDetector(
                        onTap: () async {
                          // var cardDetails = await CardScanner.scanCard();
                          // setState(
                          //   () {
                          //     nameController.text =
                          //         cardDetails?.cardHolderName ?? '';
                          //     cardNumber.text = cardDetails?.cardNumber ?? '';
                          //     expiry.text = cardDetails?.expiryDate ?? '';
                          //   },
                          // );
                        },
                        child: CreditCardUi(
                          cardHolderFullName: nameController.text,
                          placeNfcIconAtTheEnd: true,
                          cardNumber: cardNumber.text,
                          validThru: expiry.text,
                          topLeftColor: ColorPalette.primaryColorDark,
                          cardType: CardType.other,
                          bottomRightColor: ColorPalette.primaryColor,
                        ),
                      ),
                      const Gap(
                        50,
                      ),
                      CustomTextField(
                        label: "Full Name",
                        inputType: TextInputType.name,
                        controller: nameController,
                        onChange: (value) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      CustomTextField(
                        label: "Card Number",
                        inputType: TextInputType.number,
                        controller: cardNumber,
                        maxLength: 22,
                        onChange: (value) {
                          setState(() {});
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CreditCardNumberFormatter(),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: CustomTextField(
                              label: "Expiry",
                              inputType: TextInputType.datetime,
                              controller: expiry,
                              onChange: (value) {
                                setState(() {
                                  isCvvFocused = true;
                                });
                              },
                              maxLength: 5,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                MMYYInputFormatter(),
                              ],
                            ),
                          ),
                          const Gap(20),
                          Flexible(
                            child: CustomTextField(
                              label: "CVV/CVC",
                              inputType: TextInputType.text,
                              controller: cvv,
                              maxLength: 4,
                            ),
                          ),
                        ],
                      ),
                      const Gap(50),
                      SizedBox(
                        width: 200,
                        child: PrimaryButton(
                          text: "Confirm",
                          onClick: () {},
                        ),
                      ),
                    ],
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
