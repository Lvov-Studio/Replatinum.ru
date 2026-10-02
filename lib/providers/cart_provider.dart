import 'package:flutter/material.dart';
import '../data/models/product_detail_model.dart';
import '../data/models/product_model.dart';
import '../data/models/cart_quote.dart';
import '../data/api/api_service.dart';

class CartItem {
  final Product product;
  final Offer? offer;
  final int quantity;

  const CartItem({required this.product, this.offer, this.quantity = 1});

  String get key => '${product.id}:${offer?.id ?? product.offerId ?? 'base'}';
  String get catalogId => offer?.id ?? product.offerId ?? product.id;
  num get unitPrice => offer?.price ?? product.price;
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
  final Set<String> _excluded = {};
  final Future<CartQuote> Function(List<Map<String, dynamic>>) _quoteLoader;
  CartQuote? _quote;
  int _revision = 0;
  bool _checking = false;
  String _quoteError = '';

  CartProvider(
      {Future<CartQuote> Function(List<Map<String, dynamic>>)? quoteLoader})
      : _quoteLoader = quoteLoader ?? ApiService().quoteCart;

  CartQuote? get quote => _quote;
  bool get checking => _checking;
  String get quoteError => _quoteError;
  bool get canCheckout =>
      selectedItems.isNotEmpty && _quote != null && !_checking;
  List<CartItem> get selectedItems =>
      _items.values.where((item) => isSelected(item.key)).toList();
  bool isSelected(String key) => !_excluded.contains(key);
  bool get allSelected => _items.isNotEmpty && _excluded.isEmpty;
  int get selectedCount =>
      selectedItems.fold(0, (count, item) => count + item.quantity);
  void selectItem(String key, bool selected) {
    if (!_items.containsKey(key)) return;
    selected ? _excluded.remove(key) : _excluded.add(key);
    _changed();
  }

  void selectAll(bool selected) {
    _excluded.clear();
    if (!selected) _excluded.addAll(_items.keys);
    _changed();
  }

  void removeSelected() {
    for (final item in selectedItems) {
      _items.remove(item.key);
    }
    _changed();
  }

  num get discountAmount => (_quote?.discountMinor ?? 0) / 100;
  num get subtotal =>
      _quote != null ? _quote!.subtotalMinor / 100 : _localTotal;
  num priceFor(CartItem item) =>
      _quote?.unitPrices[item.catalogId] ?? item.unitPrice;
  List<Map<String, dynamic>> get orderItems => [
        for (final item in selectedItems)
          {'id': int.tryParse(item.catalogId) ?? 0, 'quantity': item.quantity}
      ];

  Future<bool> refreshQuote() async {
    final revision = ++_revision;
    _quote = null;
    _quoteError = '';
    if (selectedItems.isEmpty) {
      _checking = false;
      notifyListeners();
      return false;
    }
    _checking = true;
    notifyListeners();
    try {
      final quote = await _quoteLoader(orderItems);
      if (revision != _revision) return false;
      _quote = quote;
    } catch (_) {
      if (revision != _revision) return false;
      _quoteError = 'Не удалось проверить цену и скидку. Повторите проверку.';
    }
    if (revision != _revision) return false;
    _checking = false;
    notifyListeners();
    return _quote != null;
  }

  void _changed() {
    refreshQuote();
  }

  Map<String, CartItem> get items => Map.unmodifiable(_items);

  @override
  void dispose() {
    _revision++;
    super.dispose();
  }

  int get itemCount {
    int count = 0;
    _items.forEach((key, item) {
      count += item.quantity;
    });
    return count;
  }

  double get totalAmount =>
      _quote != null ? _quote!.totalMinor / 100 : _localTotal;

  double get _localTotal {
    var total = 0.0;
    for (final item in selectedItems) {
      total += item.unitPrice * item.quantity;
    }
    return total;
  }

  void addItem(Product product, {Offer? offer}) {
    final item = CartItem(product: product, offer: offer);
    if (item.unitPrice <= 0 || (offer?.canBuy ?? product.canBuy) == false) {
      return;
    }
    _excluded.remove(item.key);
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
    _changed();
  }

  void removeItem(String itemKey) {
    _items.remove(itemKey);
    _excluded.remove(itemKey);
    _changed();
  }

  void incrementQuantity(String itemKey) {
    if (_items.containsKey(itemKey)) {
      _items.update(
        itemKey,
        (existingCartItem) => existingCartItem.copyWith(
          quantity: existingCartItem.quantity + 1,
        ),
      );
      _changed();
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
      _excluded.remove(itemKey);
    }
    _changed();
  }

  void clear() {
    _items.clear();
    _excluded.clear();
    _changed();
  }
}
