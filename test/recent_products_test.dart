import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/providers/recent_products_provider.dart';
import 'package:platinumstore_app/ui/widgets/recent_products_strip.dart';
import 'package:platinumstore_app/ui/widgets/empty_cart_view.dart';

class EmptyRecommendationsApi extends ApiService {
  @override
  Future<List<Product>> getHomeProducts(String type) async => [];
}

class MemoryHistory extends RecentProductsProvider {
  final List<Product> entries = [];
  @override
  List<Product> get products => entries;
  @override
  Future<void> record(Product product) async {
    entries.insert(0, product);
    notifyListeners();
  }
}

void main() {
  test('history persists the latest variant and caps at twenty models',
      () async {
    final directory = await Directory.systemTemp.createTemp('recent-products-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/history.json');
    final history = RecentProductsProvider(storage: file);
    addTearDown(history.dispose);
    for (var i = 0; i < 22; i++) {
      await history
          .record(Product(id: '$i', name: 'Phone $i', price: i, image: ''));
    }
    await history.record(Product(
        id: '5', offerId: 'sku-512', name: 'Phone 512', price: 123, image: ''));
    expect(history.products, hasLength(20));
    expect(history.products.first.offerId, 'sku-512');
    expect(history.products.where((p) => p.id == '5'), hasLength(1));
    final restored = RecentProductsProvider(storage: file);
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.products.first.price, 123);
    expect(restored.products.first.offerId, 'sku-512');
    expect(restored.products, hasLength(20));
  });

  test('unreadable history still accepts newly viewed products', () async {
    final directory = await Directory.systemTemp.createTemp('recent-corrupt-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/history.json');
    await file.writeAsString('broken');
    final history = RecentProductsProvider(storage: file);
    addTearDown(history.dispose);
    await history.record(Product(id: '1', name: 'Phone', price: 0, image: ''));
    expect(history.products.single.id, '1');
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('empty cart routes to catalog and history fits at font $scale',
        (tester) async {
      tester.view.physicalSize = const Size(640, 1600);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var opened = false;
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
              body: EmptyCartView(
                  apiService: EmptyRecommendationsApi(),
                  onCatalog: () => opened = true))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('В каталог'));
      expect(opened, isTrue);
      expect(find.text('В корзине пока ничего нет'), findsOneWidget);
      expect(find.text('Хиты продаж'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final history = MemoryHistory();
      addTearDown(history.dispose);
      await tester.pumpWidget(
          ChangeNotifierProvider<RecentProductsProvider>.value(
              value: history,
              child: MaterialApp(
                  home: const Scaffold(body: RecentProductsStrip()))));
      expect(find.text('Вы смотрели'), findsNothing);
      await history.record(Product(
          id: '1',
          name: 'Очень длинное название смартфона 512 ГБ',
          price: 123456,
          image: ''));
      await tester.pumpAndSettle();
      expect(find.text('Вы смотрели'), findsOneWidget);
      expect(find.textContaining('Очень длинное'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
