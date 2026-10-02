import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/data/models/cart_quote.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/providers/cart_provider.dart';
import 'package:platinumstore_app/providers/saved_products_provider.dart';
import 'package:platinumstore_app/ui/widgets/home_product_carousel.dart';

void main() {
  group('HomeProductCarousel', () {
    for (final (width, scale) in [
      (320.0, 1.0),
      (320.0, 1.3),
      (360.0, 2.0),
      (600.0, 1.0),
    ]) {
      testWidgets(
          'should keep the last single card left and show RuStore at $width / $scale',
          (tester) async {
        tester.view.physicalSize = Size(width * 2, 1800);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final products = [
          for (var i = 1; i <= 3; i++)
            Product(
                id: '$i',
                offerId: 'sku-$i',
                name: 'Смартфон Apple iPhone 256 ГБ',
                price: 100,
                image: '',
                ruStoreWarning: i == 3),
        ];
        final cart = CartProvider(
            quoteLoader: (_) async => const CartQuote(
                id: 'test',
                subtotalMinor: 10000,
                discountMinor: 0,
                totalMinor: 10000));
        addTearDown(cart.dispose);
        final saved = SavedProductsProvider()..ready = true;
        addTearDown(saved.dispose);
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cart),
            ChangeNotifierProvider.value(value: saved),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
                body: HomeProductCarousel(
                    title: 'Хиты продаж',
                    badge: 'ХИТ',
                    badgeColor: Colors.green,
                    future: Future.value(products),
                    onRetry: () {})),
          ),
        ));
        await tester.pumpAndSettle();
        final first = find.byKey(const ValueKey('home-product-sku-1'));
        expect(tester.getTopLeft(first).dx, 10);
        final cardWidth = tester.getSize(first).width;
        if (scale == 1) {
          final imageHeight = (cardWidth < 190 ? cardWidth * .85 : 170) + 40;
          expect(tester.getSize(first).height, closeTo(imageHeight + 126, .1));
        }
        expect(
            tester.getBottomLeft(find.byTooltip('В избранное').first).dy,
            lessThanOrEqualTo(tester
                .getTopLeft(find.byKey(const ValueKey('preview-image-sku-1')))
                .dy));
        await tester.tap(find.text('В корзину').first);
        await tester.pumpAndSettle();
        expect(cart.items.values.single.key, '1:sku-1');
        await tester.drag(find.byType(PageView), Offset(-width, 0));
        await tester.pumpAndSettle();
        final last = find.byKey(const ValueKey('home-product-sku-3'));
        expect(tester.getTopLeft(last).dx, closeTo(10, .1));
        expect(tester.getSize(last).width, closeTo(cardWidth, .1));
        final rustore = find.byTooltip('Без RuStore');
        expect(rustore, findsOneWidget);
        await tester.tap(rustore);
        await tester.pumpAndSettle();
        expect(find.text('Без RuStore'), findsOneWidget);
        expect(find.textContaining('RuStore недоступен'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });
}
