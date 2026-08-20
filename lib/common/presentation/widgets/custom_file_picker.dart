import 'dart:io';
import 'dart:typed_data';

import 'package:client/core/media/upload_preparation.dart';

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
    this.onFilePrepared,
    this.onRejected,
  });

  final String label;
  final String? error;
  final String? value;
  final TextEditingController? controller;
  final void Function(File file)? onFileSelected;

  /// The bytes to actually upload — compressed for an image, untouched for a
  /// document. Optional, so every existing caller keeps working: they read the
  /// `File` and are now simply guaranteed it is within the ceiling.
  final void Function(Uint8List bytes)? onFilePrepared;

  /// Why the file was refused, in copy a customer can act on. A caller that
  /// does not supply this gets the old behaviour minus the file — which is
  /// still better than a 413 reported as a network error.
  final void Function(String message)? onRejected;

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
          final file = File(filePath.files.single.path!);
          final bytes = await file.readAsBytes();

          // Measured against the ceiling before anything is attempted.
          //
          // This picker had NO size limit at all. An oversized file went out
          // and nginx answered 413 — a response that carries no CORS headers,
          // so it reaches the app as a transport failure and gets reported to
          // the customer as a connection problem when their connection is
          // fine. Refusing here says what is actually wrong and what to do.
          //
          // An image is compressed; a PDF is only measured. Rewriting a
          // document the customer chose risks changing what it says, and no
          // size saving is worth that.
          final prepared = UploadCompressor.looksLikeImage(file.path)
              ? UploadCompressor.prepareImage(
                  bytes,
                  budget: UploadBudget.evidencePhoto,
                )
              : UploadCompressor.prepareDocument(
                  bytes,
                  contentType: 'application/octet-stream',
                );

          switch (prepared) {
            case UploadReady(:final bytes):
              onFilePrepared?.call(bytes);
              onFileSelected?.call(file);
            case UploadTooLarge(:final message):
              onRejected?.call(message);
            case UploadUnsupported(:final message):
              onRejected?.call(message);
          }
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
