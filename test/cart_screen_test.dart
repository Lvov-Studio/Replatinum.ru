import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/data/cart_recommendations.dart';
import 'package:platinumstore_app/data/models/cart_quote.dart';
import 'package:platinumstore_app/data/models/product_detail_model.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/providers/cart_provider.dart';
import 'package:platinumstore_app/providers/saved_products_provider.dart';
import 'package:platinumstore_app/ui/screens/cart_screen.dart';

void main() {
  for (final width in [320.0, 411.0]) {
    testWidgets(
        'filled cart at $width supports selection and real accessory SKU',
        (tester) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cart = CartProvider(
          quoteLoader: (items) async => CartQuote(
              id: 'q',
              subtotalMinor: items.length * 10000,
              discountMinor: 0,
              totalMinor: items.length * 10000));
      cart.addItem(Product(
          id: '1',
          name: 'Смартфон Apple iPhone 17 Pro Max 256 ГБ',
          price: 100,
          image: ''));
      final recs = CartRecommendations(
          load: (id) async => ProductDetail(
              id: id,
              name: 'Аксессуар',
              price: 50,
              canBuy: true,
              description: '',
              images: [],
              basketAccessoryIds: id == '1' ? ['2'] : [],
              offers: []));
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider.value(value: cart),
        ChangeNotifierProvider(create: (_) => SavedProductsProvider()),
      ], child: MaterialApp(home: CartScreen(recommendations: recs))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Детали заказа'), findsOneWidget);
      final protection = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Защита устройств'));
      expect(protection.onPressed, isNull);
      await tester.tap(find.byTooltip('Добавить в корзину'));
      await tester.pumpAndSettle();
      expect(cart.items.values.map((i) => i.catalogId), ['1', '2']);
      expect(find.byTooltip('Добавить в корзину'), findsNothing);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(cart.selectedItems, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
