// Emulator-only fixture. Release continues to use lib/main.dart.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/data/models/cart_quote.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/providers/cart_provider.dart';
import 'package:platinumstore_app/ui/screens/cart_screen.dart';

void main() {
  final cart = CartProvider(quoteLoader: (items) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final quantity =
        items.fold<int>(0, (sum, item) => sum + item['quantity'] as int);
    final subtotal = quantity * 199900;
    final percent = quantity >= 3
        ? 20
        : quantity >= 2
            ? 15
            : 10;
    final discount = (subtotal * percent / 10000).round() * 100;
    return CartQuote(
        id: 'fixture-$quantity',
        subtotalMinor: subtotal,
        discountMinor: discount,
        totalMinor: subtotal - discount,
        promotionName: 'Тестовая акция на аксессуары',
        hint: quantity < 3
            ? 'Добавьте ещё ${3 - quantity} аксессуар(а) — получите скидку 20%'
            : '');
  });
  final product = Product(
      id: 'fixture',
      name: 'Тестовый чехол для смартфона',
      price: 1999,
      image: '');
  cart.addItem(product);
  cart.addItem(product);
  runApp(ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const CartScreen())));
}
