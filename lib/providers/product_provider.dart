import 'package:flutter/material.dart';
import '../data/api/api_service.dart';
import '../data/catalog_navigation.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';
import '../data/models/catalog_filter.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();
  final ApiService _apiService;
  List<CatalogItem> _items = [];
  String? _path;
  String? _subsectionTitle;
  bool _browsing = true;
  List<CatalogNode> get subsections =>
      (catalogNavigation[_selectedCategory?.code] ?? [])
          .where(
              (node) => _items.any((item) => item.path.startsWith(node.path)))
          .toList();
  bool get browsing => _browsing && subsections.isNotEmpty;
  String get sectionTitle =>
      _subsectionTitle ?? _selectedCategory?.name ?? 'Каталог';
  Iterable<CatalogItem> get _baseItems =>
      _items.where((item) => _path == null || item.path.startsWith(_path!));
  List<CatalogNode> childrenOf(CatalogNode node) => node.children
      .where((child) => _items.any((item) => item.path.startsWith(child.path)))
      .toList();
  String imageOf(CatalogNode node) => _items
      .firstWhere((item) => item.path.startsWith(node.path))
      .product
      .image;
  void openSubsection([CatalogNode? node]) {
    _path = node?.path;
    _subsectionTitle = node?.title;
    _browsing = false;
    _filters = const CatalogFilters();
    _sort = CatalogSort.original;
    _visible = 20;
    notifyListeners();
  }

  void goBack() {
    if (!_browsing && subsections.isNotEmpty) {
      _browsing = true;
      _path = null;
      _subsectionTitle = null;
      _filters = const CatalogFilters();
      notifyListeners();
    } else {
      clearCategory();
    }
  }

  bool _isLoading = false;
  String _error = '';
  Category? _selectedCategory;
  String? _type;
  int _requestId = 0;
  int _visible = 20;
  CatalogFilters _filters = const CatalogFilters();
  CatalogSort _sort = CatalogSort.original;
  CatalogFilters get filters => _filters;
  CatalogSort get sort => _sort;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => false;
  String get error => _error;
  String get loadMoreError => '';
  Category? get selectedCategory => _selectedCategory;
  int get sectionTotal => _items.length;
  int get total => _filtered.length;
  bool get hasMore => total > _visible;
  List<Product> get products =>
      _filtered.take(_visible).map((item) => item.product).toList();

  List<CatalogItem> get _filtered {
    final result = _baseItems.where((item) => item.matches(_filters)).toList();
    switch (_sort) {
      case CatalogSort.original:
        break;
      case CatalogSort.priceAscending:
        result.sort((a, b) =>
            (a.product.price <= 0 ? double.infinity : a.product.price)
                .compareTo(
                    b.product.price <= 0 ? double.infinity : b.product.price));
      case CatalogSort.priceDescending:
        result.sort((a, b) => b.product.price.compareTo(a.product.price));
      case CatalogSort.name:
        result.sort((a, b) => a.product.name.compareTo(b.product.name));
    }
    return result;
  }

  Map<String, (String, List<String>)> get facets {
    final labels = <String, String>{};
    final values = <String, Set<String>>{};
    for (final item in _baseItems) {
      for (final entry in item.attributes.entries) {
        labels[entry.key] = entry.value.label;
        (values[entry.key] ??= {}).add(entry.value.value);
      }
    }
    int priority(String label) {
      final text = label.toLowerCase();
      if (text.contains('бренд') || text.contains('производител')) return 0;
      if (text.contains('год')) return 1;
      if (text.contains('цвет')) return 2;
      if (text.contains('модель')) return 3;
      if (text.contains('объем памяти') || text.contains('объём памяти')) {
        return 4;
      }
      if (text.contains('оперативн')) return 5;
      if (text.contains('sim')) return 6;
      return 7;
    }

    final keys = values.keys.where((key) => values[key]!.length > 1).toList()
      ..sort((a, b) {
        final rank = priority(labels[a]!).compareTo(priority(labels[b]!));
        return rank == 0 ? labels[a]!.compareTo(labels[b]!) : rank;
      });
    final originalLabels = {...labels};
    for (final key in keys) {
      final label = originalLabels[key]!;
      if (keys.where((k) => originalLabels[k] == label).length > 1) {
        labels[key] =
            '$label · ${key.startsWith('model:') ? 'модель' : 'вариант'}';
      }
    }
    return {
      for (final key in keys) key: (labels[key]!, values[key]!.toList()..sort())
    };
  }

  (double, double) get priceBounds {
    final prices = _baseItems
        .map((item) => item.product.price.toDouble())
        .where((p) => p > 0)
        .toList()
      ..sort();
    return prices.isEmpty ? (0, 0) : (prices.first, prices.last);
  }

  int countMatching(CatalogFilters filters) =>
      _baseItems.where((item) => item.matches(filters)).length;
  void applyFilters(CatalogFilters filters) {
    _filters = filters;
    _visible = 20;
    notifyListeners();
  }

  void setSort(CatalogSort sort) {
    _sort = sort;
    _visible = 20;
    notifyListeners();
  }

  Future<void> fetchProducts({Category? category, String? type}) async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = '';
    _selectedCategory = category;
    _path = null;
    _subsectionTitle = null;
    _browsing = true;
    _type = type;
    _items = [];
    _filters = const CatalogFilters();
    _sort = CatalogSort.original;
    _visible = 20;
    notifyListeners();
    try {
      final items = await _apiService.getCatalogItems(
          categoryId: category?.id,
          type: type,
          isCurrent: () => requestId == _requestId);
      if (requestId != _requestId) return;
      _items = items;
    } catch (_) {
      if (requestId != _requestId) return;
      _error = 'Не удалось загрузить товары и фильтры';
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() =>
      fetchProducts(category: _selectedCategory, type: _type);
  Future<void> loadMore() async {
    _visible += 20;
    notifyListeners();
  }

  void setCategory(Category? category) {
    fetchProducts(category: category);
  }

  void clearCategory() {
    _requestId++;
    _selectedCategory = null;
    _path = null;
    _subsectionTitle = null;
    _browsing = true;
    _items = [];
    _error = '';
    _isLoading = false;
    _filters = const CatalogFilters();
    _sort = CatalogSort.original;
    _visible = 20;
    notifyListeners();
  }
}
