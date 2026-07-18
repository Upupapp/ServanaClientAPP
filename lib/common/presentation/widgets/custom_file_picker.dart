import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:client/common/constants/color_palette.dart';

class CustomFilePicker extends StatelessWidget {
  const CustomFilePicker({
    super.key,
    this.label = "Pick File",
    this.onFileSelected,
    this.error,
    this.value,
    this.controller,
  });

  final String label;
  final String? error;
  final String? value;
  final TextEditingController? controller;
  final void Function(File file)? onFileSelected;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      canRequestFocus: false,
      controller: controller,
      initialValue: value,
      onTap: () async {
        FilePickerResult? filePath = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: false,
          allowedExtensions: ['jpg', 'pdf', 'doc', 'png'],
        );
        if (filePath != null) {
          // ignore: unused_local_variable
          File file = File(filePath.files.single.path!);

          onFileSelected?.call(file);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        suffixIcon: Icon(
          Icons.upload_file,
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
