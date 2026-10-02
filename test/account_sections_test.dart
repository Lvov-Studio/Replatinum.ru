import 'package:provider/provider.dart';
import 'package:platinumstore_app/features/account/ui/account_session.dart';
import 'package:platinumstore_app/ui/widgets/burger_menu.dart';
import 'package:platinumstore_app/providers/category_provider.dart';
import 'main_screen_navigation_test.dart' show EmptyCategories;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/features/account/ui/account_controller.dart';
import 'package:platinumstore_app/features/account/ui/account_sections.dart';
import 'package:platinumstore_app/features/account/ui/account_screen.dart';
import 'package:platinumstore_app/providers/saved_products_provider.dart';
import 'account_test.dart' show FakeAccountGateway;

class RemoteSaved extends SavedProductsRemote {
  bool fail = false;
  final changes = <(String, bool, bool)>[];
  final product = SavedProduct(
      Product(id: '2', name: 'С сайта', price: 10, image: ''), '2', const []);
  @override
  Future<Map<String, List<SavedProduct>>> fetch() async => {
        'favorites': [product],
        'comparison': []
      };
  @override
  Future<void> set(SavedProduct product,
      {required bool enabled, required bool compare}) async {
    changes.add((product.skuId, enabled, compare));
    if (fail) throw StateError('offline');
  }
}

void main() {
  testWidgets('menu login follows cabinet login, logout and session expiration',
      (tester) async {
    final gateway = FakeAccountGateway()..authorized = true;
    final account = AccountController(gateway);
    final session = AccountSession();
    addTearDown(account.dispose);
    addTearDown(session.dispose);
    await account.initialize();
    final key = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider<CategoryProvider>(
              create: (_) => EmptyCategories()),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
                key: key,
                drawer: const BurgerMenu(),
                body: AccountScreen(controller: account)))));
    await tester.pumpAndSettle();
    key.currentState!.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Войти').hitTestable(), findsNothing);
    await account.logout();
    await tester.pumpAndSettle();
    expect(find.text('Войти').hitTestable(), findsOneWidget);
    gateway.authorized = true;
    await account.initialize();
    await tester.pumpAndSettle();
    expect(find.text('Войти').hitTestable(), findsNothing);
    gateway.expire = true;
    await account.loadSummary();
    await tester.pumpAndSettle();
    expect(find.text('Войти').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test(
      'account saved products replace guest view, preserve device data and roll back failed writes',
      () async {
    final saved = SavedProductsProvider()..ready = true;
    addTearDown(saved.dispose);
    final guest = SavedProduct(
        Product(id: '1', name: 'Гостевой', price: 1, image: ''), '1', const []);
    saved.favorites['1'] = guest;
    final remote = RemoteSaved();
    await saved.connect(remote);
    expect(saved.favorites.keys, ['2']);
    expect(remote.changes,
        isEmpty); // Login itself never changes the website wishlist.
    remote.fail = true;
    saved.toggle(remote.product);
    await saved.refreshRemote();
    expect(saved.favorites.keys, ['2']);
    expect(remote.changes, [('2', false, false)]);
    saved.disconnect();
    expect(saved.favorites.keys, ['1']);
    expect(saved.accountConnected, false);
  });
  test('address, summary and detail state is cleared after session expiration',
      () async {
    final gateway = FakeAccountGateway()..authorized = true;
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    await account.initialize();
    expect(account.summary!['orders_count'], 2);
    await account.loadAddress();
    expect(account.address!['city'], 'Краснодар');
    await account.saveAddress(' Москва ', ' Дом 1 ');
    expect(account.address, {'city': 'Москва', 'street': 'Дом 1'});
    await account.loadOrderDetail('1');
    expect(account.orderDetail!['id'], '1');
    gateway.expire = true;
    await account.loadSummary();
    expect(account.step, AccountStep.phone);
    expect(account.summary, isNull);
    expect(account.address, isNull);
    expect(account.orderDetail, isNull);
  });
  for (final (width, scale) in [(320.0, 1.0), (360.0, 2.0), (600.0, 1.0)]) {
    testWidgets('address, order details and help fit $width / $scale',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final account =
          AccountController(FakeAccountGateway()..authorized = true);
      addTearDown(account.dispose);
      await account.initialize();
      Future<void> open(Widget screen) async {
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: screen));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await open(AccountProfileEditor(account: account));
      expect(find.text('Иван'), findsOneWidget);
      await open(AccountAddressScreen(account: account));
      expect(find.text('Краснодар'), findsOneWidget);
      await tester.ensureVisible(find.text('Сохранить адрес'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить адрес'));
      await tester.pumpAndSettle();
      expect(find.text('Адрес сохранён'), findsOneWidget);
      await open(AccountOrderDetailScreen(account: account, id: '1'));
      expect(find.text('Телефон'), findsOneWidget);
      await open(const AccountHelpScreen());
      expect(find.text('Поддержка Replatinum'), findsOneWidget);
      await open(AccountScreen(controller: account));
      expect(find.text('Личные данные'), findsOneWidget);
      await tester.ensureVisible(find.text('Выйти из аккаунта'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
