import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/cart_recommendations.dart';
import 'package:platinumstore_app/data/models/product_detail_model.dart';

ProductDetail detail(String id,
        {List<String> links = const [], List<Offer> offers = const []}) =>
    ProductDetail(
        id: id,
        name: 'Товар $id',
        price: 0,
        description: '',
        images: [],
        offers: offers,
        basketAccessoryIds: links);

void main() {
  test('website links resolve to a buyable SKU and zero prices stay disabled',
      () async {
    final calls = <String>[];
    final service = CartRecommendations(load: (id) async {
      calls.add(id);
      return switch (id) {
        '1' => detail(id, links: ['2', '2', '3']),
        '2' => detail(id, offers: [
            const Offer(
                id: '20',
                name: 'Нет в наличии',
                image: '',
                price: 50,
                properties: [],
                canBuy: false),
            const Offer(
                id: '21',
                name: 'В наличии',
                image: '',
                price: 60,
                properties: [],
                canBuy: true),
          ]),
        _ => detail(id),
      };
    });
    final results = await service.forProduct('1');
    expect(results.map((r) => r.catalogId), ['21', '3']);
    expect(results.first.canBuy, isTrue);
    expect(results.last.canBuy, isFalse);
    await service.forProduct('1');
    expect(calls, ['1', '2', '3']);
  });
  test('failed recommendations can be retried without a stale error cache',
      () async {
    var failed = true;
    final service = CartRecommendations(load: (id) async {
      if (failed) throw Exception('offline');
      return detail(id);
    });
    await expectLater(service.forProduct('1'), throwsException);
    failed = false;
    expect(await service.forProduct('1'), isEmpty);
  });
}
