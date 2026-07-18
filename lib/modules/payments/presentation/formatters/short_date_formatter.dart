import 'package:flutter/services.dart';

class MMYYInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final StringBuffer newText = StringBuffer();

    // Handling deletion
    if (newValue.text.length < oldValue.text.length) {
      for (int i = 0; i < newValue.text.length; i++) {
        if (i == 2) {
          // Don't include '/'
          continue;
        }
        newText.write(newValue.text[i]);
      }
    } else {
      // Handling insertion
      for (int i = 0; i < newValue.text.length; i++) {
        if (i == 2) {
          // Insert '/'
          newText.write('/');
        }
        // If text length is more than 5, don't include additional characters
        if (newText.length >= 5) {
          break;
        }
        if (i < newValue.text.length) {
          newText.write(newValue.text[i]);
        }
      }
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
