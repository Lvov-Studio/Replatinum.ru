import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/product_model.dart';

/// Device-local viewing history. The latest variant replaces the same model.
class RecentProductsProvider extends ChangeNotifier {
  RecentProductsProvider({File? storage}) : _file = storage;
  File? _file;
  final List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  bool _disposed = false;

  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    try {
      _file ??= File(
          '${(await getApplicationSupportDirectory()).path}/recent-products.json');
      if (await _file!.exists()) {
        final entries = jsonDecode(await _file!.readAsString()) as List;
        _products.addAll(entries
            .map((j) => Product.fromJson(Map<String, dynamic>.from(j)))
            .where((p) => p.id.isNotEmpty)
            .take(20));
      }
    } catch (_) {
      // History is optional; unavailable storage must not block shopping.
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> record(Product product) async {
    await load();
    if (_disposed || product.id.isEmpty) return;
    _products.removeWhere((p) => p.id == product.id);
    _products.insert(0, product);
    if (_products.length > 20) _products.removeRange(20, _products.length);
    notifyListeners();
    final contents = jsonEncode(_products
        .map((p) => {
              'id': p.id,
              'name': p.name,
              'price': p.price,
              'image': p.image,
              'offer_id': p.offerId,
              'store_price': p.storePrice,
              'can_buy': p.canBuy,
              'rustore_warning': p.ruStoreWarning,
            })
        .toList());
    _writes = _writes.then((_) async {
      try {
        await _file?.writeAsString(contents, flush: true);
      } catch (_) {
        // Viewing history is best effort when the device cannot write.
      }
    });
    await _writes;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
