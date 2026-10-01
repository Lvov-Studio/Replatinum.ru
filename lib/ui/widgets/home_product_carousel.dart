import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/saved_products_provider.dart';
import '../screens/product_detail_screen.dart';
import 'product_purchase_sheets.dart';

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

class HomeProductCarousel extends StatefulWidget {
  final String title;
  final String badge;
  final Color badgeColor;
  final Future<List<Product>> future;
  final VoidCallback onRetry;

  const HomeProductCarousel({
    super.key,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.future,
    required this.onRetry,
  });

  @override
  State<HomeProductCarousel> createState() => _HomeProductCarouselState();
}

class _HomeProductCarouselState extends State<HomeProductCarousel> {
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
  void didUpdateWidget(covariant HomeProductCarousel oldWidget) {
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
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final cardH = imageHeight + 126 + (scale - 1).clamp(0, 3) * 55;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _SectionHeading(widget.title)),
              Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text('${products.length} товаров',
                      style: const TextStyle(
                          color: AppColors.secondaryText, fontSize: 12)))
            ]),
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
                      mainAxisAlignment: MainAxisAlignment.start,
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
  const _ProductCard({
    required this.product,
    required this.badge,
    required this.badgeColor,
    required this.imageHeight,
  });

  final Product product;
  final String badge;
  final Color badgeColor;
  final double imageHeight;

  void _open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ProductDetailScreen(productPreview: product)));

  @override
  Widget build(BuildContext context) {
    final canBuy = product.price > 0 && product.canBuy != false;
    return Material(
      key: ValueKey('home-product-${product.offerId ?? product.id}'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: const Color(0xFFF8F8F8),
                    child: product.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: AppColors.secondaryText))
                        : const Icon(Icons.image_outlined,
                            size: 48, color: AppColors.secondaryText),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        child: Text(badge,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  if (product.ruStoreWarning)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: IconButton(
                        tooltip: 'Без RuStore',
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: () => showProductInformation(
                            context,
                            'Без RuStore',
                            const Text(
                                'В товаре имеется недостаток: RuStore недоступен на устройствах Apple')),
                        icon: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF007AC1),
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.app_blocking_outlined,
                                size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Consumer<SavedProductsProvider>(
                        builder: (context, saved, _) {
                      final id = product.offerId ?? product.id;
                      final item = SavedProduct(product, id, product.specs);
                      return Material(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            tooltip: saved.favorites.containsKey(id)
                                ? 'Убрать из избранного'
                                : 'В избранное',
                            onPressed:
                                saved.ready ? () => saved.toggle(item) : null,
                            constraints: const BoxConstraints(
                                minWidth: 48, minHeight: 48),
                            iconSize: 21,
                            icon: Icon(
                                saved.favorites.containsKey(id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: saved.favorites.containsKey(id)
                                    ? Colors.red
                                    : AppColors.darkAccent),
                          ),
                          IconButton(
                            tooltip: 'Сравнение товаров',
                            onPressed: saved.ready
                                ? () => saved.toggle(item, compare: true)
                                : null,
                            constraints: const BoxConstraints(
                                minWidth: 48, minHeight: 48),
                            iconSize: 21,
                            icon: Icon(Icons.bar_chart,
                                color: saved.comparison.containsKey(id)
                                    ? AppColors.primaryText
                                    : AppColors.darkAccent),
                          ),
                        ]),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height:
                        MediaQuery.textScalerOf(context).scale(12) * 1.25 * 2,
                    child: Text(product.name,
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: AppColors.mainText),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 6),
                  Text(
                      product.price > 0
                          ? formatPrice(product.price)
                          : 'По запросу',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.2)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (canBuy) {
                          context.read<CartProvider>().addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Товар добавлен в корзину')));
                        } else {
                          _open(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7)),
                      ),
                      child: Text(canBuy ? 'В корзину' : 'Под заказ',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
