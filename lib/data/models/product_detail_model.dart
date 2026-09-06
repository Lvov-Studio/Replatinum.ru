class ProductDetail {
  final String id;
  final String name;
  final String price;
  final String description;
  final List<String> images;

  ProductDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.images,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    // Безопасный парсинг списка картинок (иногда может быть null или строкой)
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
      // Если массива images нет, но есть одно image
      parsedImages.add(json['image'].toString());
    }

    return ProductDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      description: json['description']?.toString() ?? 'Описание отсутствует',
      images: parsedImages,
    );
  }
}
