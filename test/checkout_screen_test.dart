import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/providers/cart_provider.dart';
import 'package:platinumstore_app/ui/screens/checkout_bottom_sheet.dart';
import 'package:platinumstore_app/features/account/ui/account_screen.dart';
import 'package:platinumstore_app/features/account/ui/account_controller.dart';
import 'account_test.dart' show FakeAccountGateway;
import 'cart_storage_test.dart' show MemoryCartStorage;
import 'checkout_controller_test.dart' show CheckoutFixture, checkoutQuote;

void main() {
  group('CheckoutBottomSheet', () {
    for (final register in [false, true]) {
      testWidgets(
          'should retain guest cart after successful ${register ? 'registration' : 'login'}',
          (tester) async {
        final storage = MemoryCartStorage();
        final cart = CartProvider(
            storage: storage, quoteLoader: (_) async => checkoutQuote('same'));
        cart.addItem(Product(
            id: '1', offerId: '11', name: 'Телефон', price: 1000, image: ''));
        cart.incrementQuantity(cart.items.keys.single);
        cart.addItem(Product(
            id: '2', offerId: '22', name: 'Чехол', price: 100, image: ''));
        cart.selectItem('2:22', false);
        await cart.pendingWrites;
        final before =
            storage.rows.map((row) => Map<String, dynamic>.of(row)).toList();
        final auth = FakeAccountGateway()..needRegister = register;
        final account = AccountController(auth);
        await account.initialize();
        final gateway = CheckoutFixture();
        await tester.pumpWidget(ChangeNotifierProvider.value(
            value: cart,
            child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: CheckoutBottomSheet(
                    gateway: gateway, loginController: account))));
        await tester.pumpAndSettle();
        final name = find.byKey(const ValueKey('checkout-first_name'));
        await tester.ensureVisible(name);
        await tester.enterText(name, 'Получатель');
        await tester.ensureVisible(find.text('Войти'));
        await tester.tap(find.text('Войти'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountScreen), findsOneWidget);
        // Only the transport is substituted: the real login controller,
        // AccountScreen, checkout navigation and CartProvider all execute.
        await tester.enterText(find.byType(TextField), '9991234567');
        await tester.tap(find.text('Получить код'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '1234');
        gateway.authorized = true;
        gateway.profile = {'first_name': 'Из профиля', 'phone': '79991234567'};
        await tester.tap(find.text('Войти'));
        await tester.pumpAndSettle();
        if (register) {
          expect(account.step, AccountStep.registration);
          await account.register('Анна', 'Петрова', true);
          await tester.pumpAndSettle();
        }
        expect(account.step, AccountStep.account);
        expect(find.byType(AccountScreen), findsNothing);
        expect(find.byType(CheckoutBottomSheet), findsOneWidget);
        expect(find.text('Вход или регистрация'), findsNothing);
        expect(
            tester.widget<TextFormField>(name).controller!.text, 'Получатель');
        expect(cart.items.keys, ['1:11', '2:22']);
        expect(cart.items['1:11']!.quantity, 2);
        expect(cart.isSelected('2:22'), isFalse);
        expect(cart.orderItems, [
          {'id': 11, 'quantity': 2}
        ]);
        await cart.pendingWrites;
        expect(storage.rows, before);
        expect(gateway.sent, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        account.dispose();
        cart.dispose();
      });
    }
    testWidgets('guest login returns to the preserved checkout form',
        (tester) async {
      final cart =
          CartProvider(quoteLoader: (_) async => checkoutQuote('same'));
      cart.addItem(Product(id: '1', name: 'Телефон', price: 1000, image: ''));
      final gateway = CheckoutFixture();
      await tester.pumpWidget(ChangeNotifierProvider.value(
          value: cart,
          child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: CheckoutBottomSheet(gateway: gateway))));
      await tester.pumpAndSettle();
      expect(find.text('Вход или регистрация'), findsOneWidget);
      final name = find.byKey(const ValueKey('checkout-first_name'));
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Моё имя');
      await tester.ensureVisible(find.text('Войти'));
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsOneWidget);
      gateway.authorized = true;
      gateway.profile = {'first_name': 'Из профиля', 'phone': '79991234567'};
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Вход или регистрация'), findsNothing);
      expect(tester.widget<TextFormField>(name).controller!.text, 'Моё имя');
      final phone = tester
          .widget<TextFormField>(find.byKey(const ValueKey('checkout-phone')));
      expect(phone.controller!.text, '+7 (999) 123-45-67');
      expect(gateway.sent, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      cart.dispose();
    });
    for (final (width, scale) in [(320.0, 1.0), (360.0, 2.0), (600.0, 1.0)]) {
      testWidgets('should support delivery and validation at $width/$scale',
          (tester) async {
        tester.view.physicalSize = Size(width * 2, 1800);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final cart =
            CartProvider(quoteLoader: (_) async => checkoutQuote('same'));
        final gateway = CheckoutFixture();
        cart.addItem(
            Product(id: '1', name: 'Телефон 256 ГБ', price: 1000, image: ''));
        await tester.pumpWidget(ChangeNotifierProvider.value(
            value: cart,
            child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: CheckoutBottomSheet(gateway: gateway))));
        await tester.pumpAndSettle();
        expect(find.text('Способ получения'), findsOneWidget);
        final selected = tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Самовывоз'));
        expect(selected.labelStyle!.color, Colors.white);
        expect(selected.checkmarkColor, Colors.white);
        await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Доставка'));
        await tester.tap(find.widgetWithText(ChoiceChip, 'Доставка'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('checkout-delivery_address')),
            findsOneWidget);
        for (var i = 0; i < 12; i++) {
          await tester.drag(
              find.byType(SingleChildScrollView), const Offset(0, -500));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.ensureVisible(find.text('Подтвердить заказ'));
        await tester.tap(find.text('Подтвердить заказ'));
        await tester.pumpAndSettle();
        expect(gateway.sent, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        cart.dispose();
      });
    }
  });
}
