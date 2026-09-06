import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../data/models/product_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/banner_slider.dart';
import 'product_search_delegate.dart';
import 'catalog_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      context.read<ProductProvider>().fetchProducts(); // Загружаем популярные товары
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Строка поиска
            Container(
              color: AppColors.darkAccent,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () {
                  showSearch(
                    context: context,
                    delegate: ProductSearchDelegate(),
                  );
                },
                child: Container(
                  height: 48,
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
                          style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          borderRadius: BorderRadius.circular(8), // Скругление как у кнопки
                        ),
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Слайдер с баннерами
            const SizedBox(height: 16),
            const BannerSlider(),
            
            // Заголовок категорий
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'Популярные категории',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainText,
                ),
              ),
            ),

            // Горизонтальная лента категорий
            SizedBox(
              height: 110,
              child: Consumer<CategoryProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error.isNotEmpty) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () => provider.fetchCategories(),
                        child: const Text('Повторить'),
                      ),
                    );
                  }

                  if (provider.categories.isEmpty) {
                    return const Center(child: Text('Категории не найдены'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final category = provider.categories[index];
                      return GestureDetector(
                        onTap: () {
                          // Открываем каталог с фильтром по выбранной категории
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CatalogScreen(
                                initialCategory: category,
                              ),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 80,
                          child: Column(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: AppColors.primaryAccent,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4), // Отступ между рамкой и картинкой
                                child: Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: category.image.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: category.image,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          errorWidget: (context, url, error) => const Icon(
                                            Icons.image_not_supported,
                                            color: AppColors.secondaryText,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.category,
                                          color: AppColors.secondaryText,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.mainText,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 8),

            // ── Популярные товары ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Популярные товары',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainText,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CatalogScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Все товары →',
                      style: TextStyle(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Горизонтальная лента карточек товаров
            SizedBox(
              height: 240,
              child: Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                      ),
                    );
                  }
                  if (provider.products.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.products.length > 10
                        ? 10
                        : provider.products.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _HomeProductCard(
                        product: provider.products[index],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Карточка товара для главной ───────────────────────────────────────────────
class _HomeProductCard extends StatelessWidget {
  final Product product;
  const _HomeProductCard({required this.product});

  String _formatPrice(int price) {
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
          builder: (_) => ProductDetailScreen(productPreview: product),
        ),
      ),
      child: Container(
        width: 150,
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
            // Фото
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 130,
                color: const Color(0xFFF8F8F8),
                width: double.infinity,
                child: product.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.image_outlined,
                              size: 40, color: Color(0xFFCCCCCC)),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_outlined,
                            size: 40, color: Color(0xFFCCCCCC)),
                      ),
              ),
            ),
            // Инфо
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 11, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      product.price > 0
                          ? '${_formatPrice(product.price.toInt())} ₽'
                          : 'По запросу',
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<CartProvider>().addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Добавлено в корзину'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppColors.primaryAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
