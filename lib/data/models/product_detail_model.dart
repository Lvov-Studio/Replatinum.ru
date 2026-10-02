num parseNumber(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
bool? parseAvailability(dynamic v) => switch (v) {
      true || 'Y' || 1 => true,
      false || 'N' || 0 => false,
      _ => null
    };
List<String> parseImages(dynamic v) => v is List
    ? v.map((e) => '$e').where((e) => e.isNotEmpty).toSet().toList()
    : [];

class OfferProperty {
  final String code, name, value, image;
  const OfferProperty(
      {required this.code,
      required this.name,
      required this.value,
      this.image = ''});
  factory OfferProperty.fromJson(Map<String, dynamic> j) => OfferProperty(
      code: '${j['code'] ?? ''}',
      name: '${j['name'] ?? ''}',
      value: j['value'] is List
          ? (j['value'] as List).join(' / ')
          : '${j['value'] ?? ''}',
      image: '${j['image'] ?? ''}');
}

class ProductSpec {
  final String name, value, group, code;
  const ProductSpec(
      {required this.name,
      required this.value,
      this.code = '',
      this.group = 'Общие характеристики'});
  factory ProductSpec.fromJson(Map<String, dynamic> j) => ProductSpec(
      name: '${j['name'] ?? ''}',
      code: '${j['code'] ?? ''}',
      value: '${j['value'] ?? ''}',
      group: '${j['group'] ?? 'Общие характеристики'}');
}

List<ProductSpec> parseSpecs(dynamic j) => j is List
    ? j.map((e) => ProductSpec.fromJson(Map<String, dynamic>.from(e))).toList()
    : [];

class Offer {
  final String id, name, image, description;
  final num price, storePrice;
  final bool? canBuy;
  final List<String> images;
  final List<ProductSpec> specs;
  final List<OfferProperty> properties;
  const Offer(
      {required this.id,
      required this.name,
      required this.image,
      required this.price,
      required this.properties,
      this.storePrice = 0,
      this.canBuy,
      this.description = '',
      this.images = const [],
      this.specs = const []});
  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
      id: '${j['id'] ?? ''}',
      name: '${j['name'] ?? ''}',
      image: '${j['image'] ?? ''}',
      price: parseNumber(j['price']),
      storePrice: parseNumber(j['store_price']),
      canBuy: parseAvailability(j['can_buy']),
      description: '${j['description'] ?? ''}',
      images: parseImages(j['images']),
      specs: parseSpecs(j['specs']),
      properties: j['properties'] is List
          ? (j['properties'] as List)
              .map((e) => OfferProperty.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : []);
  String? valueOf(String code) {
    for (final p in properties) {
      if (p.code == code) return p.value;
    }
    return null;
  }
}

class ProductDetail {
  final String id, name, description, url, promoName;
  final num price, storePrice;
  final bool? canBuy;
  final bool ruStoreWarning;
  final List<String> images;
  final List<Offer> offers;
  final List<ProductSpec> specs;
  final List<(int, num)> promoTiers;
  final List<String> basketAccessoryIds;
  const ProductDetail(
      {required this.id,
      required this.name,
      required this.price,
      required this.description,
      required this.images,
      required this.offers,
      this.storePrice = 0,
      this.canBuy,
      this.url = '',
      this.ruStoreWarning = false,
      this.specs = const [],
      this.promoName = '',
      this.promoTiers = const [],
      this.basketAccessoryIds = const []});
  factory ProductDetail.fromJson(Map<String, dynamic> j) {
    final images = parseImages(j['images']);
    if (images.isEmpty && '${j['image'] ?? ''}'.isNotEmpty) {
      images.add('${j['image']}');
    }
    final promo = j['promotion'] is Map ? j['promotion'] as Map : const {};
    return ProductDetail(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        price: parseNumber(j['price']),
        storePrice: parseNumber(j['store_price']),
        canBuy: parseAvailability(j['can_buy']),
        description: '${j['description'] ?? ''}',
        url: '${j['url'] ?? ''}',
        ruStoreWarning: j['rustore_warning'] == true,
        images: images,
        offers: j['offers'] is List
            ? (j['offers'] as List)
                .map((e) => Offer.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : [],
        specs: parseSpecs(j['specs']),
        basketAccessoryIds: parseImages(j['basket_accessory_ids']),
        promoName: '${promo['name'] ?? ''}',
        promoTiers: promo['tiers'] is List
            ? (promo['tiers'] as List)
                .whereType<List>()
                .where((e) => e.length == 2)
                .map((e) => (parseNumber(e[0]).toInt(), parseNumber(e[1])))
                .toList()
            : []);
  }
}
