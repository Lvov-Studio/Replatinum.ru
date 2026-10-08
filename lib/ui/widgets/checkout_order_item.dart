import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../../providers/cart_provider.dart';

class CheckoutOrderItem extends StatelessWidget {
  const CheckoutOrderItem({super.key, required this.item, required this.total});
  final CartItem item;
  final num total;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
            image: true,
            label: 'Фото ${item.product.name}',
            child: SizedBox(
                width: 56,
                height: 64,
                child: item.image.isEmpty
                    ? const Icon(Icons.image_outlined,
                        color: AppColors.secondaryText)
                    : CachedNetworkImage(
                        imageUrl: item.image,
                        fit: BoxFit.contain,
                        placeholder: (_, url) => const Icon(
                            Icons.image_outlined,
                            color: AppColors.secondaryText),
                        errorWidget: (_, url, error) => const Icon(
                            Icons.image_outlined,
                            color: AppColors.secondaryText)))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              item.offer?.name.isNotEmpty == true
                  ? item.offer!.name
                  : item.product.name,
              style: const TextStyle(fontSize: 13, height: 1.35)),
          if (item.variantLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.variantLabel,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.secondaryText)),
          ],
          const SizedBox(height: 6),
          Text('${item.quantity} шт. · ${formatPrice(total)}',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ])),
      ]));
}
