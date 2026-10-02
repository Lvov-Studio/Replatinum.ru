import '../../../data/api/api_service.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/saved_products_provider.dart';
import 'account_gateway.dart';

class AccountSavedProducts implements SavedProductsRemote {
  AccountSavedProducts(this.gateway, {ApiService? api})
      : api = api ?? ApiService();
  final AccountGateway gateway;
  final ApiService api;
  @override
  Future<Map<String, List<SavedProduct>>> fetch() async {
    final result = await gateway.request('saved');
    final ids = <String>{
      for (final key in ['favorites', 'comparison'])
        for (final id in result[key] as List? ?? []) '$id'
    }.toList();
    final products = <String, SavedProduct>{};
    for (var start = 0; start < ids.length; start += 4) {
      final batch = ids.skip(start).take(4);
      await Future.wait(batch.map((id) async {
        try {
          final detail = await api.getProductDetail(id);
          final offers = detail.offers.where((o) => o.id == id);
          final offer = offers.isEmpty ? null : offers.first;
          final image = offer?.image ??
              (detail.images.isEmpty ? '' : detail.images.first);
          products[id] = SavedProduct(
              Product(
                  id: detail.id,
                  offerId: offer?.id,
                  name: offer?.name ?? detail.name,
                  price: offer?.price ?? detail.price,
                  storePrice: offer?.storePrice ?? detail.storePrice,
                  canBuy: offer?.canBuy ?? detail.canBuy,
                  image: image,
                  ruStoreWarning: detail.ruStoreWarning),
              id,
              offer?.specs ?? detail.specs);
        } catch (_) {
          // Preserve missing IDs so the user can explicitly remove stale favorites.
          products[id] = SavedProduct(
              Product(id: id, name: 'Товар недоступен', price: 0, image: ''),
              id, const []);
        }
      }));
    }
    return {
      for (final key in ['favorites', 'comparison'])
        key: [
          for (final id in result[key] as List? ?? [])
            if (products['$id'] != null) products['$id']!
        ]
    };
  }

  @override
  Future<void> set(SavedProduct product,
      {required bool enabled, required bool compare}) async {
    await gateway.request('saved_update', {
      'kind': compare ? 'comparison' : 'favorites',
      'id': product.skuId,
      'enabled': enabled ? '1' : '0'
    });
  }
}
