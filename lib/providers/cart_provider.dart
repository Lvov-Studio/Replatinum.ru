import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import '../data/models/product_detail_model.dart';
import '../data/models/product_model.dart';
import '../data/models/cart_quote.dart';
import '../data/api/api_service.dart';
import '../data/cart_storage.dart';

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
          .where((property) =>
              property.value.trim().isNotEmpty &&
              !const ['NEWPRODUCT', 'SALELEADER', 'DISCOUNT']
                  .contains(property.code))
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
  final CartStorage? _storage;
  Future<void> _writes = Future.value();
  bool _disposed = false, _loaded = false;
  bool checkoutInProgress = false;
  Map<String, dynamic>? pendingCheckout;
  String storageError = '';
  CartQuote? _quote;
  int _revision = 0;
  bool _checking = false;
  String _quoteError = '';

  CartProvider(
      {Future<CartQuote> Function(List<Map<String, dynamic>>)? quoteLoader,
      CartStorage? storage})
      : _storage = storage,
        _quoteLoader = quoteLoader ?? ApiService().quoteCart;

  Future<void> get pendingWrites => _writes;

  Future<void> load() async {
    if (_loaded || _storage == null) return;
    _loaded = true;
    final revision = _revision;
    try {
      final rows = await _storage.read();
      if (_disposed || revision != _revision) return;
      Map<String, dynamic>? pending;
      for (final row in rows) {
        try {
          if (row['checkout_pending'] is Map) {
            pending = Map<String, dynamic>.from(row['checkout_pending']);
            continue;
          }
          final product =
              Product.fromJson(Map<String, dynamic>.from(row['product']));
          final offer = row['offer'] is Map
              ? Offer.fromJson(Map<String, dynamic>.from(row['offer']))
              : null;
          final quantity = row['quantity'];
          if (quantity is! int || quantity < 1 || quantity > 100) continue;
          final item =
              CartItem(product: product, offer: offer, quantity: quantity);
          if (int.tryParse(item.catalogId) == null || item.unitPrice <= 0) {
            continue;
          }
          _items[item.key] = item;
          if (row['selected'] == false) _excluded.add(item.key);
        } catch (_) {
          // A damaged row must not discard the other saved products.
        }
      }
      if (pending != null &&
          RegExp(r'^[a-f0-9]{32}$').hasMatch('${pending['request_id']}') &&
          pending['items'] is List &&
          listEquals(
              (pending['items'] as List)
                  .map((row) => '${row['id']}:${row['quantity']}')
                  .toList(),
              orderItems
                  .map((row) => '${row['id']}:${row['quantity']}')
                  .toList())) {
        pendingCheckout = pending;
        checkoutInProgress = true;
      }
      await refreshQuote();
    } catch (_) {
      if (_disposed) return;
      storageError = 'Не удалось восстановить корзину.';
      notifyListeners();
    }
  }

  void _persist() {
    if (_storage == null) return;
    final rows = [
      if (pendingCheckout != null) {'checkout_pending': pendingCheckout},
      for (final item in _items.values)
        {
          'product': {
            'id': item.product.id,
            'offer_id': item.product.offerId,
            'name': item.product.name,
            'price': item.product.price,
            'store_price': item.product.storePrice,
            'image': item.product.image,
            'can_buy': item.product.canBuy,
            'rustore_warning': item.product.ruStoreWarning
          },
          if (item.offer case final offer?)
            'offer': {
              'id': offer.id,
              'name': offer.name,
              'price': offer.price,
              'image': offer.image,
              'store_price': offer.storePrice,
              'can_buy': offer.canBuy,
              'properties': [
                for (final p in offer.properties)
                  {
                    'code': p.code,
                    'name': p.name,
                    'value': p.value,
                    'image': p.image
                  }
              ]
            },
          'quantity': item.quantity,
          'selected': isSelected(item.key),
        }
    ];
    _writes = _writes.then((_) async {
      try {
        await _storage.write(rows);
        if (!_disposed && storageError.isNotEmpty) {
          storageError = '';
          notifyListeners();
        }
      } catch (_) {
        if (_disposed) return;
        storageError = 'Не удалось сохранить корзину на устройстве.';
        notifyListeners();
      }
    });
  }

  bool beginCheckout() {
    if (!canCheckout) return false;
    checkoutInProgress = true;
    notifyListeners();
    return true;
  }

  Future<void> rememberCheckout(Map<String, dynamic> payload) async {
    pendingCheckout = Map.of(payload);
    _persist();
    await pendingWrites;
    if (_storage != null && storageError.isNotEmpty) {
      pendingCheckout = null;
      _persist();
      throw const CartApiFailure(
          'Не удалось сохранить подтверждение на устройстве. Повторите попытку.');
    }
  }

  void endCheckout({bool completed = false}) {
    pendingCheckout = null;
    if (completed) {
      for (final item in selectedItems) {
        _items.remove(item.key);
        _excluded.remove(item.key);
      }
    }
    checkoutInProgress = false;
    if (completed) {
      _changed();
    } else if (!_disposed) {
      _persist();
      notifyListeners();
    }
  }

  CartQuote? get quote => _quote;
  bool get checking => _checking;
  String get quoteError => _quoteError;
  bool get canCheckout =>
      selectedItems.isNotEmpty &&
      _quote != null &&
      !_checking &&
      !checkoutInProgress;
  List<CartItem> get selectedItems =>
      _items.values.where((item) => isSelected(item.key)).toList();
  bool isSelected(String key) => !_excluded.contains(key);
  bool get allSelected => _items.isNotEmpty && _excluded.isEmpty;
  int get selectedCount =>
      selectedItems.fold(0, (count, item) => count + item.quantity);
  void selectItem(String key, bool selected) {
    if (checkoutInProgress) return;
    if (!_items.containsKey(key)) return;
    selected ? _excluded.remove(key) : _excluded.add(key);
    _changed();
  }

  void selectAll(bool selected) {
    if (checkoutInProgress) return;
    _excluded.clear();
    if (!selected) _excluded.addAll(_items.keys);
    _changed();
  }

  void removeSelected() {
    if (checkoutInProgress) return;
    for (final item in selectedItems) {
      _items.remove(item.key);
    }
    _changed();
  }

  num get discountAmount => (_quote?.discountMinor ?? 0) / 100;
  // Match the site: savings include the difference from the store price
  // and the server's accessory promotion. Only selected goods contribute.
  num get displaySubtotal {
    final storeTotal = selectedItems.fold<num>(0, (sum, item) {
      final storePrice = item.offer?.storePrice ?? item.product.storePrice;
      final price = priceFor(item);
      return sum + (storePrice > price ? storePrice : price) * item.quantity;
    });
    return storeTotal > subtotal ? storeTotal : subtotal;
  }

  num get displayDiscount => quote == null ? 0 : displaySubtotal - totalAmount;
  num get subtotal =>
      _quote != null ? _quote!.subtotalMinor / 100 : _localTotal;
  num priceFor(CartItem item) =>
      _quote?.unitPrices[item.catalogId] ?? item.unitPrice;
  num lineTotalFor(CartItem item) =>
      (_quote?.lineTotalsMinor[item.catalogId] ??
          (priceFor(item) * item.quantity * 100).round()) /
      100;
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
    } catch (error) {
      if (revision != _revision) return false;
      _quoteError = error is CartApiFailure
          ? error.message
          : 'Не удалось проверить цену и скидку. Повторите проверку.';
    }
    if (revision != _revision) return false;
    _checking = false;
    notifyListeners();
    return _quote != null;
  }

  void _changed() {
    _persist();
    refreshQuote();
  }

  Map<String, CartItem> get items => Map.unmodifiable(_items);

  @override
  void dispose() {
    _disposed = true;
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
    if (checkoutInProgress) return;
    final item = CartItem(product: product, offer: offer);
    if (item.unitPrice <= 0 || (offer?.canBuy ?? product.canBuy) == false) {
      return;
    }
    _excluded.remove(item.key);
    if (_items.containsKey(item.key)) {
      if (_items[item.key]!.quantity >= 100) return;
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
    if (checkoutInProgress) return;
    _items.remove(itemKey);
    _excluded.remove(itemKey);
    _changed();
  }

  void incrementQuantity(String itemKey) {
    if (checkoutInProgress || (_items[itemKey]?.quantity ?? 0) >= 100) return;
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
    if (checkoutInProgress) return;
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
    if (checkoutInProgress) return;
    _items.clear();
    _excluded.clear();
    _changed();
  }
}
