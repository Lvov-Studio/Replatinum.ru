import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/category_provider.dart';
import '../../providers/cart_provider.dart';
import '../../data/api/api_service.dart';
import '../../data/models/product_model.dart';
import '../../data/models/news_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
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
  int _bannerVersion = 0;
  bool _showHeader = true;

  bool _handleScroll(UserScrollNotification notification) {
    final showHeader = switch (notification.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle => _showHeader,
    };
    if (showHeader != _showHeader) {
      setState(() => _showHeader = showHeader);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryProvider>().fetchCategories();
    });
    _saleFuture = _loadSection('sale');
    _newFuture = _loadSection('new');
    _hitFuture = _loadSection('hit');
    _newsFuture = _api.getNews(limit: 8);
  }

  Future<List<Product>> _loadSection(String type) async {
    final result = await _api.getProducts(type: type, limit: 10);
    return result['products'] as List<Product>;
  }

  Future<void> _ignoreFailure(Future<dynamic> future) async {
    try {
      await future;
    } catch (_) {
      // The section renders its own retry state.
    }
  }

  Future<void> _refresh() async {
    final categories =
        context.read<CategoryProvider>().fetchCategories(force: true);
    setState(() {
      _bannerVersion++;
      _saleFuture = _loadSection('sale');
      _newFuture = _loadSection('new');
      _hitFuture = _loadSection('hit');
      _newsFuture = _api.getNews(limit: 8);
    });
    await Future.wait([
      categories,
      _ignoreFailure(_saleFuture),
      _ignoreFailure(_newFuture),
      _ignoreFailure(_hitFuture),
      _ignoreFailure(_newsFuture),
    ]);
  }

  void _retryProducts(String type) {
    setState(() {
      switch (type) {
        case 'sale':
          _saleFuture = _loadSection(type);
          break;
        case 'new':
          _newFuture = _loadSection(type);
          break;
        case 'hit':
          _hitFuture = _loadSection(type);
          break;
      }
    });
  }

  void _retryNews() {
    setState(() => _newsFuture = _api.getNews(limit: 8));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(collapsed: !_showHeader),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: _handleScroll,
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Слайдер ───────────────────────────────────
                      const SizedBox(height: 12),
                      BannerSlider(key: ValueKey(_bannerVersion)),

                      // ── Категории ─────────────────────────────────
                      const Padding(
                        padding: EdgeInsets.fromLTRB(10, 20, 10, 12),
                        child: Text('Популярные категории',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mainText)),
                      ),
                      const _CategoriesRow(),

                      const SizedBox(height: 2),

                      // ── Акции ─────────────────────────────────────
                      _SectionBlock(
                        title: 'Акции',
                        badge: 'АКЦИЯ',
                        badgeColor: const Color(0xFFE53935),
                        future: _saleFuture,
                        onRetry: () => _retryProducts('sale'),
                      ),

                      // ── Новинки ───────────────────────────────────
                      _SectionBlock(
                        title: 'Новинки',
                        badge: 'НОВИНКА',
                        badgeColor: const Color(0xFFFF9800),
                        future: _newFuture,
                        onRetry: () => _retryProducts('new'),
                      ),

                      // ── Хиты продаж ───────────────────────────────
                      _SectionBlock(
                        title: 'Хиты продаж',
                        badge: 'ХИТ ПРОДАЖ',
                        badgeColor: AppColors.primaryAccent,
                        future: _hitFuture,
                        onRetry: () => _retryProducts('hit'),
                      ),

                      // ── Новости и обзоры ──────────────────────────
                      _NewsSection(future: _newsFuture, onRetry: _retryNews),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: GestureDetector(
        onTap: () => showSearch(
          context: context,
          delegate: ProductSearchDelegate(),
        ),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F7),
            border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Поиск товаров...',
                    style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
              ),
              Container(
                width: 42,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Горизонтальная лента категорий ────────────────────────────────────────
class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryAccent));
          }
          if (provider.categories.isEmpty) {
            return _HomeLoadMessage(
              message: 'Категории не загрузились',
              onRetry: () => provider.fetchCategories(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            itemCount: provider.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final cat = provider.categories[index];
              return InkWell(
                onTap: () =>
                    MainScreen.of(context)?.switchToCatalog(category: cat),
                child: SizedBox(
                  width: 84,
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primaryAccent, width: 1.5),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: ClipOval(
                          child: cat.image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: cat.image,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.category,
                                      color: AppColors.secondaryText),
                                )
                              : const Icon(Icons.category,
                                  color: AppColors.secondaryText),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(cat.name,
                          style: const TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mainText),
                          textAlign: TextAlign.center,
                          maxLines: 3,
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _HomeLoadMessage extends StatelessWidget {
  const _HomeLoadMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
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
  final VoidCallback onRetry;

  const _SectionBlock({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.future,
    required this.onRetry,
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
  void didUpdateWidget(covariant _SectionBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.future, widget.future)) {
      _currentPage = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _ctrl.hasClients) _ctrl.jumpToPage(0);
      });
    }
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(widget.title),
              const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(widget.title),
              _HomeLoadMessage(
                message: 'Товары не загрузились',
                onRetry: widget.onRetry,
              ),
            ],
          );
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(widget.title),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text('Пока нет товаров'),
              ),
            ],
          );
        }

        // Группируем по 2 карточки на одну «страницу»
        final pages = <List<Product>>[];
        for (int i = 0; i < products.length; i += 2) {
          pages.add(products.sublist(
              i, (i + 2) > products.length ? products.length : (i + 2)));
        }

        final screenW = MediaQuery.of(context).size.width;
        final cardWidth = (screenW - 30) / 2;
        final imageHeight = cardWidth < 190 ? cardWidth * 0.85 : 170.0;
        final cardH = imageHeight + 154;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(widget.title),
            SizedBox(
              height: cardH,
              child: PageView.builder(
                controller: _ctrl,
                itemCount: pages.length,
                itemBuilder: (_, pageIndex) {
                  final pair = pages[pageIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (pair.length == 1)
                          SizedBox(
                            width: cardWidth,
                            child: _ProductCard(
                                product: pair[0],
                                badge: widget.badge,
                                badgeColor: widget.badgeColor,
                                imageHeight: imageHeight),
                          )
                        else ...[
                          Expanded(
                            child: _ProductCard(
                                product: pair[0],
                                badge: widget.badge,
                                badgeColor: widget.badgeColor,
                                imageHeight: imageHeight),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ProductCard(
                                product: pair[1],
                                badge: widget.badge,
                                badgeColor: widget.badgeColor,
                                imageHeight: imageHeight),
                          ),
                        ],
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
  final double imageHeight;

  const _ProductCard({
    required this.product,
    required this.badge,
    required this.badgeColor,
    required this.imageHeight,
  });

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
            SizedBox(
              height: imageHeight,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
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
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
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
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Инфо
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: AppColors.mainText),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.price > 0
                          ? formatPrice(product.price)
                          : 'По запросу',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<CartProvider>().addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Добавлено в корзину'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppColors.darkAccent,
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
                              borderRadius: BorderRadius.circular(7)),
                        ),
                        child: const Text('В корзину',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
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
  final VoidCallback onRetry;
  const _NewsSection({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading('Новости и обзоры'),
              SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator())),
            ],
          );
        }
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeading('Новости и обзоры'),
              _HomeLoadMessage(
                message: 'Новости не загрузились',
                onRetry: onRetry,
              ),
            ],
          );
        }
        final news = snapshot.data ?? [];
        if (news.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 4),
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
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text('Все статьи →',
                        style: TextStyle(
                            color: AppColors.primaryAccent, fontSize: 13)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.sizeOf(context).width * 0.72 / 2.1 + 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: news.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
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
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Широкое превью, как в мобильной ленте сайта.
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 2.1,
                child: item.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.image,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerLeft,
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Center(
                              child: Icon(Icons.article_outlined,
                                  size: 48, color: Color(0xFFCCCCCC))),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Center(
                            child: Icon(Icons.article_outlined,
                                size: 48, color: Color(0xFFCCCCCC))),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Категория
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
                    const SizedBox(height: 4),
                    // Заголовок
                    Text(item.title,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.25),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    // Читать
                    Text('Читать',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryAccent)),
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
