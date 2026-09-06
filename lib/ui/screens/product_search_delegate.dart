import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/api/api_service.dart';
import '../../data/models/product_model.dart';
import '../../core/theme/app_colors.dart';
import 'product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final ApiService _apiService = ApiService();

  @override
  String get searchFieldLabel => 'Поиск товаров...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white54),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _DebouncedSearchSuggestions(query: query, apiService: _apiService);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().length < 2) {
      return const Center(
        child: Text(
          'Введите минимум 2 символа для поиска',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }
    return _DebouncedSearchSuggestions(query: query, apiService: _apiService);
  }
}

class _DebouncedSearchSuggestions extends StatefulWidget {
  final String query;
  final ApiService apiService;

  const _DebouncedSearchSuggestions({required this.query, required this.apiService});

  @override
  State<_DebouncedSearchSuggestions> createState() => _DebouncedSearchSuggestionsState();
}

class _DebouncedSearchSuggestionsState extends State<_DebouncedSearchSuggestions> {
  Timer? _debounce;
  Future<List<Product>>? _future;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void didUpdateWidget(covariant _DebouncedSearchSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _search();
    }
  }

  void _search() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _future = widget.apiService.searchProducts(widget.query);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      // Пока ждем дебаунса
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка поиска: ${snapshot.error}'));
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return const Center(child: Text('Ничего не найдено'));
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final product = results[index];
            return ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: product.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                      )
                    : const Icon(Icons.image),
              ),
              title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${product.price} ₽',
                style: const TextStyle(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(productPreview: product),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
