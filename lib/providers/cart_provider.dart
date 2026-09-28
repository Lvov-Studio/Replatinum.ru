import 'package:flutter/material.dart';
import '../data/models/product_detail_model.dart';
import '../data/models/product_model.dart';

class CartItem {
  final Product product;
  final Offer? offer;
  final int quantity;

  const CartItem({required this.product, this.offer, this.quantity = 1});

  String get key => '${product.id}:${offer?.id ?? 'base'}';
  String get catalogId => offer?.id ?? product.id;
  num get unitPrice =>
      offer != null && offer!.price > 0 ? offer!.price : product.price;
  String get image =>
      offer?.image.isNotEmpty == true ? offer!.image : product.image;
  String get variantLabel =>
      offer?.properties
          .where((property) => property.value.trim().isNotEmpty)
          .map((property) => property.value)
          .join(' · ') ??
      '';

  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        offer: offer,
        quantity: quantity ?? this.quantity,
      );
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount {
    int count = 0;
    _items.forEach((key, item) {
      count += item.quantity;
    });
    return count;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.unitPrice * item.quantity;
    });
    return total;
  }

  void addItem(Product product, {Offer? offer}) {
    final item = CartItem(product: product, offer: offer);
    if (_items.containsKey(item.key)) {
      _items.update(
        item.key,
        (existingCartItem) => existingCartItem.copyWith(
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        item.key,
        () => item,
      );
    }
    notifyListeners();
  }

  void removeItem(String itemKey) {
    _items.remove(itemKey);
    notifyListeners();
  }

  void incrementQuantity(String itemKey) {
    if (_items.containsKey(itemKey)) {
      _items.update(
        itemKey,
        (existingCartItem) => existingCartItem.copyWith(
          quantity: existingCartItem.quantity + 1,
        ),
      );
      notifyListeners();
    }
  }

  void decrementQuantity(String itemKey) {
    if (!_items.containsKey(itemKey)) return;

    if (_items[itemKey]!.quantity > 1) {
      _items.update(
        itemKey,
        (existingCartItem) => existingCartItem.copyWith(
          quantity: existingCartItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(itemKey);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
