import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/product_model.dart';
import 'product_preview_card.dart';

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
        final imageHeight = (cardWidth < 190 ? cardWidth * 0.85 : 170.0) + 40;
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
                            child: ProductPreviewCard(
                                product: pair[0],
                                badge: widget.badge,
                                badgeColor: widget.badgeColor,
                                imageHeight: imageHeight),
                          )
                        else ...[
                          Expanded(
                            child: ProductPreviewCard(
                                product: pair[0],
                                badge: widget.badge,
                                badgeColor: widget.badgeColor,
                                imageHeight: imageHeight),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ProductPreviewCard(
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
