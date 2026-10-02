import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/core/utils/price_formatter.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/models/product_detail_model.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/providers/cart_provider.dart';
import 'package:platinumstore_app/providers/saved_products_provider.dart';
import 'package:platinumstore_app/ui/screens/product_detail_screen.dart';
import 'package:platinumstore_app/ui/widgets/product_credit_sheet.dart';

class ScreenApi extends ApiService {
  @override
  Future<ProductDetail> getProductDetail(String id) async =>
      const ProductDetail(
          id: '1',
          name: 'Phone',
          price: 100,
          description: 'Описание устройства',
          images: [],
          offers: [
            Offer(
                id: '2',
                name: 'Phone 256 GB',
                image: '',
                price: 100,
                storePrice: 120,
                canBuy: true,
                properties: [
                  OfferProperty(code: 'MEMORY', name: 'Память', value: '256 ГБ')
                ],
                specs: [
                  ProductSpec(name: 'Модель', value: 'Phone')
                ]),
            Offer(
                id: '3',
                name: 'Phone 512 GB',
                image: '',
                price: 0,
                canBuy: false,
                properties: [
                  OfferProperty(code: 'MEMORY', name: 'Память', value: '512 ГБ')
                ])
          ]);
}

class SearchPriceApi extends ApiService {
  @override
  Future<ProductDetail> getProductDetail(String id) async =>
      const ProductDetail(
          id: 'parent',
          name: 'Phone',
          price: 0,
          description: '',
          images: [],
          offers: [
            Offer(
                id: 'expensive',
                name: 'Phone expensive',
                image: '',
                price: 200,
                properties: []),
            Offer(
                id: 'matching',
                name: 'Phone matching',
                image: '',
                price: 100,
                properties: []),
          ]);
}

void main() {
  group('ProductDetailScreen', () {
    testWidgets(
        'search opens the priced variant; exact SKU wins over a price match',
        (tester) async {
      for (final (offerId, expectedName) in [
        ('parent', 'Phone matching'),
        ('expensive', 'Phone expensive')
      ]) {
        await tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => CartProvider()),
              ChangeNotifierProvider(
                  create: (_) => SavedProductsProvider()..ready = true),
            ],
            child: MaterialApp(
                home: ProductDetailScreen(
              key: ValueKey(offerId),
              productPreview:
                  Product(id: 'parent', name: 'Phone', price: 100, image: ''),
              initialOfferId: offerId,
              matchPreviewPrice: true,
              apiService: SearchPriceApi(),
            ))));
        await tester.pumpAndSettle();
        expect(find.text(expectedName), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
    for (final (width, scale) in [
      (320.0, 1.0),
      (320.0, 1.3),
      (360.0, 1.0),
      (600.0, 1.0)
    ]) {
      testWidgets(
          'should show prices, installment and unavailable SKU at width $width and font scale $scale',
          (tester) async {
        tester.view.physicalSize = Size(width * 2, 1600);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => CartProvider()),
              ChangeNotifierProvider(
                  create: (_) => SavedProductsProvider()..ready = true)
            ],
            child: MaterialApp(
                home: ProductDetailScreen(
                    productPreview:
                        Product(id: '1', name: 'Phone', price: 100, image: ''),
                    apiService: ScreenApi()))));
        await tester.pumpAndSettle();
        expect(find.textContaining(formatPrice(120)), findsNWidgets(2));
        final installment = find.text('Рассрочка от ${formatPrice(5)}/мес.');
        await tester.ensureVisible(installment);
        await tester.pumpAndSettle();
        await tester.tap(installment);
        await tester.pumpAndSettle();
        expect(find.byType(ProductCreditSheet), findsOneWidget);
        await tester.tap(find.text('12 мес.'));
        await tester.pumpAndSettle();
        expect(find.text('${formatPrice(10)}/мес.'), findsOneWidget);
        Navigator.of(tester.element(find.byType(ProductCreditSheet))).pop();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('512 ГБ'), -180,
            scrollable: find.byType(Scrollable).first);
        await Scrollable.ensureVisible(tester.element(find.text('512 ГБ')),
            alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(find.text('512 ГБ'));
        await tester.pumpAndSettle();
        expect(find.text('Цена по запросу'), findsNothing);
        expect(find.text('Под заказ'), findsWidgets);
        expect(find.text(formatPrice(100)), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
