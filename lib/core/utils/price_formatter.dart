String formatPrice(num price) {
  final digits = price.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('\u00A0');
    }
    buffer.write(digits[index]);
  }
  return '${buffer.toString()} ₽';
}
