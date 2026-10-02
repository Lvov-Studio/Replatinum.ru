import 'api/api_service.dart';
import 'models/product_detail_model.dart';
import 'models/product_model.dart';

class CartRecommendation {
  final Product product;
  final Offer? offer;
  const CartRecommendation(this.product, this.offer);
  String get catalogId => offer?.id ?? product.id;
  bool get canBuy =>
      (offer?.price ?? product.price) > 0 &&
      (offer?.canBuy ?? product.canBuy) == true;
}

/// Uses the same BASKET_ITEM_ACCESSORIES links as the website's inline tray.
class CartRecommendations {
  final Future<ProductDetail> Function(String) _load;
  final Map<String, Future<List<CartRecommendation>>> _cache = {};
  CartRecommendations({Future<ProductDetail> Function(String)? load})
      : _load = load ?? ApiService().getProductDetail;

  Future<List<CartRecommendation>> forProduct(String id) =>
      _cache.putIfAbsent(id, () => _fetch(id));

  void retry(String id) => _cache.remove(id);

  Future<List<CartRecommendation>> _fetch(String id) async {
    try {
      final parent = await _load(id);
      final result = <CartRecommendation>[];
      for (final accessoryId in parent.basketAccessoryIds.toSet()) {
        final detail = await _load(accessoryId);
        final offers = detail.offers;
        final buyable = offers.where((o) => o.canBuy == true && o.price > 0);
        final offer = buyable.firstOrNull ?? offers.firstOrNull;
        result.add(CartRecommendation(
            Product(
              id: detail.id,
              name: offer?.name.isNotEmpty == true ? offer!.name : detail.name,
              image: offer?.image.isNotEmpty == true
                  ? offer!.image
                  : detail.images.firstOrNull ?? '',
              price: offer?.price ?? detail.price,
              offerId: offer?.id,
              storePrice: offer?.storePrice ?? detail.storePrice,
              canBuy: offer?.canBuy ?? detail.canBuy,
              ruStoreWarning: detail.ruStoreWarning,
              specs: offer?.specs ?? detail.specs,
            ),
            offer));
      }
      return result;
    } catch (_) {
      _cache.remove(id);
      rethrow;
    }
  }
}
