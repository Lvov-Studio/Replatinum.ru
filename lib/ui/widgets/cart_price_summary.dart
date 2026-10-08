import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../../providers/cart_provider.dart';

/// The website's price hierarchy, using the app's typography and spacing.
class CartPriceSummary extends StatelessWidget {
  const CartPriceSummary({super.key, required this.cart});
  final CartProvider cart;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text('Товары (${cart.selectedCount} шт.)'),
              Wrap(spacing: 8, runSpacing: 4, children: [
                if (cart.displayDiscount > 0)
                  Text(formatPrice(cart.displaySubtotal),
                      style: const TextStyle(
                          color: AppColors.secondaryText,
                          decoration: TextDecoration.lineThrough)),
                Text(formatPrice(cart.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ],
          ),
          if (cart.displayDiscount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [
                    Color(0xFF1C1C1E),
                    Color(0xFF7F1D1D),
                  ])),
              child: Column(children: [
                Row(children: [
                  const Expanded(
                      child: Text('Скидка',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600))),
                  Flexible(
                      child: Text('− ${formatPrice(cart.displayDiscount)}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 10),
                Container(height: 2, color: Colors.white24),
              ]),
            ),
          ],
          if (cart.quote?.hint.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(cart.quote!.hint,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.secondaryText)),
          ],
        ],
      );
}
