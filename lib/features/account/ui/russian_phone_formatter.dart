import 'package:flutter/services.dart';

class RussianPhoneFormatter extends TextInputFormatter {
  const RussianPhoneFormatter();
  static const prefix = '+7 ';
  static const pattern = '(###) ###-##-##';
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final hasCountry = newValue.text.trimLeft().startsWith('+7') ||
        (digits.length == 11 &&
            (digits.startsWith('7') || digits.startsWith('8')));
    final cursor = newValue.selection.baseOffset < 0
        ? newValue.text.length
        : newValue.selection.baseOffset.clamp(0, newValue.text.length);
    var before =
        newValue.text.substring(0, cursor).replaceAll(RegExp(r'\D'), '').length;
    if (hasCountry && digits.isNotEmpty) {
      digits = digits.substring(1);
      before--;
    }
    if (digits.length > 10) digits = digits.substring(0, 10);
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final oldNational = oldValue.text.startsWith('+7') && oldDigits.isNotEmpty
        ? oldDigits.substring(1)
        : oldDigits;
    // Backspacing a separator should erase the preceding digit, not trap the caret.
    if (newValue.text.length < oldValue.text.length &&
        digits == oldNational &&
        before > 0) {
      final index = (before - 1).clamp(0, digits.length - 1);
      digits = digits.substring(0, index) + digits.substring(index + 1);
      before--;
    }
    final text = StringBuffer(prefix);
    var index = 0, caret = prefix.length;
    for (final char in pattern.split('')) {
      if (index >= digits.length) break;
      if (char == '#') {
        text.write(digits[index++]);
        if (index <= before) caret = text.length;
      } else {
        text.write(char);
      }
    }
    return TextEditingValue(
        text: text.toString(),
        selection: TextSelection.collapsed(
            offset: caret.clamp(prefix.length, text.length)));
  }
}
