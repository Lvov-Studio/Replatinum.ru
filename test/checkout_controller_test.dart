import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/models/cart_quote.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/features/account/data/account_gateway.dart';
import 'package:platinumstore_app/features/checkout/data/checkout_gateway.dart';
import 'package:platinumstore_app/features/checkout/ui/checkout_controller.dart';
import 'package:platinumstore_app/providers/cart_provider.dart';

class CheckoutFixture implements CheckoutGateway {
  final sent = <Map<String, dynamic>>[];
  bool authorized = false;
  Map<String, dynamic> profile = {};
  Future<Map<String, dynamic>> Function()? respond;
  @override
  Future<Map<String, dynamic>> context() async => {
        'success': true,
        'schema_version': 1,
        'city_delivery_minor': 100000,
        'payment_types': ['cash'],
        'authorized': authorized,
        'profile': profile,
        'pickup_stores': [
          {
            'id': 'sbs',
            'name': 'СБС',
            'address': 'Уральская',
            'available': true
          },
          {
            'id': 'severnaya',
            'name': 'Северная',
            'address': 'Северная',
            'available': false
          },
        ],
      };
  @override
  Future<Map<String, dynamic>> submit(Map<String, dynamic> payload) async {
    sent.add(Map.of(payload));
    return respond == null
        ? {'success': true, 'order_id': 601}
        : await respond!();
  }

  @override
  void dispose() {}
}

const checkoutFields = {
  'first_name': 'Анна',
  'phone': '+7 (999) 123-45-67',
  'email': ''
};
CartQuote checkoutQuote(String id) => CartQuote(
    id: id, subtotalMinor: 100000, discountMinor: 0, totalMinor: 100000);

void main() {
  group('CheckoutController', () {
    late CartProvider cart;
    late CheckoutFixture gateway;
    late CheckoutController controller;
    setUp(() async {
      cart = CartProvider(quoteLoader: (_) async => checkoutQuote('same'));
      cart.addItem(Product(
          id: '1', offerId: '2', name: 'Телефон', price: 1000, image: ''));
      await Future<void>.delayed(Duration.zero);
      gateway = CheckoutFixture();
      controller = CheckoutController(cart, gateway);
      await controller.initialize();
    });
    tearDown(() {
      controller.dispose();
      cart.dispose();
    });

    test('should reject incomplete phone, blank name and unavailable store',
        () async {
      expect(CheckoutController.validateName('   '), isNotNull);
      expect(CheckoutController.validatePhone('+7 999'), isNotNull);
      expect(CheckoutController.validateEmail(''), isNull);
      controller.chooseStore('severnaya');
      expect(controller.pickupStore, isEmpty);
      expect(await controller.submit(checkoutFields, consent: true), isFalse);
      expect(gateway.sent, isEmpty);
    });

    test(
        'should send selected SKU and server total then remove only purchased items',
        () async {
      cart.addItem(Product(id: '3', name: 'Оставить', price: 1000, image: ''));
      cart.selectItem('3:base', false);
      await Future<void>.delayed(Duration.zero);
      controller.chooseStore('sbs');
      expect(await controller.submit(checkoutFields, consent: true), isTrue);
      expect(gateway.sent.single['items'], [
        {'id': 2, 'quantity': 1}
      ]);
      expect(gateway.sent.single['phone'], '79991234567');
      expect(gateway.sent.single['payment_type'], 'cash');
      expect(controller.orderId, 601);
      expect(cart.items.keys, ['3:base']);
      expect(await controller.submit(checkoutFields, consent: true), isFalse);
    });

    test('should include city delivery and reject missing delivery address',
        () async {
      controller.chooseDelivery('delivery');
      expect(controller.totalMinor, 200000);
      expect(await controller.submit(checkoutFields, consent: true), isFalse);
      expect(
          await controller.submit(
              {...checkoutFields, 'delivery_address': 'Краснодар, дом 1'},
              consent: true),
          isTrue);
      expect(gateway.sent.single['expected_total_minor'], 200000);
      expect(gateway.sent.single['pickup_store'], isEmpty);
    });

    test('should stop before submission if price changes', () async {
      controller.dispose();
      cart.dispose();
      var count = 0;
      cart =
          CartProvider(quoteLoader: (_) async => checkoutQuote('${count++}'));
      cart.addItem(Product(id: '1', name: 'Товар', price: 1000, image: ''));
      await Future<void>.delayed(Duration.zero);
      controller = CheckoutController(cart, gateway);
      await controller.initialize();
      controller.chooseStore('sbs');
      expect(await controller.submit(checkoutFields, consent: true), isFalse);
      expect(controller.error, contains('изменилась'));
      expect(gateway.sent, isEmpty);
      expect(cart.checkoutInProgress, isFalse);
    });

    test('should lock mutations and reject a simultaneous second submission',
        () async {
      final pending = Completer<Map<String, dynamic>>();
      gateway.respond = () => pending.future;
      controller.chooseStore('sbs');
      final first = controller.submit(checkoutFields, consent: true);
      await Future<void>.delayed(Duration.zero);
      cart.clear();
      cart.incrementQuantity(cart.items.keys.single);
      expect(cart.itemCount, 1);
      expect(await controller.submit(checkoutFields, consent: true), isFalse);
      pending.complete({'success': true, 'order_id': 602});
      expect(await first, isTrue);
      expect(gateway.sent, hasLength(1));
    });

    test('should retry the identical request after an unconfirmed response',
        () async {
      controller.chooseStore('sbs');
      gateway.respond =
          () async => throw const AccountFailure('timeout', uncertain: true);
      expect(await controller.submit(checkoutFields, consent: true), isFalse);
      expect(controller.awaitingConfirmation, isTrue);
      cart.clear();
      expect(cart.items, isNotEmpty);
      gateway.respond = () async => {'success': true, 'order_id': 601};
      expect(await controller.submit(checkoutFields, consent: true), isTrue);
      expect(gateway.sent[1], gateway.sent[0]);
      expect(cart.items, isEmpty);
    });

    test(
        'should preserve cart after a confirmed rejection or missing order number',
        () async {
      controller.chooseStore('sbs');
      gateway.respond =
          () async => throw const AccountFailure('Недостаточно товара');
      expect(await controller.submit(checkoutFields, consent: true), isFalse);
      expect(cart.items, isNotEmpty);
      expect(controller.awaitingConfirmation, isFalse);
      gateway.respond = () async => {'success': true};
      expect(await controller.submit(checkoutFields, consent: true), isFalse);
      expect(cart.items, isNotEmpty);
      expect(controller.orderId, isNull);
    });
  });
}
