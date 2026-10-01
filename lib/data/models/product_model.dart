import 'product_detail_model.dart';

class Product {
  final String id;
  final String name;
  final num price;
  final String image;
  final String? offerId;
  final num storePrice;
  final bool? canBuy;
  final List<ProductSpec> specs;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.offerId,
    this.storePrice = 0,
    this.canBuy,
    this.specs = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?) ?? 0,
      image: json['image']?.toString() ?? '',
      offerId: json['offer_id']?.toString(),
      storePrice: parseNumber(json['store_price']),
      canBuy: parseAvailability(json['can_buy']),
      specs: parseSpecs(json['specs']),
    );
  }
}
