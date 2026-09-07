import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/category_provider.dart';
import '../../providers/cart_provider.dart';
import '../../data/api/api_service.dart';
import '../../data/models/product_model.dart';
import '../../data/models/news_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/banner_slider.dart';
import 'product_search_delegate.dart';
import 'main_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();

  late Future<List<Product>> _saleFuture;
  late Future<List<Product>> _newFuture;
  late Future<List<Product>> _hitFuture;
  late Future<List<NewsItem>> _newsFuture;

  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().fetchCategories();
    _saleFuture = _loadSection('sale');
    _newFuture  = _loadSection('new');
    _hitFuture  = _loadSection('hit');
    _newsFuture = _api.getNews(limit: 8);
  }

  Future<List<Product>> _loadSection(String type) async {
    final result = await _api.getProducts(type: type, limit: 10);
    return result['products'] as List<Product>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: const Color(0xFFF2F2F7),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Строка поиска ─────────────────────────────
            Container(
              color: AppColors.darkAccent,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () => showSearch(
                  context: context,
                  delegate: ProductSearchDelegate(),
                ),
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
                        child: Text('Поиск по каталогу...',
                            style: TextStyle(
                                color: AppColors.secondaryText, fontSize: 16)),
                      ),
                      Container(
                        width: 48,
                        height: 48,
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

            // ── Слайдер ───────────────────────────────────
            const SizedBox(height: 12),
            const BannerSlider(),

            // ── Категории ─────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text('Популярные категории',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainText)),
            ),
            _CategoriesRow(),

            const SizedBox(height: 8),

            // ── Акции ─────────────────────────────────────
            _SectionBlock(
              title: 'Акции',
              badge: 'АКЦИЯ',
              badgeColor: const Color(0xFFE53935),
              future: _saleFuture,
            ),

            // ── Новинки ───────────────────────────────────
            _SectionBlock(
              title: 'Новинки',
              badge: 'НОВИНКА',
              badgeColor: const Color(0xFFFF9800),
              future: _newFuture,
            ),

            // ── Хиты продаж ───────────────────────────────
            _SectionBlock(
              title: 'Хиты продаж',
              badge: 'ХИТ ПРОДАЖ',
              badgeColor: AppColors.primaryAccent,
              future: _hitFuture,
            ),

            // ── Новости и обзоры ──────────────────────────
            _NewsSection(future: _newsFuture),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Горизонтальная лента категорий ────────────────────────────────────────
class _CategoriesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(
                color: AppColors.primaryAccent));
          }
          if (provider.categories.isEmpty) return const SizedBox.shrink();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: provider.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final cat = provider.categories[index];
              return GestureDetector(
                onTap: () => MainScreen.of(context)?.switchToCatalog(category: cat),
                child: SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                              color: AppColors.primaryAccent, width: 2),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: cat.image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: cat.image,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.category,
                                          color: AppColors.secondaryText),
                                )
                              : const Icon(Icons.category,
                                  color: AppColors.secondaryText),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(cat.name,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mainText),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Секция (Акции / Новинки / Хиты продаж) — горизонтальный свайп ────────
class _SectionBlock extends StatefulWidget {
  final String title;
  final String badge;
  final Color badgeColor;
  final Future<List<Product>> future;

  const _SectionBlock({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.future,
  });

  @override
  State<_SectionBlock> createState() => _SectionBlockState();
}

class _SectionBlockState extends State<_SectionBlock> {
  int _currentPage = 0;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    _ctrl.addListener(() {
      final page = _ctrl.page?.round() ?? 0;
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryAccent)),
          );
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SizedBox.shrink();

        // Группируем по 2 карточки на одну «страницу»
        final pages = <List<Product>>[];
        for (int i = 0; i < products.length; i += 2) {
          pages.add(products.sublist(
              i, (i + 2) > products.length ? products.length : (i + 2)));
        }

        final screenW = MediaQuery.of(context).size.width;
        final cardH = (screenW / 2 - 22) / 0.6;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(widget.title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainText)),
            ),
            SizedBox(
              height: cardH,
              child: PageView.builder(
                controller: _ctrl,
                itemCount: pages.length,
                itemBuilder: (_, pageIndex) {
                  final pair = pages[pageIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ProductCard(
                              product: pair[0],
                              badge: widget.badge,
                              badgeColor: widget.badgeColor),
                        ),
                        const SizedBox(width: 10),
                        if (pair.length > 1)
                          Expanded(
                            child: _ProductCard(
                                product: pair[1],
                                badge: widget.badge,
                                badgeColor: widget.badgeColor),
                          )
                        else
                          const Expanded(child: SizedBox()),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Индикаторы страниц (активная точка двигается)
            if (pages.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pages.length, (i) {
                    final isActive = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: isActive
                            ? widget.badgeColor
                            : const Color(0xFFDDDDDD),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Карточка товара с бейджем ─────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final String badge;
  final Color badgeColor;

  const _ProductCard({
    required this.product,
    required this.badge,
    required this.badgeColor,
  });

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
            // Фото + бейдж
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: Container(
                      color: const Color(0xFFF8F8F8),
                      width: double.infinity,
                      height: double.infinity,
                      child: product.image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.image,
                              fit: BoxFit.contain,
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
                  // Бейдж
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Инфо
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
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<CartProvider>().addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Добавлено в корзину'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppColors.primaryAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkAccent,
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

// ─── Секция Новости и обзоры ───────────────────────────────────────────────
class _NewsSection extends StatelessWidget {
  final Future<List<NewsItem>> future;
  const _NewsSection({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
          );
        }
        final news = snapshot.data ?? [];
        if (news.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Новости и обзоры',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainText)),
                  TextButton(
                    onPressed: () async {
                      final uri = Uri.parse('https://replatinum.ru/news/');
                      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: const Text('Все статьи →',
                        style: TextStyle(color: AppColors.primaryAccent, fontSize: 13)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: news.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _NewsCard(item: news[i]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ─── Карточка новости ──────────────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('https://replatinum.ru${item.url}');
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: item.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.image,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Center(child: Icon(Icons.article_outlined, size: 48, color: Color(0xFFCCCCCC))),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Center(child: Icon(Icons.article_outlined, size: 48, color: Color(0xFFCCCCCC))),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Категория
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryAccent,
                          letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Заголовок
                  Text(item.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  // Читать
                  Text('Читать',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
