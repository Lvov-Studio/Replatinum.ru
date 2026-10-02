import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../../data/models/product_model.dart';
import '../../data/api/api_service.dart';
import '../../providers/product_provider.dart';
import '../../providers/saved_products_provider.dart';
import '../screens/product_detail_screen.dart';
import 'catalog_products_view.dart';
import 'product_purchase_sheets.dart';
import 'product_badge.dart';

class HomeShowcaseCarousel extends StatelessWidget {
  const HomeShowcaseCarousel(
      {super.key,
      required this.title,
      required this.type,
      required this.badge,
      required this.future,
      required this.onRetry,
      this.apiService});
  final String title;
  final String type;
  final String badge;
  final Future<List<Product>> future;
  final VoidCallback onRetry;
  final ApiService? apiService;

  void _openAll(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
              create: (_) => ProductProvider(apiService: apiService)
                ..fetchProducts(type: type),
              child: Consumer<ProductProvider>(
                  builder: (context, provider, _) => Scaffold(
                      backgroundColor: AppColors.background,
                      body: CatalogProductsView(
                          provider: provider,
                          onBack: () => Navigator.of(context).pop()))),
            )));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Product>>(
      future: future,
      builder: (context, snapshot) {
        if (type == 'sale' &&
            snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError &&
            (snapshot.data ?? []).isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 4),
                child: Row(children: [
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainText))),
                  SizedBox(
                      width: 126,
                      child: TextButton(
                          onPressed: () => _openAll(context),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.mainText,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6)),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                    child: Text('Посмотреть все',
                                        maxLines: 2,
                                        style: TextStyle(fontSize: 11))),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 16),
                              ]))),
                ])),
            Builder(builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(children: [
                      const Expanded(child: Text('Товары не загрузились')),
                      TextButton(
                          onPressed: onRetry, child: const Text('Повторить'))
                    ]));
              }
              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.fromLTRB(10, 4, 10, 12),
                    child: Text('Пока нет товаров'));
              }
              final width =
                  (MediaQuery.sizeOf(context).width * .41).clamp(130.0, 190.0);
              final scale = MediaQuery.textScalerOf(context).scale(1);
              return SizedBox(
                  height: width + 68 + (scale - 1).clamp(0, 3) * 64,
                  child: ListView.separated(
                    key: PageStorageKey('home-showcase-$type'),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) => SizedBox(
                        width: width,
                        child: _ShowcaseCard(
                            product: products[index],
                            badge: badge,
                            imageHeight: width)),
                  ));
            }),
          ],
        );
      });
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard(
      {required this.product, required this.badge, required this.imageHeight});
  final Product product;
  final String badge;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final id = product.offerId ?? product.id;
    final saved = context.watch<SavedProductsProvider>();
    return Material(
        color: Colors.transparent,
        child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ProductDetailScreen(
                    productPreview: product, initialOfferId: product.offerId))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  height: imageHeight,
                  child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(children: [
                        Positioned.fill(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 32, 10, 12),
                                child: product.image.isEmpty
                                    ? const Icon(Icons.image_outlined,
                                        color: AppColors.secondaryText)
                                    : CachedNetworkImage(
                                        imageUrl: product.image,
                                        fit: BoxFit.contain,
                                        errorWidget: (_, __, ___) =>
                                            const Icon(Icons.image_outlined)))),
                        Positioned(top: 8, left: 8, child: ProductBadge(badge)),
                        Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                                tooltip: saved.favorites.containsKey(id)
                                    ? 'Убрать из избранного'
                                    : 'В избранное',
                                onPressed: saved.ready
                                    ? () => saved.toggle(SavedProduct(
                                        product, id, product.specs))
                                    : null,
                                icon: Icon(
                                    saved.favorites.containsKey(id)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 20,
                                    color: saved.favorites.containsKey(id)
                                        ? Colors.red
                                        : AppColors.secondaryText))),
                        if (product.ruStoreWarning)
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                  tooltip: 'Без RuStore',
                                  onPressed: () => showProductInformation(
                                      context,
                                      'Без RuStore',
                                      const Text(
                                          'В товаре имеется недостаток: RuStore недоступен на устройствах Apple')),
                                  alignment: Alignment.bottomRight,
                                  padding: const EdgeInsets.all(6),
                                  icon: Image.asset(
                                      'assets/icons/no-rustore.png',
                                      width: 24,
                                      height: 24))),
                      ]))),
              const SizedBox(height: 8),
              SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(12) * 1.25 * 2,
                  child: Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          height: 1.25,
                          color: AppColors.mainText))),
              const SizedBox(height: 5),
              Text(product.price > 0 ? formatPrice(product.price) : '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainText)),
            ])));
  }
}
