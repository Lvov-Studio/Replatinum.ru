class Product {
  final String id;
  final String name;
  final num price;
  final String image;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?) ?? 0,
      image: json['image']?.toString() ?? '',
    );
  }
}
