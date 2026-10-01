import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';
import '../data/models/product_detail_model.dart';
import '../data/models/product_model.dart';

enum PurchaseAction { cart, preorder, order, checkAvailability }

class ProductDetailController extends ChangeNotifier {
  final Product preview;
  final ApiService _api;
  ProductDetail? detail;
  Offer? selectedOffer;
  bool loading = true;
  String? error;
  bool _disposed = false;
  int _loadVersion = 0;
  ProductDetailController(this.preview, {ApiService? api})
      : _api = api ?? ApiService();
  Future<void> load() async {
    final version = ++_loadVersion;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _api.getProductDetail(preview.id);
      if (_disposed || version != _loadVersion) return;
      detail = result;
      selectedOffer = result.offers.isEmpty ? null : result.offers.first;
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      error = 'Не удалось загрузить товар';
    }
    if (_disposed || version != _loadVersion) return;
    loading = false;
    notifyListeners();
  }

  String get id => selectedOffer?.id ?? detail?.id ?? preview.id;
  String get name => selectedOffer?.name ?? detail?.name ?? preview.name;
  // Zero is a real SKU price; never borrow the parent or another SKU price.
  num get price => selectedOffer?.price ?? detail?.price ?? 0;
  num get storePrice => selectedOffer?.storePrice ?? detail?.storePrice ?? 0;
  bool? get canBuy =>
      selectedOffer?.canBuy ?? (selectedOffer == null ? detail?.canBuy : null);
  PurchaseAction get action => price <= 0
      ? PurchaseAction.order
      : canBuy == true
          ? PurchaseAction.cart
          : canBuy == false
              ? PurchaseAction.preorder
              : PurchaseAction.checkAvailability;
  String get actionLabel => switch (action) {
        PurchaseAction.cart => 'В корзину',
        PurchaseAction.preorder => 'Предзаказ',
        PurchaseAction.order => 'Под заказ',
        PurchaseAction.checkAvailability => 'Уточнить наличие'
      };
  List<String> get images {
    final o = selectedOffer;
    if (o != null && o.images.isNotEmpty) return o.images;
    if (o != null && o.image.isNotEmpty) return [o.image];
    return detail?.images ?? [];
  }

  List<ProductSpec> get specs => selectedOffer?.specs ?? detail?.specs ?? [];
  String get description => selectedOffer?.description.isNotEmpty == true
      ? selectedOffer!.description
      : detail?.description ?? '';
  Product get cartProduct => Product(
      id: detail!.id,
      name: name,
      price: price,
      image: images.isEmpty ? preview.image : images.first,
      ruStoreWarning: detail!.ruStoreWarning);
  Map<String, List<OfferProperty>> get variantGroups {
    final groups = <String, Map<String, OfferProperty>>{};
    for (final o in detail?.offers ?? <Offer>[]) {
      for (final p in o.properties) {
        if (!const ['COLOR', 'MEMORY', 'SIM', 'CVETREM'].contains(p.code) ||
            p.value.isEmpty) {
          continue;
        }
        groups.putIfAbsent(p.code, () => {}).putIfAbsent(p.value, () => p);
      }
    }
    final ordered = <String, List<OfferProperty>>{};
    for (final code in const ['COLOR', 'MEMORY', 'SIM', 'CVETREM']) {
      final values = groups[code]?.values.toList();
      if (values == null) continue;
      if (code == 'MEMORY') {
        values.sort((a, b) => _memory(a.value).compareTo(_memory(b.value)));
      }
      ordered[code] = values;
    }
    return ordered;
  }

  num _memory(String value) {
    final size =
        num.tryParse(RegExp(r'[\d.]+').firstMatch(value)?.group(0) ?? '') ?? 0;
    return RegExp(r'тб|tb', caseSensitive: false).hasMatch(value)
        ? size * 1024
        : size;
  }

  String label(OfferProperty p) {
    if (p.code != 'COLOR' ||
        !RegExp(r'^[a-zA-Z0-9]{5,16}$').hasMatch(p.value)) {
      return p.value;
    }
    for (final o in detail?.offers ?? <Offer>[]) {
      if (o.valueOf('COLOR') != p.value) continue;
      final match =
          RegExp(r'(?:ГБ|GB|ТБ|TB)\s*[,;]?\s*(.*?)\s*\(', caseSensitive: false)
              .firstMatch(o.name);
      if (match != null && match.group(1)!.isNotEmpty) return match.group(1)!;
    }
    return 'Вариант цвета';
  }

  String imageFor(OfferProperty p) {
    if (p.image.isNotEmpty) return p.image;
    for (final o in detail?.offers ?? <Offer>[]) {
      if (o.valueOf(p.code) == p.value && o.image.isNotEmpty) return o.image;
    }
    return '';
  }

  void select(String code, String value) {
    final candidates = (detail?.offers ?? <Offer>[])
        .where((o) => o.valueOf(code) == value)
        .toList();
    if (candidates.isEmpty) return;
    int score(Offer o) => variantGroups.keys
        .where((k) => k != code && o.valueOf(k) == selectedOffer?.valueOf(k))
        .length;
    var best = candidates.first;
    for (final o in candidates.skip(1)) {
      if (score(o) > score(best) ||
          (score(o) == score(best) &&
              o.canBuy == true &&
              best.canBuy != true)) {
        best = o;
      }
    }
    selectedOffer = best;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
