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

// ─── Карточка товара с бейджем ─────────────────────────────────────────────
class ProductPreviewCard extends StatelessWidget {
  const ProductPreviewCard({
    super.key,
    required this.product,
    this.badge = '',
    this.badgeColor = AppColors.primaryAccent,
    required this.imageHeight,
    this.showStorePrice = false,
    this.catalogLayout = false,
  });

  final Product product;
  final bool showStorePrice;
  final bool catalogLayout;
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
      key: ValueKey(
          '${catalogLayout ? 'catalog' : 'home'}-product-${product.offerId ?? product.id}'),
      color: catalogLayout ? AppColors.background : Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                height: imageHeight,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    SizedBox(
                        height: catalogLayout ? 48 : 40,
                        child: Row(children: [
                          const Spacer(),
                          _savedActions(context),
                        ])),
                    Expanded(
                        child: Stack(fit: StackFit.expand, children: [
                      Padding(
                          key: ValueKey(
                              'preview-image-${product.offerId ?? product.id}'),
                          padding: EdgeInsets.fromLTRB(
                              10, 0, product.ruStoreWarning ? 30 : 10, 10),
                          child: product.image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.image,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.topCenter,
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.image_outlined,
                                      color: AppColors.secondaryText))
                              : const Icon(Icons.image_outlined,
                                  color: AppColors.secondaryText)),
                      if (product.ruStoreWarning)
                        Positioned(
                            bottom: 0, right: 0, child: _ruStore(context)),
                      if (badge.isNotEmpty)
                        Positioned(
                            top: 4,
                            left: 6,
                            child: DecoratedBox(
                                decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(4)),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    child: Text(badge,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800))))),
                    ])),
                  ]),
                )),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (catalogLayout) ...[
                    _price(context),
                    const SizedBox(height: 5),
                    _title(context),
                    const SizedBox(height: 3),
                  ] else ...[
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
                  ],
                  if (showStorePrice) ...[
                    const SizedBox(height: 3),
                    SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(11) * 1.2,
                      child: product.storePrice > 0
                          ? Text(
                              'В магазине: ${formatPrice(product.storePrice)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                  color: AppColors.mainText))
                          : null,
                    ),
                  ],
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ElevatedButton(
                        onPressed: () {
                          if (canBuy) {
                            context.read<CartProvider>().addItem(product);
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(const SnackBar(
                                  persist: false,
                                  duration: Duration(seconds: 2),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _price(BuildContext context) =>
      Text(product.price > 0 ? formatPrice(product.price) : 'По запросу',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.mainText));
  Widget _title(BuildContext context) => SizedBox(
      height: MediaQuery.textScalerOf(context).scale(12) * 1.25 * 3,
      child: Text(product.name,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 12, height: 1.25, color: AppColors.mainText)));
  Widget _ruStore(BuildContext context) => IconButton(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.all(6),
      tooltip: 'Без RuStore',
      onPressed: () => showProductInformation(
          context,
          'Без RuStore',
          const Text(
              'В товаре имеется недостаток: RuStore недоступен на устройствах Apple')),
      icon: const DecoratedBox(
          decoration: BoxDecoration(
              color: Color(0xFF007AC1),
              borderRadius: BorderRadius.all(Radius.circular(4))),
          child: Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.app_blocking_outlined,
                  size: 17, color: Colors.white))));
  Widget _savedActions(BuildContext context) =>
      Consumer<SavedProductsProvider>(builder: (context, saved, _) {
        final id = product.offerId ?? product.id;
        final item = SavedProduct(product, id, product.specs);
        return Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              alignment: Alignment.center,
              padding: catalogLayout
                  ? const EdgeInsets.all(8)
                  : const EdgeInsets.fromLTRB(8, 8, 8, 6),
              tooltip: saved.favorites.containsKey(id)
                  ? 'Убрать из избранного'
                  : 'В избранное',
              onPressed: saved.ready ? () => saved.toggle(item) : null,
              icon: Icon(
                  saved.favorites.containsKey(id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 21,
                  color: saved.favorites.containsKey(id)
                      ? Colors.red
                      : AppColors.secondaryText)),
        ]);
      });
}
