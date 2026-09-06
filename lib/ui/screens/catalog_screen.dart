import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'product_detail_screen.dart';
import 'product_search_delegate.dart';

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
      // Загружаем категории если нет
      context.read<CategoryProvider>().fetchCategories();
      // Если передана категория — грузим товары, иначе ничего
      if (widget.initialCategory != null) {
        context.read<ProductProvider>().fetchProducts(category: widget.initialCategory);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // ── Строка поиска ──────────────────────────────────
          Container(
            color: AppColors.darkAccent,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GestureDetector(
              onTap: () => showSearch(
                context: context,
                delegate: ProductSearchDelegate(),
              ),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Поиск по каталогу...',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 15),
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Контент ────────────────────────────────────────
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, _) {
                // Если категория выбрана — показываем товары
                if (productProvider.selectedCategory != null) {
                  return _ProductsView(provider: productProvider);
                }
                // Иначе — сетка разделов
                return _CategoriesView();
              },
            ),
          ),
        ],
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
                const Icon(Icons.wifi_off, size: 64, color: AppColors.secondaryText),
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

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _CategoryCard(
                    category: catProvider.categories[index],
                  ),
                  childCount: catProvider.categories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        );
      },
    );
  }
}

// ─── Карточка категории (как на сайте) ─────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final Category category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ProductProvider>().fetchProducts(category: category);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название раздела
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainText,
                  height: 1.25,
                ),
                maxLines: 2,
              ),
            ),
            // Картинка раздела
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: category.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: category.image,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: Color(0xFFCCCCCC),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.category_outlined,
                            size: 64, color: Color(0xFFCCCCCC)),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Страница товаров внутри раздела ───────────────────────────────────────
class _ProductsView extends StatelessWidget {
  final ProductProvider provider;
  const _ProductsView({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Заголовок раздела + кнопка назад к разделам
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => provider.clearCategory(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: AppColors.mainText),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.selectedCategory?.name ?? 'Каталог',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${provider.total} товаров',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: provider.isLoading && provider.products.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryAccent))
              : provider.products.isEmpty
                  ? const Center(
                      child: Text('Товары не найдены',
                          style: TextStyle(color: AppColors.secondaryText)))
                  : CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(12),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _ProductCard(product: provider.products[index]),
                              childCount: provider.products.length,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.62,
                            ),
                          ),
                        ),
                        if (provider.hasMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: provider.isLoadingMore
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                            color: AppColors.primaryAccent),
                                      ))
                                  : OutlinedButton(
                                      onPressed: () => provider.loadMore(),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryAccent,
                                        side: const BorderSide(
                                            color: AppColors.primaryAccent,
                                            width: 1.5),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                      child: Text(
                                        'Показать ещё '
                                        '(осталось ${provider.total - provider.products.length})',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      ],
                    ),
        ),
      ],
    );
  }
}

// ─── Карточка товара ────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  String _fmt(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00A0');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productPreview: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  color: const Color(0xFFF8F8F8),
                  width: double.infinity,
                  child: product.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryAccent),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.image_outlined,
                                size: 48, color: Color(0xFFCCCCCC)),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_outlined,
                              size: 48, color: Color(0xFFCCCCCC)),
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontSize: 11, height: 1.35),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.price > 0
                          ? '${_fmt(product.price.toInt())} ₽'
                          : 'По запросу',
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('В корзину',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
