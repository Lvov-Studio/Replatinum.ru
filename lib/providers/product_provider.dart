import 'package:flutter/material.dart';
import '../data/api/api_service.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _error = '';
  String _loadMoreError = '';
  Category? _selectedCategory;
  int _total = 0;
  int _offset = 0;
  static const int _pageSize = 10;

  String? _type;
  int _requestId = 0;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get error => _error;
  String get loadMoreError => _loadMoreError;
  Category? get selectedCategory => _selectedCategory;
  int get total => _total;
  bool get hasMore => _products.length < _total;

  /// Первичная загрузка (с нуля)
  Future<void> fetchProducts({Category? category, String? type}) async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = '';
    _loadMoreError = '';
    _selectedCategory = category;
    _type = type;
    _offset = 0;
    _products = [];
    notifyListeners();

    try {
      final result = await _apiService.getProducts(
        categoryId: category?.id,
        type: type,
        limit: _pageSize,
        offset: 0,
      );
      if (requestId != _requestId) return;
      _products = result['products'] as List<Product>;
      _total = result['total'] as int;
      _offset = _products.length;
    } catch (e) {
      if (requestId != _requestId) return;
      _error = e.toString();
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Загрузить следующую страницу
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    _loadMoreError = '';
    notifyListeners();

    try {
      final result = await _apiService.getProducts(
        categoryId: _selectedCategory?.id,
        type: _type,
        limit: _pageSize,
        offset: _offset,
      );
      final newProducts = result['products'] as List<Product>;
      _products.addAll(newProducts);
      _total = result['total'] as int;
      _offset = _products.length;
    } catch (e) {
      _loadMoreError = 'Не удалось загрузить ещё товары';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Переключение категории (вызывается из MainScreen при тапе на категорию)
  void setCategory(Category? category) {
    fetchProducts(category: category);
  }

  /// Сброс категории — возврат к экрану разделов
  void clearCategory() {
    _requestId++;
    _selectedCategory = null;
    _products = [];
    _total = 0;
    _offset = 0;
    _error = '';
    _loadMoreError = '';
    notifyListeners();
  }
}
