import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../data/models/category_model.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../widgets/catalog_category_list.dart';
import '../widgets/saved_products_shortcuts.dart';
import 'main_screen.dart';
import 'product_search_delegate.dart';
import '../widgets/catalog_products_view.dart';

class CatalogScreen extends StatefulWidget {
  final Category? initialCategory;
  const CatalogScreen({super.key, this.initialCategory});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Загружаем категории если нет
      context.read<CategoryProvider>().fetchCategories();
      // Если передана категория — грузим товары, иначе ничего
      if (widget.initialCategory != null) {
        context
            .read<ProductProvider>()
            .fetchProducts(category: widget.initialCategory);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    return PopScope(
      canPop: productProvider.selectedCategory == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && productProvider.selectedCategory != null) {
          productProvider.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: productProvider.selectedCategory != null
            ? null
            : AppBar(
                toolbarHeight: 48,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.mainText,
                surfaceTintColor: Colors.white,
                scrolledUnderElevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                leading: IconButton(
                  tooltip: 'Открыть меню',
                  onPressed: () =>
                      MainScreen.scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
                actions: const [SavedProductsActions(), SizedBox(width: 8)],
              ),
        body: Column(
          children: [
            if (productProvider.selectedCategory == null)
              Material(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: InkWell(
                    key: const ValueKey('catalog-search'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => showSearch(
                      context: context,
                      delegate: ProductSearchDelegate(),
                    ),
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8ED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(children: [
                              const Icon(Icons.search,
                                  size: 20, color: AppColors.secondaryText),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: const Text('Поиск товаров',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: AppColors.mainText,
                                          fontSize: 14))),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (productProvider.selectedCategory == null)
              const Divider(height: 1, thickness: 1, color: AppColors.border),
            // ── Контент ────────────────────────────────────────
            Expanded(
              child: productProvider.selectedCategory != null
                  ? CatalogProductsView(provider: productProvider)
                  : _CategoriesView(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Страница категорий (по умолчанию) ─────────────────────────────────────
class _CategoriesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        if (catProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          );
        }
        if (catProvider.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off,
                    size: 64, color: AppColors.secondaryText),
                const SizedBox(height: 12),
                const Text('Не удалось загрузить разделы',
                    style: TextStyle(color: AppColors.secondaryText)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => catProvider.fetchCategories(),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }
        if (catProvider.categories.isEmpty) {
          return const Center(child: Text('Разделы не найдены'));
        }

        return CatalogCategoryList(
          categories: catProvider.categories,
          onSelected: (category) =>
              context.read<ProductProvider>().fetchProducts(category: category),
        );
      },
    );
  }
}
