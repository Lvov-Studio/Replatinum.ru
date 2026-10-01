import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/models/cart_quote.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/data/models/product_detail_model.dart';
import 'package:platinumstore_app/providers/cart_provider.dart';

Product product(String id, {num price = 1000}) =>
    Product(id: id, name: 'Аксессуар', image: '', price: price);
CartQuote quote(String id, int total, {int discount = 0}) => CartQuote(
      id: id,
      subtotalMinor: total + discount,
      discountMinor: discount,
      totalMinor: total,
    );

void main() {
  group('CartProvider', () {
    test('should submit the selected preview SKU instead of its parent',
        () async {
      List<Map<String, dynamic>>? submitted;
      final cart = CartProvider(quoteLoader: (items) async {
        submitted = items;
        return quote('sku', 100000);
      });
      cart.addItem(Product(
          id: '100', offerId: '101', name: 'SKU', price: 1000, image: ''));
      await Future<void>.delayed(Duration.zero);
      expect(submitted!.single['id'], 101);
    });
    test('should use server discount and invalidate it when quantity changes',
        () async {
      final requests = <Completer<CartQuote>>[];
      final cart = CartProvider(quoteLoader: (_) {
        final request = Completer<CartQuote>();
        requests.add(request);
        return request.future;
      });
      cart.addItem(product('1'));
      expect(cart.canCheckout, isFalse);
      requests[0].complete(quote('one', 90000, discount: 10000));
      await Future<void>.delayed(Duration.zero);
      expect(cart.totalAmount, 900);
      expect(cart.canCheckout, isTrue);
      cart.incrementQuantity(cart.items.keys.single);
      expect(cart.quote, isNull);
      expect(cart.discountAmount, 0);
      requests[1].complete(quote('two', 170000, discount: 30000));
      await Future<void>.delayed(Duration.zero);
      expect(cart.totalAmount, 1700);
    });

    test('should ignore an older quote arriving after the latest quote',
        () async {
      final requests = <Completer<CartQuote>>[];
      final cart = CartProvider(quoteLoader: (_) {
        final request = Completer<CartQuote>();
        requests.add(request);
        return request.future;
      });
      cart.addItem(product('1'));
      cart.incrementQuantity(cart.items.keys.single);
      requests[1].complete(quote('new', 170000));
      await Future<void>.delayed(Duration.zero);
      requests[0].complete(quote('old', 90000));
      await Future<void>.delayed(Duration.zero);
      expect(cart.quote!.id, 'new');
      expect(cart.totalAmount, 1700);
    });

    test(
        'should keep checkout disabled after a failed quote and recover on retry',
        () async {
      var fail = true;
      final cart = CartProvider(quoteLoader: (_) async {
        if (fail) throw Exception('offline');
        return quote('retry', 100000);
      });
      cart.addItem(product('1'));
      await Future<void>.delayed(Duration.zero);
      expect(cart.canCheckout, isFalse);
      expect(cart.quoteError, isNotEmpty);
      fail = false;
      expect(await cart.refreshQuote(), isTrue);
      expect(cart.quoteError, isEmpty);
    });

    test('should not add a zero-price offer using the parent price', () {
      final cart =
          CartProvider(quoteLoader: (_) async => quote('unexpected', 100000));
      cart.addItem(product('1'),
          offer: const Offer(
              id: '2', name: '', image: '', price: 0, properties: []));
      expect(cart.items, isEmpty);
    });

    test('should discard a pending quote after clearing the basket', () async {
      final request = Completer<CartQuote>();
      final cart = CartProvider(quoteLoader: (_) => request.future);
      cart.addItem(product('1'));
      cart.clear();
      request.complete(quote('old', 100000));
      await Future<void>.delayed(Duration.zero);
      expect(cart.quote, isNull);
      expect(cart.checking, isFalse);
      expect(cart.canCheckout, isFalse);
    });
  });
}
