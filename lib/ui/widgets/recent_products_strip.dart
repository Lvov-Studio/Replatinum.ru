import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'product_thumbnail.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../../providers/recent_products_provider.dart';
import '../screens/product_detail_screen.dart';

class RecentProductsStrip extends StatelessWidget {
  const RecentProductsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<RecentProductsProvider?>();
    final products = history?.products ?? [];
    if (products.isEmpty) return const SizedBox.shrink();
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(10, 28, 10, 12),
        child: Text('Вы смотрели',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.mainText)),
      ),
      SizedBox(
        height: 92 + (scale - 1).clamp(0, 3) * 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final product = products[index];
            return SizedBox(
              width: (MediaQuery.sizeOf(context).width * .78).clamp(260, 360),
              child: Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => ProductDetailScreen(
                              productPreview: product,
                              initialOfferId: product.offerId))),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      SizedBox(
                          width: 48,
                          height: 60,
                          child: product.image.isEmpty
                              ? const Icon(Icons.image_outlined,
                                  color: AppColors.secondaryText)
                              : ProductThumbnail(url: product.image)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Text(
                                product.price > 0
                                    ? formatPrice(product.price)
                                    : 'По запросу',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText)),
                            const SizedBox(height: 4),
                            Text(product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(fontSize: 13, height: 1.2)),
                          ])),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
