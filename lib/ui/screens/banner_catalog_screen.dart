import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/api/api_service.dart';
import '../../data/banner_destination.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/catalog_products_view.dart';

class BannerCatalogScreen extends StatefulWidget {
  const BannerCatalogScreen(
      {super.key, required this.destination, this.apiService});
  final BannerDestination destination;
  final ApiService? apiService;

  @override
  State<BannerCatalogScreen> createState() => _BannerCatalogScreenState();
}

class _BannerCatalogScreenState extends State<BannerCatalogScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  late final ProductProvider _products = ProductProvider(apiService: _api);
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final categories = await _api.getCategories();
      if (!mounted) return;
      final category = categories
          .where((c) => c.code == widget.destination.categoryCode)
          .first;
      _products.fetchProducts(
          category: category, subsection: widget.destination.section);
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _products.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: _loading || _failed
          ? AppBar(title: Text(widget.destination.section?.title ?? 'Каталог'))
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Не удалось открыть раздел'),
                  TextButton(onPressed: _load, child: const Text('Повторить')),
                ]))
              : ChangeNotifierProvider.value(
                  value: _products,
                  child: Consumer<ProductProvider>(
                      builder: (context, provider, _) => CatalogProductsView(
                          provider: provider,
                          onBack: () => Navigator.of(context).pop()))));
}
