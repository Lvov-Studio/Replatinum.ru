import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
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
      context.read<ProductProvider>().fetchProducts(
        category: widget.initialCategory,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFromCategory = widget.initialCategory != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: isFromCategory
          ? AppBar(
              backgroundColor: AppColors.darkAccent,
              foregroundColor: Colors.white,
              title: Text(
                widget.initialCategory!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: ProductSearchDelegate(),
                    );
                  },
                ),
              ],
            )
          : const CustomAppBar(),
      body: Column(
        children: [
          // ── Строка поиска (как на главной) ───────────────
          Container(
            color: AppColors.darkAccent,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GestureDetector(
              onTap: () {
                showSearch(
                  context: context,
                  delegate: ProductSearchDelegate(),
                );
              },
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
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 15,
                        ),
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

          // ── Сетка товаров ────────────────────────────────
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryAccent),
                  );
                }

                if (provider.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 64, color: AppColors.secondaryText),
                        const SizedBox(height: 16),
                        Text(
                          'Не удалось загрузить товары',
                          style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchProducts(category: widget.initialCategory),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.products.isEmpty) {
                  return const Center(
                    child: Text(
                      'Товары не найдены',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    return _ProductCard(product: provider.products[index]);
                  },
                );
              },
            ),
          ), // Expanded
        ],
      ), // Column
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productPreview: product),
          ),
        );
      },
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
            // ── Фото товара ──────────────────────────
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  color: const Color(0xFFF8F8F8),
                  width: double.infinity,
                  child: product.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Color(0xFFCCCCCC),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                ),
              ),
            ),

            // ── Информация ────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Цена
                    Text(
                      product.price > 0
                          ? '${_formatPrice(product.price.toInt())} ₽'
                          : 'Цена по запросу',
                      style: TextStyle(
                        fontSize: product.price > 0 ? 16 : 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryAccent,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Кнопка В корзину
                    SizedBox(
                      width: double.infinity,
                      height: 34,
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'В корзину',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
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

  String _formatPrice(int price) {
    // Форматируем цену с разделителем тысяч: 49990 → 49 990
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00A0'); // неразрывный пробел
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
