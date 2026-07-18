import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:client/common/constants/color_palette.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.label,
    this.onChange,
    this.onEditingComplete,
    this.controller,
    this.leading,
    this.trailing,
    this.action,
    this.inputType,
    this.obscureText = false,
    this.error,
    this.value,
    this.maxLines = 1,
    this.inputFormatters,
    this.focusNode,
    this.gKey,
    this.borderRadius = 12,
    this.maxLength,
    this.enabled = true,
  });

  final String? label;
  final GlobalKey? gKey;
  final double borderRadius;
  final String? error;
  final String? value;
  final void Function(String value)? onChange;
  final void Function()? onEditingComplete;
  final TextEditingController? controller;
  final Widget? leading;
  final Widget? trailing;
  final TextInputAction? action;
  final int maxLines;
  final int? maxLength;
  final TextInputType? inputType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      key: gKey,
      focusNode: focusNode,
      onChanged: onChange,
      textInputAction: action,
      enabled: enabled,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: 1,
      onEditingComplete: onEditingComplete,
      keyboardType: inputType,
      obscureText: obscureText,
      initialValue: value,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: leading,
        suffixIcon: trailing,
        counter: const SizedBox.shrink(),
        errorText: error,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: ColorPalette.secondaryAccentColor,
          ),
        ),
      ),
    );
  }
}
