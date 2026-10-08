import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/cart_storage.dart';
import 'package:platinumstore_app/data/models/cart_quote.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/data/models/product_detail_model.dart';
import 'package:platinumstore_app/providers/cart_provider.dart';

class MemoryCartStorage implements CartStorage {
  List<Map<String, dynamic>> rows = [];
  Completer<List<Map<String, dynamic>>>? pending;
  @override
  Future<List<Map<String, dynamic>>> read() async =>
      pending == null ? rows : await pending!.future;
  @override
  Future<void> write(List<Map<String, dynamic>> items) async {
    rows = items;
  }
}

void main() {
  group('CartStorage', () {
    CartProvider make(MemoryCartStorage storage) => CartProvider(
        storage: storage,
        quoteLoader: (_) async => const CartQuote(
            id: 'fresh',
            subtotalMinor: 100000,
            discountMinor: 0,
            totalMinor: 100000));

    test(
        'should restore SKU, quantities and selection and obtain a fresh quote',
        () async {
      final storage = MemoryCartStorage();
      final first = make(storage);
      first.addItem(Product(id: '1', name: 'Телефон', price: 1000, image: ''),
          offer: const Offer(
              id: '2',
              name: '256 ГБ',
              image: '',
              price: 1200,
              properties: [
                OfferProperty(code: 'MEMORY', name: 'Память', value: '256 ГБ')
              ]));
      first.incrementQuantity(first.items.keys.single);
      first.addItem(Product(id: '3', name: 'Кабель', price: 100, image: ''));
      first.selectItem('3:base', false);
      await first.pendingWrites;
      first.dispose();
      final restored = make(storage);
      await restored.load();
      expect(restored.itemCount, 3);
      expect(restored.selectedItems.single.catalogId, '2');
      expect(restored.selectedItems.single.variantLabel, '256 ГБ');
      expect(restored.selectedItems.single.quantity, 2);
      expect(restored.quote!.id, 'fresh');
      expect(restored.isSelected('3:base'), isFalse);
      restored.clear();
      await restored.pendingWrites;
      expect(storage.rows, isEmpty);
      restored.dispose();
    });

    test('should not overwrite user actions with a late restore', () async {
      final storage = MemoryCartStorage()..pending = Completer();
      final cart = make(storage);
      final load = cart.load();
      cart.addItem(Product(id: '9', name: 'Новый', price: 1000, image: ''));
      storage.pending!.complete([
        {
          'product': {'id': '1', 'price': 100},
          'quantity': 1
        }
      ]);
      await load;
      await cart.pendingWrites;
      expect(cart.items.values.single.catalogId, '9');
      cart.dispose();
    });

    test('should cap quantity at the server limit', () async {
      final cart = make(MemoryCartStorage());
      final product = Product(id: '1', name: 'Товар', price: 1000, image: '');
      for (var i = 0; i < 105; i++) {
        cart.addItem(product);
      }
      cart.incrementQuantity(cart.items.keys.single);
      expect(cart.itemCount, 100);
      await cart.pendingWrites;
      cart.dispose();
    });

    test(
        'should restore a pending submission and lock changes until confirmation',
        () async {
      final storage = MemoryCartStorage();
      final first = make(storage);
      first.addItem(Product(id: '1', name: 'Телефон', price: 1000, image: ''));
      await first.refreshQuote();
      expect(first.beginCheckout(), isTrue);
      await first.rememberCheckout({
        'request_id': 'a' * 32,
        'items': first.orderItems,
        'delivery_type': 'pickup',
        'pickup_store': 'sbs',
        'expected_total_minor': 100000
      });
      first.dispose();
      final restored = make(storage);
      await restored.load();
      expect(restored.pendingCheckout!['request_id'], 'a' * 32);
      expect(restored.checkoutInProgress, isTrue);
      restored.clear();
      expect(restored.items, isNotEmpty);
      restored.endCheckout(completed: true);
      await restored.pendingWrites;
      expect(storage.rows, isEmpty);
      restored.dispose();
    });
  });
}
