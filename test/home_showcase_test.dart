import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/data/models/catalog_filter.dart';
import 'package:platinumstore_app/providers/saved_products_provider.dart';
import 'package:platinumstore_app/ui/widgets/home_showcase_carousel.dart';
import 'package:platinumstore_app/ui/widgets/catalog_products_view.dart';

class ShowcaseApi extends ApiService {
  String? requestedType;
  @override
  Future<List<CatalogItem>> getCatalogItems(
      {String? categoryId, String? type, bool Function()? isCurrent}) async {
    requestedType = type;
    return [];
  }
}

void main() {
  for (final (width, scale) in [
    (320.0, 1.0),
    (320.0, 1.3),
    (360.0, 2.0),
    (600.0, 1.0)
  ]) {
    testWidgets(
        'showcase fits $width/$scale, saves SKU and opens full hit section',
        (tester) async {
      tester.view.physicalSize = Size(width * 2, 1600);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final saved = SavedProductsProvider()..ready = true;
      addTearDown(saved.dispose);
      final api = ShowcaseApi();
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: saved,
          child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                  body: HomeShowcaseCarousel(
                title: 'Хиты продаж',
                type: 'hit',
                badge: 'Хит',
                apiService: api,
                future: Future.value([
                  for (var i = 0; i < 5; i++)
                    Product(
                        id: '$i',
                        offerId: 'sku-$i',
                        name: 'Смартфон очень длинное название 512 ГБ',
                        price: 12345,
                        image: '',
                        ruStoreWarning: i == 0)
                ]),
                onRetry: () {},
              )))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Initial showcase layout');
      expect(find.byTooltip('Сравнение товаров'), findsNothing);
      expect(find.text('В корзину'), findsNothing);
      final favorite = find.byTooltip('В избранное').first;
      final rustore = find.byTooltip('Без RuStore');
      expect(tester.getCenter(rustore).dy,
          greaterThan(tester.getCenter(favorite).dy));
      await tester.tap(favorite);
      await tester.pumpAndSettle();
      expect(saved.favorites.containsKey('sku-0'), isTrue);
      await tester.tap(find.text('Посмотреть все'));
      await tester.pumpAndSettle();
      expect(api.requestedType, 'hit');
      expect(find.byType(CatalogProductsView), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Full section layout');
      expect(find.text('Хиты продаж'), findsOneWidget);
      await tester.tap(find.byTooltip('Вернуться к разделам'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeShowcaseCarousel), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
