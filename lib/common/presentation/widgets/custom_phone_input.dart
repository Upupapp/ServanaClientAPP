import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:client/common/constants/color_palette.dart';

class CustomPhoneInput extends StatelessWidget {
  const CustomPhoneInput({
    super.key,
    this.label = 'Phone Number',
    this.onChange,
    this.onEditingComplete,
    this.controller,
    this.onCountryChange,
    this.error,
    this.value,
  });

  final String label;
  final String? error;
  final String? value;
  final void Function(PhoneNumber value)? onChange;
  final void Function()? onEditingComplete;
  final TextEditingController? controller;
  final void Function(Country value)? onCountryChange;

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ColorPalette.secondaryAccentColor,
          ),
        ),
      ),
      initialCountryCode: 'PH',
      onChanged: onChange,
      onCountryChanged: onCountryChange,
      controller: controller,
    );
  }
}
