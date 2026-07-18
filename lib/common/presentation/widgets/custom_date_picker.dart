import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:client/common/constants/color_palette.dart';

class CustomDateTimePicker extends StatelessWidget {
  const CustomDateTimePicker({
    super.key,
    this.label = "Pick Date and Time",
    this.onFileSelected,
    this.error,
    this.value,
    this.controller,
  });

  final String label;
  final String? error;
  final DateTime? value;
  final TextEditingController? controller;
  final void Function(File file)? onFileSelected;

  @override
  Widget build(BuildContext context) {
    var dateTimeFormat = DateFormat("MMM d, y, j:ma");
    var formattedDateTime = dateTimeFormat.format(DateTime.now());
    if (value != null) {
      formattedDateTime = dateTimeFormat.format(value!);
    }
    return TextFormField(
      readOnly: true,
      canRequestFocus: false,
      controller: controller,
      initialValue: formattedDateTime,
      onTap: () async {},
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        suffixIcon: Icon(
          Icons.calendar_month,
          color: ColorPalette.primaryColorDark,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ColorPalette.secondaryAccentColor,
          ),
        ),
      ),
    );
  }
}
