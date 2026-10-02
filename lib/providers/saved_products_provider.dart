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
        'offer_id': product.offerId,
        'store_price': product.storePrice,
        'can_buy': product.canBuy,
        'image': product.image,
        'rustore_warning': product.ruStoreWarning,
        'specs': specs
            .map((s) => {
                  'name': s.name,
                  'value': s.value,
                  'group': s.group,
                  'code': s.code
                })
            .toList()
      };
  factory SavedProduct.fromJson(Map<String, dynamic> j) =>
      SavedProduct(Product.fromJson(j), '${j['sku']}', parseSpecs(j['specs']));
}

abstract class SavedProductsRemote {
  Future<Map<String, List<SavedProduct>>> fetch();
  Future<void> set(SavedProduct product,
      {required bool enabled, required bool compare});
}

class SavedProductsProvider extends ChangeNotifier {
  final Map<String, SavedProduct> favorites = {};
  final Map<String, SavedProduct> comparison = {};
  File? _file;
  bool ready = false;
  String? error;
  bool _disposed = false;
  Future<void> _writes = Future.value();
  SavedProductsRemote? _remote;
  Map<String, SavedProduct>? _guestFavorites, _guestComparison;
  Future<void> _remoteWrites = Future.value();
  bool syncing = false;
  int _remoteVersion = 0;
  bool get accountConnected => _remote != null;
  Future<void> connect(SavedProductsRemote remote) async {
    disconnect(notify: false);
    _guestFavorites = Map.of(favorites);
    _guestComparison = Map.of(comparison);
    favorites.clear();
    comparison.clear();
    _remote = remote;
    await refreshRemote();
  }

  Future<void> refreshRemote() async {
    final remote = _remote;
    if (remote == null || syncing) return;
    final version = _remoteVersion;
    syncing = true;
    error = null;
    notifyListeners();
    try {
      await _remoteWrites;
      final lists = await remote.fetch();
      if (_disposed || version != _remoteVersion) return;
      favorites
        ..clear()
        ..addEntries(
            (lists['favorites'] ?? []).map((p) => MapEntry(p.skuId, p)));
      comparison
        ..clear()
        ..addEntries(
            (lists['comparison'] ?? []).map((p) => MapEntry(p.skuId, p)));
    } catch (_) {
      if (!_disposed && version == _remoteVersion) {
        error = 'Не удалось обновить сохранённые товары. Повторите обновление.';
      }
    } finally {
      if (!_disposed && version == _remoteVersion) {
        syncing = false;
        notifyListeners();
      }
    }
  }

  void disconnect({bool notify = true}) {
    _remoteVersion++;
    _remote = null;
    syncing = false;
    if (_guestFavorites != null) {
      favorites
        ..clear()
        ..addAll(_guestFavorites!);
      comparison
        ..clear()
        ..addAll(_guestComparison!);
      _guestFavorites = null;
      _guestComparison = null;
    }
    error = null;
    if (notify && !_disposed) notifyListeners();
  }

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
    if (!ready || syncing) return;
    final target = compare ? comparison : favorites;
    final enabled = !target.containsKey(product.skuId);
    target.containsKey(product.skuId)
        ? target.remove(product.skuId)
        : target[product.skuId] = product;
    error = null;
    notifyListeners();
    final remote = _remote;
    if (remote != null) {
      final version = _remoteVersion;
      _remoteWrites = _remoteWrites.then((_) async {
        if (_disposed || version != _remoteVersion) return;
        try {
          await remote.set(product, enabled: enabled, compare: compare);
        } catch (_) {
          if (!_disposed && version == _remoteVersion) {
            // Roll back only if this mutation is still the latest local intent.
            if (target.containsKey(product.skuId) == enabled) {
              enabled
                  ? target.remove(product.skuId)
                  : target[product.skuId] = product;
            }
            error = 'Не удалось сохранить на сайте. Повторите действие.';
            notifyListeners();
          }
        }
      });
      return;
    }
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
