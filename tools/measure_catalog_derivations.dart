import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/models/catalog_filter.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/providers/product_provider.dart';

class FixtureApi extends ApiService {
  @override
  Future<List<CatalogItem>> getCatalogItems(
          {String? categoryId,
          String? type,
          bool Function()? isCurrent,
          void Function(List<CatalogItem>)? onProgress}) async =>
      [
        for (var i = 0; i < 2000; i++)
          CatalogItem(
              Product(
                  id: '$i',
                  name: 'Phone $i',
                  price: (i * 7919) % 100000,
                  image: ''),
              {'brand': CatalogAttribute('Brand', 'Brand ${i % 5}')})
      ];
}

void main() {
  test('catalog derived-data benchmark (fixture, not frame rate)', () async {
    final provider = ProductProvider(apiService: FixtureApi());
    await provider.fetchProducts();
    provider.setSort(CatalogSort.priceAscending);
    final samples = <int>[];
    var checksum = 0;
    for (var i = 0; i < 220; i++) {
      final watch = Stopwatch()..start();
      checksum += provider.products.length +
          provider.total +
          (provider.hasMore ? 1 : 0) +
          provider.facets.length;
      watch.stop();
      if (i >= 20) samples.add(watch.elapsedMicroseconds);
    }
    samples.sort();
    debugPrint(
        'CATALOG_DERIVATIONS count=2000 samples=200 p50_us=${samples[100]} p95_us=${samples[190]} checksum=$checksum');
    expect(provider.total, 2000);
    provider.dispose();
  });
}
