import 'package:flutter/material.dart';
import '../data/api/api_service.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  bool _isLoading = false;
  String _error = '';
  Category? _selectedCategory; // текущая выбранная категория

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get error => _error;
  Category? get selectedCategory => _selectedCategory;

  Future<void> fetchProducts({Category? category}) async {
    _isLoading = true;
    _error = '';
    _selectedCategory = category;
    notifyListeners();

    try {
      _products = await _apiService.getProducts(
        categoryId: category?.id,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
