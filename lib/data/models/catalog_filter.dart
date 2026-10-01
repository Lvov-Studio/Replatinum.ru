import 'product_model.dart';

enum CatalogSort { original, priceAscending, priceDescending, name }

class CatalogFilters {
  final num? minPrice, maxPrice;
  final bool availableOnly;
  final Map<String, Set<String>> values;
  const CatalogFilters(
      {this.minPrice,
      this.maxPrice,
      this.availableOnly = false,
      this.values = const {}});
  int get count =>
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (availableOnly ? 1 : 0) +
      values.values.where((v) => v.isNotEmpty).length;
}

class CatalogAttribute {
  final String label, value;
  const CatalogAttribute(this.label, this.value);
}

class CatalogItem {
  final Product product;
  final Map<String, CatalogAttribute> attributes;
  final String path;
  const CatalogItem(this.product, this.attributes, {this.path = ''});

  bool matches(CatalogFilters filters) {
    if (filters.minPrice != null && product.price < filters.minPrice!) {
      return false;
    }
    if (filters.maxPrice != null &&
        (product.price <= 0 || product.price > filters.maxPrice!)) {
      return false;
    }
    if (filters.availableOnly &&
        (product.canBuy != true || product.price <= 0)) {
      return false;
    }
    return filters.values.entries.every((entry) =>
        entry.value.isEmpty ||
        entry.value.contains(attributes[entry.key]?.value));
  }
}
