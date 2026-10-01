import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/providers/cart_provider.dart';
import 'package:platinumstore_app/providers/category_provider.dart';
import 'package:platinumstore_app/providers/product_provider.dart';
import 'package:platinumstore_app/providers/saved_products_provider.dart';
import 'package:platinumstore_app/ui/screens/main_screen.dart';
import 'package:platinumstore_app/ui/screens/catalog_screen.dart';
import 'package:platinumstore_app/ui/screens/cart_screen.dart';
import 'package:platinumstore_app/ui/screens/placeholder_screens.dart';
import 'package:platinumstore_app/ui/widgets/saved_products_shortcuts.dart';

class EmptyCategories extends CategoryProvider {
  @override
  Future<void> fetchCategories({bool force = false}) async {}
}

void main() {
  group('MainScreen', () {
    testWidgets(
        'should route all four tabs and saved pages inside the active tab',
        (tester) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<CategoryProvider>(
              create: (_) => EmptyCategories()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(
              create: (_) => SavedProductsProvider()..ready = true),
        ],
        child:
            MaterialApp(theme: AppTheme.lightTheme, home: const MainScreen()),
      ));
      await tester.pumpAndSettle();
      final nav = find
          .descendant(
              of: find.byType(Scaffold).first, matching: find.text('Главная'))
          .last;
      expect(nav, findsOneWidget);
      expect(find.text('Каталог'), findsOneWidget);
      expect(find.text('Корзина'), findsOneWidget);
      expect(find.text('Кабинет'), findsOneWidget);
      expect(MainScreen.tabNavigatorKeys, hasLength(4));

      await tester.tap(find.text('Каталог'));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogScreen), findsOneWidget);
      expect(MainScreen.currentTabIndex, MainScreen.catalogTab);
      await tester.tap(find
          .descendant(
              of: find.byType(SavedProductsActions),
              matching: find.byType(IconButton))
          .first);
      await tester.pumpAndSettle();
      expect(find.text('Добавьте понравившиеся товары в избранное'),
          findsOneWidget);
      expect(find.text('Корзина'), findsOneWidget);
      Navigator.of(tester.element(find.text('Избранное'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Корзина').last);
      await tester.pumpAndSettle();
      expect(find.byType(CartScreen), findsOneWidget);
      expect(MainScreen.currentTabIndex, MainScreen.cartTab);
      final cartContext = tester.element(find.byType(CartScreen));
      MainScreen.of(cartContext)!.switchToTab(MainScreen.profileTab);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(MainScreen.currentTabIndex, MainScreen.profileTab);
      await tester.tap(find.text('Сравнение'));
      await tester.pumpAndSettle();
      expect(find.text('Добавьте товары для сравнения'), findsOneWidget);
      Navigator.of(tester.element(find.text('Сравнение'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Главная'));
      await tester.pumpAndSettle();
      expect(find.text('Добро пожаловать!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
