import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/models/product_detail_model.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/providers/product_detail_controller.dart';

Offer variant(String id, String color, String memory, num price,
        {bool? available = true, bool flagged = false}) =>
    Offer(
        id: id,
        name: 'Phone $memory $color (eSIM)',
        image: 'https://example.com/$id.jpg',
        price: price,
        storePrice: 120,
        canBuy: available,
        images: [
          'https://example.com/$id-1.jpg',
          'https://example.com/$id-2.jpg'
        ],
        properties: [
          OfferProperty(code: 'COLOR', name: 'Цвет', value: color),
          OfferProperty(code: 'MEMORY', name: 'Память', value: memory),
          if (flagged)
            const OfferProperty(
                code: 'NEWPRODUCT', name: 'Новинка', value: 'Да')
        ],
        specs: [
          ProductSpec(name: 'Память', value: memory)
        ]);
final preview = Product(id: 'parent', name: 'Phone', price: 999, image: '');
final fixture = ProductDetail(
    id: 'parent',
    name: 'Phone',
    price: 999,
    description: 'Parent description',
    images: [
      'parent.jpg'
    ],
    offers: [
      variant('black256', 'Чёрный', '256 ГБ', 100, flagged: true),
      variant('black512', 'Чёрный', '512 ГБ', 110),
      variant('blue256', 'Голубой', '256 ГБ', 0, flagged: true),
      variant('blue512', 'Голубой', '512 ГБ', 90)
    ],
    specs: const [
      ProductSpec(name: 'Parent-only', value: 'must not leak')
    ]);

class FixtureApi extends ApiService {
  @override
  Future<ProductDetail> getProductDetail(String id) async => fixture;
  @override
  Future<Map<String, dynamic>> getProducts(
          {String? categoryId,
          String? type,
          int limit = 10,
          int offset = 0}) async =>
      {
        'products': offset == 0 ? [preview] : <Product>[],
        'total': 1
      };
}

void main() {
  group('ProductDetailController', () {
    late ProductDetailController controller;
    setUp(() {
      controller = ProductDetailController(preview, api: FixtureApi())
        ..detail = fixture
        ..selectedOffer = fixture.offers.first;
    });
    tearDown(() => controller.dispose());
    test('should preserve memory when changing color', () {
      controller.select('MEMORY', '512 ГБ');
      controller.select('COLOR', 'Голубой');
      expect(controller.id, 'blue512');
      expect(controller.price, 90);
    });
    test(
        'should keep zero SKU price and route to order rather than borrow parent price',
        () {
      controller.select('COLOR', 'Голубой');
      expect(controller.price, 0);
      expect(controller.action, PurchaseAction.order);
    });
    test('should update gallery and specs to the selected variant', () {
      controller.select('MEMORY', '512 ГБ');
      expect(controller.images, contains('https://example.com/black512-2.jpg'));
      expect(controller.specs.single.value, '512 ГБ');
    });
    test('should distinguish preorder from unknown stock', () {
      controller.selectedOffer =
          variant('out', 'Чёрный', '256 ГБ', 100, available: false);
      expect(controller.action, PurchaseAction.preorder);
      controller.selectedOffer =
          variant('unknown', 'Чёрный', '256 ГБ', 100, available: null);
      expect(controller.action, PurchaseAction.checkAvailability);
    });
    test('should omit technical flag properties from variant controls', () {
      expect(
          controller.variantGroups.keys, unorderedEquals(['COLOR', 'MEMORY']));
      expect(controller.variantGroups['COLOR'], hasLength(2));
    });
    test('should not show parent specs when selected SKU has no specs', () {
      controller.selectedOffer = const Offer(
          id: 'empty', name: 'Empty', image: '', price: 10, properties: []);
      expect(controller.specs, isEmpty);
    });
  });
  group('ApiService home SKU selection', () {
    test('should expand one parent into all marked SKUs with their own price',
        () async {
      final result = await FixtureApi().getHomeProducts('new');
      expect(result.map((p) => p.offerId), ['black256', 'blue256']);
      expect(result.map((p) => p.price), [100, 0]);
      expect(result.every((p) => p.id == 'parent'), isTrue);
    });
    test('should choose the lowest positive price when only parent has flag',
        () async {
      final result = await FixtureApi().getHomeProducts('hit');
      expect(result.single.offerId, 'blue512');
      expect(result.single.price, 90);
    });
  });
  group('ProductDetail JSON', () {
    test('should read both prices and keep unavailable SKU state', () {
      final detail = ProductDetail.fromJson({
        'id': 1,
        'name': 'Phone',
        'price': 100,
        'store_price': 120,
        'offers': [
          {
            'id': 2,
            'price': 0,
            'can_buy': false,
            'images': ['one.jpg', 'two.jpg'],
            'specs': [
              {'name': 'SIM', 'value': 'eSIM'}
            ]
          }
        ]
      });
      expect(detail.storePrice, 120);
      expect(detail.offers.single.price, 0);
      expect(detail.offers.single.canBuy, isFalse);
      expect(detail.offers.single.images, hasLength(2));
    });
  });
}
