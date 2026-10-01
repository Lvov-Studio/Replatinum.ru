import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/models/product_detail_model.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/providers/saved_products_provider.dart';

class PreviewApi extends ApiService {
  final bool marked;
  final bool hasOffers;
  PreviewApi({required this.marked, this.hasOffers = true});

  @override
  Future<Map<String, dynamic>> getProducts(
          {String? categoryId,
          String? type,
          int limit = 10,
          int offset = 0}) async =>
      {
        'products': [
          Product(id: 'parent', name: 'Device', price: 100, image: '')
        ],
        'total': 1,
      };

  @override
  Future<ProductDetail> getProductDetail(String id) async => ProductDetail(
      id: id,
      name: 'Device',
      price: 100,
      description: '',
      images: [],
      ruStoreWarning: true,
      offers: hasOffers
          ? [
              Offer(
                  id: 'sku',
                  name: 'Device SKU',
                  price: 100,
                  image: '',
                  properties: marked
                      ? [
                          const OfferProperty(
                              code: 'NEWPRODUCT', name: 'Новинка', value: 'Да')
                        ]
                      : [])
            ]
          : []);
}

void main() {
  group('Home product preview', () {
    for (final (marked, hasOffers) in [
      (true, true),
      (false, true),
      (false, false)
    ]) {
      test(
          'should retain server RuStore warning for marked=$marked / offers=$hasOffers',
          () async {
        final result = await PreviewApi(marked: marked, hasOffers: hasOffers)
            .getHomeProducts('new');
        expect(result.single.ruStoreWarning, isTrue);
        expect(result.single.offerId, hasOffers ? 'sku' : null);
      });
    }

    test('should preserve RuStore in JSON previews and saved items', () {
      final product = Product.fromJson({
        'id': '1',
        'name': 'Device',
        'image': '',
        'price': 100,
        'rustore_warning': true
      });
      final saved =
          SavedProduct.fromJson(SavedProduct(product, 'sku', []).toJson());
      expect(saved.product.ruStoreWarning, isTrue);
      expect(Product.fromJson({'id': '2'}).ruStoreWarning, isFalse);
    });
  });
}
