import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/features/account/ui/russian_phone_formatter.dart';

void main() {
  const mask = RussianPhoneFormatter();
  TextEditingValue value(String text) => TextEditingValue(
      text: text, selection: TextSelection.collapsed(offset: text.length));
  test('normalizes pasted +7, 8 and national numbers to the same mask', () {
    for (final text in [
      '+79991234567',
      '89991234567',
      '9991234567',
      '+7 (999) 123-45-67'
    ]) {
      final result = mask.formatEditUpdate(value('+7 '), value(text));
      expect(result.text, '+7 (999) 123-45-67');
      expect(result.selection.baseOffset, result.text.length);
    }
  });
  test('keeps +7, formats typing, deletion and mid-number editing', () {
    expect(mask.formatEditUpdate(value('+7 '), value('')).text, '+7 ');
    var current = value('+7 ');
    for (final digit in '9991234567'.split('')) {
      current = mask.formatEditUpdate(current, value(current.text + digit));
    }
    expect(current.text, '+7 (999) 123-45-67');
    final removed = mask.formatEditUpdate(
        current, value(current.text.substring(0, current.text.length - 1)));
    expect(removed.text, '+7 (999) 123-45-6');
    final separator = mask.formatEditUpdate(
        value('+7 (999) 1'),
        const TextEditingValue(
            text: '+7 (999)1', selection: TextSelection.collapsed(offset: 8)));
    expect(separator.text, '+7 (991');
  });
}
