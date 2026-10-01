import 'product_detail_model.dart';

class CartQuote {
  final String id, promotionName, hint;
  final int subtotalMinor, discountMinor, totalMinor;
  final Map<String, num> unitPrices;

  const CartQuote({
    required this.id,
    required this.subtotalMinor,
    required this.discountMinor,
    required this.totalMinor,
    this.promotionName = '',
    this.hint = '',
    this.unitPrices = const {},
  });

  factory CartQuote.fromJson(Map<String, dynamic> json) {
    if (json['currency'] != 'RUB' ||
        '${json['quote_id'] ?? ''}'.isEmpty ||
        json['items'] is! List) {
      throw const FormatException('Invalid cart quote');
    }
    final subtotal = parseNumber(json['subtotal_minor']).toInt();
    final discount = parseNumber(json['discount_minor']).toInt();
    final total = parseNumber(json['total_minor']).toInt();
    if (subtotal < 0 || discount < 0 || total != subtotal - discount) {
      throw const FormatException('Invalid cart total');
    }
    return CartQuote(
      id: json['quote_id'],
      subtotalMinor: subtotal,
      discountMinor: discount,
      totalMinor: total,
      promotionName: '${json['promotion_name'] ?? ''}',
      hint: '${json['hint'] ?? ''}',
      unitPrices: {
        for (final item in json['items'])
          '${item['id']}': parseNumber(item['unit_price_minor']) / 100,
      },
    );
  }
}
