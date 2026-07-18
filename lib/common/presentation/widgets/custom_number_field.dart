import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:client/common/constants/color_palette.dart';

class CustomNumberField extends StatefulWidget {
  const CustomNumberField({
    super.key,
    this.label,
    this.onChange,
    this.onEditingComplete,
    this.controller,
    this.action,
    this.inputType,
    this.obscureText = false,
    this.error,
    this.value = 0,
    this.maxLines = 1,
  });

  final String? label;
  final String? error;
  final int value;
  final void Function(int? value)? onChange;
  final void Function()? onEditingComplete;
  final TextEditingController? controller;
  final TextInputAction? action;
  final int maxLines;
  final TextInputType? inputType;
  final bool obscureText;

  @override
  State<CustomNumberField> createState() => _CustomNumberFieldState();
}

class _CustomNumberFieldState extends State<CustomNumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    _controller = widget.controller ??
        TextEditingController(text: widget.value.toString());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      onChanged: (value) {
        var val = int.tryParse(value) ?? 0;
        widget.onChange?.call(val);
      },
      textInputAction: widget.action,
      maxLines: widget.maxLines,
      minLines: 1,
      onEditingComplete: widget.onEditingComplete,
      keyboardType: TextInputType.number,
      obscureText: widget.obscureText,
      textAlignVertical: TextAlignVertical.center,
      textAlign: TextAlign.center,
      maxLength: 3,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: InputDecoration(
        labelText: widget.label,
        contentPadding:
            const EdgeInsets.only(left: 10, right: 5, top: 10, bottom: 10),
        suffixIconConstraints: const BoxConstraints(maxWidth: 21),
        counter: const SizedBox.shrink(),
        suffixIcon: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                int currentVal = int.tryParse(_controller.text) ?? 0;
                int newVal = currentVal + 1;
                _controller.text = newVal.toString();
                widget.onChange?.call(newVal);
              },
              child: RotatedBox(
                quarterTurns: 1,
                child: Icon(
                  Icons.chevron_left,
                  color: ColorPalette.primaryColorDark,
                  size: 25,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                int currentVal = int.tryParse(_controller.text) ?? 0;
                int newVal = (currentVal > 0) ? (currentVal - 1) : 0;
                _controller.text = newVal.toString();
                widget.onChange?.call(newVal);
              },
              child: RotatedBox(
                quarterTurns: 1,
                child: Icon(
                  Icons.chevron_right,
                  color: ColorPalette.primaryColorDark,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
        errorText: widget.error,
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
