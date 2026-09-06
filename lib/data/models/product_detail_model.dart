class OfferProperty {
  final String code;
  final String name;
  final String value;

  const OfferProperty({
    required this.code,
    required this.name,
    required this.value,
  });

  factory OfferProperty.fromJson(Map<String, dynamic> json) => OfferProperty(
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
      );
}

class Offer {
  final String id;
  final String name;
  final String image;
  final num price;
  final List<OfferProperty> properties;

  const Offer({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.properties,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        price: json['price'] is num ? json['price'] : num.tryParse(json['price'].toString()) ?? 0,
        properties: json['properties'] is List
            ? (json['properties'] as List)
                .map((p) => OfferProperty.fromJson(p as Map<String, dynamic>))
                .toList()
            : [],
      );

  /// Значение свойства по коду
  String? valueOf(String code) {
    try {
      return properties.firstWhere((p) => p.code == code).value;
    } catch (_) {
      return null;
    }
  }
}

class ProductDetail {
  final String id;
  final String name;
  final num price;
  final String description;
  final List<String> images;
  final List<Offer> offers;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.images,
    required this.offers,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    // Фото
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List)
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
      parsedImages.add(json['image'].toString());
    }

    // Цена
    final rawPrice = json['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice
        : num.tryParse(rawPrice?.toString() ?? '') ?? 0;

    // Офферы
    final List<Offer> parsedOffers = [];
    if (json['offers'] is List) {
      for (final o in json['offers'] as List) {
        parsedOffers.add(Offer.fromJson(o as Map<String, dynamic>));
      }
    }

    // Если у товара нет своих фото — берём из офферов
    if (parsedImages.isEmpty) {
      for (final offer in parsedOffers) {
        if (offer.image.isNotEmpty) {
          parsedImages.add(offer.image);
          break;
        }
      }
    }

    return ProductDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: parsedPrice,
      description: json['description']?.toString() ?? 'Описание отсутствует',
      images: parsedImages,
      offers: parsedOffers,
    );
  }
}
