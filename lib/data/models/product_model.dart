import 'product_detail_model.dart';

class Product {
  final String id;
  final String name;
  final num price;
  final String image;
  final String? offerId;
  final num storePrice;
  final bool? canBuy;
  final bool ruStoreWarning;
  final List<ProductSpec> specs;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.offerId,
    this.storePrice = 0,
    this.canBuy,
    this.ruStoreWarning = false,
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
      ruStoreWarning: json['rustore_warning'] == true,
      specs: parseSpecs(json['specs']),
    );
  }

  Product copyWith({bool? ruStoreWarning}) => Product(
      id: id,
      name: name,
      price: price,
      image: image,
      offerId: offerId,
      storePrice: storePrice,
      canBuy: canBuy,
      specs: specs,
      ruStoreWarning: ruStoreWarning ?? this.ruStoreWarning);
}
