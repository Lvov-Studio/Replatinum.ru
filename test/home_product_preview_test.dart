import 'dart:async';
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

class BoundedHomeApi extends ApiService {
  final requests = <(int, int)>[];
  final pending = <String, Completer<ProductDetail>>{};
  @override
  Future<Map<String, dynamic>> getProducts(
      {String? categoryId,
      String? type,
      int limit = 10,
      int offset = 0}) async {
    requests.add((limit, offset));
    return {
      'products': [
        for (var i = 0; i < 12; i++)
          Product(id: '$i', name: 'Device $i', price: 100, image: '')
      ],
      'total': 1000
    };
  }

  @override
  Future<ProductDetail> getProductDetail(String id) {
    final completer = Completer<ProductDetail>();
    pending[id] = completer;
    return completer.future;
  }

  void finishBatch() {
    for (final entry in pending.entries.toList()) {
      if (!entry.value.isCompleted) {
        entry.value.complete(ProductDetail(
            id: entry.key,
            name: 'Device',
            price: 100,
            description: '',
            images: [],
            offers: []));
      }
    }
  }
}

void main() {
  group('Home product preview', () {
    test('should bound home requests and resolve four models concurrently',
        () async {
      final api = BoundedHomeApi();
      final result = api.getHomeProducts('new');
      await Future<void>.delayed(Duration.zero);
      expect(api.requests, [(12, 0)]);
      expect(api.pending.keys, ['0', '1', '2', '3']);
      api.finishBatch();
      await Future<void>.delayed(Duration.zero);
      expect(api.pending.length, 8);
      api.finishBatch();
      await Future<void>.delayed(Duration.zero);
      expect(api.pending.length, 12);
      api.finishBatch();
      expect(await result, hasLength(12));
      expect(api.requests, hasLength(1));
    });

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
