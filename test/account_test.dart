import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/features/account/data/account_gateway.dart';
import 'package:platinumstore_app/features/account/ui/account_controller.dart';
import 'package:platinumstore_app/features/account/ui/account_screen.dart';

class FakeAccountGateway implements AccountGateway {
  final calls = <(String, Map<String, String>)>[];
  bool authorized = false, needRegister = false, expire = false;
  Completer<Map<String, dynamic>>? sending;
  var reconnects = 0;
  Map<String, dynamic> profile = {
    'name': 'Иван',
    'last_name': 'Петров',
    'phone': '+7 (999) 123-45-67',
    'email': 'a@example.com'
  };
  @override
  Future<Map<String, dynamic>> request(String action,
      [Map<String, String> fields = const {}]) async {
    calls.add((action, fields));
    if (expire) throw const AccountFailure('Войдите снова', unauthorized: true);
    if (action == 'bootstrap') {
      return {'success': true, 'authorized': authorized};
    }
    if (action == 'send_code') {
      return sending == null ? {'success': true} : await sending!.future;
    }
    if (action == 'verify_code') {
      if (fields['code'] != '1234') throw const AccountFailure('Неверный код');
      authorized = !needRegister;
      return {'success': true, if (needRegister) 'need_register': true};
    }
    if (action == 'register') {
      authorized = true;
      return {'success': true};
    }
    if (action == 'remember') return {'success': true};
    if (action == 'summary') {
      return {
        'success': true,
        'summary': {'orders_count': 2, 'orders_total': 200}
      };
    }
    if (action == 'address') {
      return {
        'success': true,
        'address': {'city': 'Краснодар', 'street': 'Северная'}
      };
    }
    if (action == 'address_update') return {'success': true, 'address': fields};
    if (action == 'order_detail') {
      return {
        'success': true,
        'order': {
          'id': fields['id'],
          'number': '100',
          'date': '02.10.2026',
          'status': 'Новый',
          'paid': false,
          'price': 100,
          'currency': 'RUB',
          'delivery_price': 0,
          'items': [
            {'name': 'Телефон', 'quantity': 1, 'price': 100, 'currency': 'RUB'}
          ]
        }
      };
    }
    if (action == 'profile') return {'success': true, 'profile': profile};
    if (action == 'profile_update') {
      profile = {...profile, ...fields};
      return {'success': true, 'profile': profile};
    }
    if (action == 'orders') {
      return {
        'success': true,
        'orders': [
          {
            'id': fields['offset'] == '0' ? '1' : '2',
            'number': fields['offset'] == '0' ? '100' : '101',
            'date': '02.10.2026',
            'price': 100,
            'currency': 'RUB',
            'status': 'Новый'
          }
        ],
        'next_offset': fields['offset'] == '0' ? 1 : 2,
        'has_more': fields['offset'] == '0'
      };
    }
    if (action == 'logout') {
      authorized = false;
      return {'success': true};
    }
    throw StateError('Unexpected action: $action');
  }

  @override
  Future<void> reconnect() async {
    reconnects++;
  }

  @override
  void cancelChallenge() {
    sending?.completeError(const AccountFailure('', cancelled: true));
  }

  @override
  void dispose() {}
}

void main() {
  test('guest restore never sends SMS; invalid numbers never hit server',
      () async {
    final gateway = FakeAccountGateway();
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    await account.initialize();
    expect(account.step, AccountStep.phone);
    await account.sendCode('123');
    expect(gateway.calls.map((call) => call.$1), ['bootstrap']);
    expect(account.error, isNotEmpty);
    expect(
        AccountController.normalizePhone('8 (999) 123-45-67'), '79991234567');
    expect(AccountController.normalizePhone('+7 499 123-45-67'), '');
  });
  test(
      'SMS duplicate guard, cooldown and verification use the confirmed number',
      () async {
    var now = DateTime(2026, 10, 2);
    final gateway = FakeAccountGateway()..sending = Completer();
    final account = AccountController(gateway, now: () => now);
    addTearDown(account.dispose);
    final first = account.sendCode('+7 (999) 123-45-67');
    await account.sendCode('+7 (999) 123-45-67');
    expect(gateway.calls.length, 1);
    gateway.sending!.complete({'success': true});
    await first;
    expect(account.step, AccountStep.code);
    expect(account.resendSeconds, 60);
    await account.sendCode(account.phone);
    expect(gateway.calls.length, 1);
    await account.verifyCode('1111');
    expect(account.step, AccountStep.code);
    expect(account.error, 'Неверный код');
    await account.verifyCode('1234');
    expect(account.step, AccountStep.account);
    expect(account.profile?['name'], 'Иван');
    expect(gateway.reconnects, 2);
    expect(gateway.calls.first.$2['phone'], '79991234567');
    now = now.add(const Duration(seconds: 61));
    expect(account.resendSeconds, 0);
  });
  test(
      'new user needs consent, then profile; expired session wipes private data',
      () async {
    final gateway = FakeAccountGateway()..needRegister = true;
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    await account.sendCode('9991234567');
    await account.verifyCode('1234');
    expect(account.step, AccountStep.registration);
    await account.register('Иван', 'Петров', false);
    expect(gateway.calls.where((call) => call.$1 == 'register'), isEmpty);
    await account.register('Иван', 'Петров', true);
    expect(account.step, AccountStep.account);
    await account.loadOrders();
    expect(account.orders.single['id'], '1');
    expect(account.hasMoreOrders, true);
    await account.loadOrders(more: true);
    expect(account.orders.length, 2);
    expect(account.hasMoreOrders, false);
    gateway.expire = true;
    await account.loadOrders();
    expect(account.step, AccountStep.phone);
    expect(account.profile, isNull);
    expect(account.orders, isEmpty);
  });
  test(
      'restores account without SMS, saves profile, confirms logout before clearing',
      () async {
    final gateway = FakeAccountGateway()..authorized = true;
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    await account.initialize();
    expect(account.step, AccountStep.account);
    await account.saveProfile('Анна', 'Петрова', 'new@example.com');
    expect(account.profile?['name'], 'Анна');
    await account.logout();
    expect(account.step, AccountStep.phone);
    expect(account.profile, isNull);
    expect(gateway.calls.any((call) => call.$1 == 'send_code'), false);
  });
  test('disposing during pending SMS ignores late results', () async {
    final gateway = FakeAccountGateway()..sending = Completer();
    final account = AccountController(gateway);
    final result = account.sendCode('9991234567');
    account.dispose();
    gateway.sending!.complete({'success': true});
    await result;
    expect(account.step, AccountStep.phone);
  });
  for (final (width, scale) in [(320.0, 1.0), (360.0, 2.0), (600.0, 1.0)]) {
    testWidgets('phone, code and registration fit $width/$scale',
        (tester) async {
      tester.view.physicalSize = Size(width * 2, 1600);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final gateway = FakeAccountGateway()..needRegister = true;
      final account = AccountController(gateway);
      addTearDown(account.dispose);
      await account.initialize();
      await tester
          .pumpWidget(MaterialApp(home: AccountScreen(controller: account)));
      expect(find.text('Вход по номеру телефона'), findsOneWidget);
      await account.sendCode('9991234567');
      await tester.pumpAndSettle();
      expect(find.text('Введите код из SMS'), findsOneWidget);
      expect(tester.getSize(find.byKey(const ValueKey('sms-code'))).width, 168);
      await tester.enterText(find.byKey(const ValueKey('sms-code')), '12a345');
      expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('sms-code')))
              .controller!
              .text,
          '1234');
      expect(tester.takeException(), isNull);
      await account.verifyCode('1234');
      await tester.pumpAndSettle();
      expect(find.text('Завершим знакомство'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('authenticated orders have empty/error retry and profile editing',
      (tester) async {
    final gateway = FakeAccountGateway()..authorized = true;
    final account = AccountController(gateway);
    addTearDown(account.dispose);
    await account.initialize();
    await tester
        .pumpWidget(MaterialApp(home: AccountScreen(controller: account)));
    await tester.tap(find.text('Мои заказы'));
    await tester.pumpAndSettle();
    expect(find.text('Заказ № 100'), findsOneWidget);
    await tester.tap(find.text('Показать ещё'));
    await tester.pumpAndSettle();
    expect(find.text('Заказ № 101'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Личные данные'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Анна');
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Данные сохранены'), findsOneWidget);
  });
}
