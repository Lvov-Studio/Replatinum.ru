import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/models/category_model.dart';
import 'package:platinumstore_app/data/models/catalog_filter.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/data/models/product_detail_model.dart';
import 'package:platinumstore_app/providers/product_provider.dart';
import 'package:platinumstore_app/providers/saved_products_provider.dart';
import 'package:platinumstore_app/ui/widgets/catalog_category_list.dart';
import 'package:platinumstore_app/ui/widgets/catalog_products_view.dart';
import 'package:platinumstore_app/ui/widgets/catalog_filter_sheet.dart';

class SectionApi extends ApiService {
  SectionApi() : super(useCompactCatalog: false);
  final offsets = <int>[];
  @override
  Future<Map<String, dynamic>> getProducts(
      {String? categoryId,
      String? type,
      int limit = 10,
      int offset = 0}) async {
    offsets.add(offset);
    return {
      'products': [
        for (var i = offset; i < 51 && i < offset + limit; i++)
          Product(id: '$i', name: 'Модель $i', price: 100, image: '')
      ],
      'total': 51
    };
  }

  @override
  Future<ProductDetail> getProductDetail(String id) async => ProductDetail(
      id: id,
      name: 'Модель $id',
      price: 100,
      description: '',
      images: [],
      ruStoreWarning: true,
      specs: const [
        ProductSpec(name: 'Память', code: 'MEMORY', value: 'Общая')
      ],
      offers: [
        for (var i = 0; i < 2; i++)
          Offer(
              id: '$id-$i',
              name: 'Вариант $id-$i',
              image: '',
              price: int.parse(id) * 100 + i + 1,
              storePrice: 10000,
              canBuy: i == 0,
              properties: [],
              specs: [
                ProductSpec(
                    name: 'Память',
                    code: 'MEMORY',
                    value: i == 0 ? '128 ГБ' : '256 ГБ')
              ])
      ]);
}

class RacingApi extends ApiService {
  final pending = <String, Completer<List<CatalogItem>>>{};
  @override
  Future<List<CatalogItem>> getCatalogItems(
          {String? categoryId,
          String? type,
          bool Function()? isCurrent,
          void Function(List<CatalogItem>)? onProgress}) =>
      (pending[categoryId!] = Completer<List<CatalogItem>>()).future;
}

class IncompleteApi extends ApiService {
  IncompleteApi() : super(useCompactCatalog: false);
  @override
  Future<Map<String, dynamic>> getProducts(
          {String? categoryId,
          String? type,
          int limit = 10,
          int offset = 0}) async =>
      {'products': <Product>[], 'total': 10};
}

class NavigationApi extends ApiService {
  int requests = 0;
  @override
  Future<List<CatalogItem>> getCatalogItems(
      {String? categoryId,
      String? type,
      bool Function()? isCurrent,
      void Function(List<CatalogItem>)? onProgress}) async {
    requests++;
    return [
      CatalogItem(
          Product(
              id: 'apple',
              offerId: 'a',
              name: 'iPhone 18 Pro',
              price: 100,
              image: ''),
          {},
          path: '/catalog/smartfony/iphone/iphone-18-pro/phone/'),
      CatalogItem(
          Product(
              id: 'samsung',
              offerId: 's',
              name: 'Samsung Galaxy S',
              price: 200,
              image: ''),
          {},
          path: '/catalog/smartfony/samsung/galaxy_s/phone/'),
    ];
  }
}

class SlowSectionApi extends SectionApi {
  final remaining = Completer<void>();
  bool fail = false;
  @override
  Future<ProductDetail> getProductDetail(String id) async {
    if (int.parse(id) >= 4) await remaining.future;
    if (fail) throw StateError('Detail unavailable');
    return super.getProductDetail(id);
  }
}

void main() {
  group('Progressive catalog loading', () {
    test('should expose real SKUs before remaining details and defer facets',
        () async {
      final api = SlowSectionApi();
      final provider = ProductProvider(apiService: api);
      addTearDown(provider.dispose);
      final loading = provider.fetchProducts(
          category: Category(id: '83', name: 'Phones', image: ''));
      await Future<void>.delayed(Duration.zero);
      expect(provider.isLoading, true);
      expect(provider.sectionTotal, 8);
      expect(provider.products.first.offerId, '0-0');
      expect(provider.facets, isEmpty);
      api.remaining.complete();
      await loading;
      expect(provider.sectionTotal, 102);
      expect(provider.facets, isNotEmpty);
    });
    test(
        'should discard partial results on a later failure and avoid caching them',
        () async {
      final api = SlowSectionApi();
      final provider = ProductProvider(apiService: api);
      addTearDown(provider.dispose);
      final category = Category(id: '83', name: 'Phones', image: '');
      final loading = provider.fetchProducts(category: category);
      await Future<void>.delayed(Duration.zero);
      expect(provider.sectionTotal, 8);
      api.fail = true;
      api.remaining.complete();
      await loading;
      expect(provider.error, isNotEmpty);
      expect(provider.sectionTotal, 0);
      api.fail = false;
      await provider.fetchProducts(category: category);
      expect(provider.sectionTotal, 102);
      expect(api.offsets, [0, 0, 50]);
    });
    test('should reuse complete sections, force refresh and expire the cache',
        () async {
      var now = DateTime(2026, 10, 2);
      final api = NavigationApi();
      final provider = ProductProvider(apiService: api, now: () => now);
      addTearDown(provider.dispose);
      final category =
          Category(id: '83', code: 'smartfony', name: 'Phones', image: '');
      await provider.fetchProducts(category: category);
      provider.clearCategory();
      await provider.fetchProducts(category: category);
      expect(api.requests, 1);
      expect(provider.sectionTotal, 2);
      await provider.retry();
      expect(api.requests, 2);
      now = now.add(const Duration(minutes: 3));
      await provider.fetchProducts(category: category);
      expect(api.requests, 3);
    });
    test(
        'should show subsection navigation before details and ignore cancelled progress',
        () async {
      final api = SlowSectionApi();
      final provider = ProductProvider(apiService: api);
      addTearDown(provider.dispose);
      final loading = provider.fetchProducts(
          category:
              Category(id: '83', code: 'smartfony', name: 'Phones', image: ''));
      expect(provider.browsing, true);
      expect(provider.subsections, isNotEmpty);
      expect(provider.imageOf(provider.subsections.first), isEmpty);
      await Future<void>.delayed(Duration.zero);
      provider.clearCategory();
      api.remaining.complete();
      await loading;
      expect(provider.sectionTotal, 0);
      expect(provider.selectedCategory, null);
      expect(provider.isLoading, false);
    });
  });
  testWidgets(
      'should keep navigation and loaded products visible during background loading',
      (tester) async {
    final api = SlowSectionApi();
    final provider = ProductProvider(apiService: api);
    final saved = SavedProductsProvider()..ready = true;
    addTearDown(provider.dispose);
    addTearDown(saved.dispose);
    final loading = provider.fetchProducts(
        category:
            Category(id: '83', code: 'smartfony', name: 'Phones', image: ''));
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: saved),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: Consumer<ProductProvider>(
                    builder: (_, p, child) =>
                        CatalogProductsView(provider: p))))));
    await tester.pump();
    expect(find.text('iPhone'), findsOneWidget);
    expect(find.byTooltip('Обновить товары'), findsOneWidget);
    await tester.tap(find.text('Смотреть все'));
    await tester.pump();
    expect(find.byKey(const ValueKey('preview-image-0-0')), findsOneWidget);
    expect(find.text('Загружаем товары и фильтры…'), findsNothing);
    expect(find.text('Фильтры'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    api.remaining.complete();
    await loading;
    await tester.pump();
    expect(find.text('Фильтры'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test(
      'Subsections use website paths, hide empty branches and preserve back navigation',
      () async {
    final provider = ProductProvider(apiService: NavigationApi());
    addTearDown(provider.dispose);
    await provider.fetchProducts(
        category: Category(
            id: '83', code: 'smartfony', name: 'Смартфоны', image: ''));
    expect(provider.browsing, true);
    expect(provider.subsections.map((n) => n.title), ['iPhone', 'Samsung']);
    final apple = provider.subsections.first;
    expect(provider.childrenOf(apple).map((n) => n.title), ['iPhone 18 Pro']);
    provider.openSubsection(provider.childrenOf(apple).single);
    expect(provider.sectionTitle, 'iPhone 18 Pro');
    expect(provider.total, 1);
    expect(provider.products.single.offerId, 'a');
    expect(provider.priceBounds, (100.0, 100.0));
    provider.goBack();
    expect(provider.browsing, true);
    provider.openSubsection();
    expect(provider.total, 2);
    provider.goBack();
    provider.goBack();
    expect(provider.selectedCategory, null);
  });
  test('Incomplete section fails visibly instead of exposing partial filters',
      () async {
    final provider = ProductProvider(apiService: IncompleteApi());
    addTearDown(provider.dispose);
    await provider.fetchProducts(
        category: Category(id: '83', name: 'Смартфоны', image: ''));
    expect(provider.error, isNotEmpty);
    expect(provider.isLoading, false);
    expect(provider.facets, isEmpty);
  });
  test('Multiple values are OR within a facet and AND across facets', () {
    final item =
        CatalogItem(Product(id: '1', name: 'Phone', image: '', price: 100), {
      'color': const CatalogAttribute('Цвет', 'Черный'),
      'memory': const CatalogAttribute('Память', '128 ГБ')
    });
    expect(
        item.matches(const CatalogFilters(values: {
          'color': {'Черный', 'Белый'},
          'memory': {'128 ГБ'}
        })),
        true);
    expect(
        item.matches(const CatalogFilters(values: {
          'color': {'Черный', 'Белый'},
          'memory': {'256 ГБ'}
        })),
        false);
  });
  test(
      'Full section fetch includes page two, selected SKU prices and separate facets',
      () async {
    final api = SectionApi();
    final provider = ProductProvider(apiService: api);
    addTearDown(provider.dispose);
    await provider.fetchProducts(
        category: Category(id: '83', name: 'Смартфоны', image: ''));
    expect(api.offsets, [0, 50]);
    expect(provider.total, 102);
    expect(provider.products.length, 20);
    provider.applyFilters(const CatalogFilters(
        minPrice: 5000,
        maxPrice: 5002,
        availableOnly: true,
        values: {
          'offer:MEMORY': {'128 ГБ'}
        }));
    expect(provider.total, 1);
    expect(provider.products.single.offerId, '50-0');
    expect(provider.products.single.price, 5001);
    expect(provider.products.single.ruStoreWarning, true);
    expect(provider.facets['offer:MEMORY']!.$2, ['128 ГБ', '256 ГБ']);
    expect(
        provider.countMatching(const CatalogFilters(values: {
          'model:MEMORY': {'128 ГБ'}
        })),
        0);
    provider.applyFilters(const CatalogFilters());
    provider.setSort(CatalogSort.priceDescending);
    expect(provider.products.first.offerId, '50-1');
    await provider.loadMore();
    expect(provider.products.length, 40);
  });
  test('Old response cannot overwrite a changed or cleared section', () async {
    final api = RacingApi();
    final provider = ProductProvider(apiService: api);
    addTearDown(provider.dispose);
    final a = provider.fetchProducts(
        category: Category(id: 'a', name: 'A', image: ''));
    final b = provider.fetchProducts(
        category: Category(id: 'b', name: 'B', image: ''));
    api.pending['a']!.complete([]);
    await a;
    expect(provider.isLoading, true);
    provider.clearCategory();
    api.pending['b']!.complete([]);
    await b;
    expect(provider.selectedCategory, null);
    expect(provider.isLoading, false);
    expect(provider.total, 0);
  });
  for (final (width, scale) in [
    (320.0, 1.0),
    (320.0, 1.3),
    (360.0, 2.0),
    (600.0, 1.0)
  ]) {
    testWidgets(
        'Rows and product grid fit $width / $scale with working filters',
        (tester) async {
      tester.view.physicalSize = Size(width * 2, 1800);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      Category? selected;
      final category =
          Category(id: '83', name: 'Умные часы и фитнес-браслеты', image: '');
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: CatalogCategoryList(
                  categories: [category], onSelected: (c) => selected = c))));
      await tester.tap(find.text(category.name));
      expect(selected, category);
      expect(tester.takeException(), null);
      final navigation = ProductProvider(apiService: NavigationApi());
      addTearDown(navigation.dispose);
      await navigation.fetchProducts(
          category: Category(
              id: '83', code: 'smartfony', name: 'Смартфоны', image: ''));
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: navigation,
          child: MaterialApp(
              home:
                  Scaffold(body: CatalogProductsView(provider: navigation)))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('iPhone'));
      await tester.pumpAndSettle();
      expect(find.text('Смотреть все модели'), findsOneWidget);
      expect(find.text('iPhone 18 Pro'), findsOneWidget);
      expect(tester.takeException(), null);
      final provider = ProductProvider(apiService: SectionApi());
      addTearDown(provider.dispose);
      await provider.fetchProducts(category: category);
      final saved = SavedProductsProvider()..ready = true;
      addTearDown(saved.dispose);
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: saved)
          ],
          child: MaterialApp(
              home: Scaffold(
                  body: Consumer<ProductProvider>(
                      builder: (c, p, _) =>
                          CatalogProductsView(provider: p))))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
      expect(find.byTooltip('Без RuStore'), findsWidgets);
      expect(
          tester.getBottomLeft(find.byTooltip('В избранное').first).dy,
          lessThanOrEqualTo(tester
              .getTopLeft(find.byKey(const ValueKey('preview-image-0-0')))
              .dy));
      await tester.tap(find.byTooltip('В избранное').first);
      await tester.pump();
      expect(saved.favorites.keys, contains('0-0'));
      await tester.tap(find.text('Фильтры'));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogFilterSheet), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), '5000');
      await tester.enterText(find.byType(TextField).at(1), '100');
      await tester.pump();
      expect(find.text('Цена «До» должна быть не меньше цены «От»'),
          findsOneWidget);
      await tester.tap(find.text('Сбросить'));
      await tester.scrollUntilVisible(find.text('Только в наличии'), -100,
          scrollable: find
              .descendant(
                  of: find.byType(CatalogFilterSheet),
                  matching: find.byType(Scrollable))
              .first);
      await tester.pump();
      await tester.tap(find.text('Только в наличии'));
      await tester.pump();
      expect(find.text('Показать товары (51)'), findsOneWidget);
      await tester.tap(find.text('Показать товары (51)'));
      await tester.pumpAndSettle();
      expect(provider.total, 51);
      expect(tester.takeException(), null);
    });
  }
}
