import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/product_model.dart';
import '../data/models/product_detail_model.dart';

class SavedProduct {
  final Product product;
  final String skuId;
  final List<ProductSpec> specs;
  const SavedProduct(this.product, this.skuId, this.specs);
  Map<String, dynamic> toJson() => {
        'id': product.id,
        'sku': skuId,
        'name': product.name,
        'price': product.price,
        'image': product.image,
        'specs': specs
            .map((s) => {'name': s.name, 'value': s.value, 'group': s.group})
            .toList()
      };
  factory SavedProduct.fromJson(Map<String, dynamic> j) =>
      SavedProduct(Product.fromJson(j), '${j['sku']}', parseSpecs(j['specs']));
}

class SavedProductsProvider extends ChangeNotifier {
  final Map<String, SavedProduct> favorites = {};
  final Map<String, SavedProduct> comparison = {};
  File? _file;
  bool ready = false;
  String? error;
  bool _disposed = false;
  Future<void> _writes = Future.value();
  Future<void> load() async {
    try {
      _file = File(
          '${(await getApplicationSupportDirectory()).path}/saved-products.json');
      if (await _file!.exists()) {
        final j = jsonDecode(await _file!.readAsString()) as Map;
        for (final entry in [
          ('favorites', favorites),
          ('comparison', comparison)
        ]) {
          for (final value in (j[entry.$1] as List? ?? [])) {
            final saved =
                SavedProduct.fromJson(Map<String, dynamic>.from(value));
            entry.$2[saved.skuId] = saved;
          }
        }
      }
    } catch (_) {
      error = 'Не удалось загрузить сохранённые товары';
    }
    if (_disposed) return;
    ready = true;
    notifyListeners();
  }

  void toggle(SavedProduct product, {bool compare = false}) {
    if (!ready) return;
    final target = compare ? comparison : favorites;
    target.containsKey(product.skuId)
        ? target.remove(product.skuId)
        : target[product.skuId] = product;
    error = null;
    notifyListeners();
    final contents = jsonEncode({
      'favorites': favorites.values.map((s) => s.toJson()).toList(),
      'comparison': comparison.values.map((s) => s.toJson()).toList()
    });
    _writes = _writes.then((_) async {
      try {
        if (_file == null) {
          throw const FileSystemException('Storage unavailable');
        }
        await _file!.writeAsString(contents, flush: true);
      } catch (_) {
        if (!_disposed) {
          error = 'Не удалось сохранить товары на устройстве';
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
