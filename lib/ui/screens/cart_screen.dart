import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../widgets/custom_app_bar.dart';
import 'checkout_bottom_sheet.dart';
import 'main_screen.dart';
import 'success_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context) async {
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckoutBottomSheet(),
    );
    if (!context.mounted || completed != true) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SuccessScreen()),
    );
    if (!context.mounted) return;
    MainScreen.of(context)?.switchToTab(MainScreen.homeTab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppColors.secondaryText.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ваша корзина пуста',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                  ),
                ],
              ),
            );
          }

          final cartItems = cart.items.values.toList();

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AppColors.border),
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    final product = cartItem.product;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Картинка товара
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.white,
                              border: Border.all(color: AppColors.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: cartItem.image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: cartItem.image,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.image_not_supported,
                                            color: AppColors.secondaryText),
                                  )
                                : const Icon(Icons.image,
                                    color: AppColors.secondaryText),
                          ),
                          const SizedBox(width: 12),

                          // Название и цена
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (cartItem.variantLabel.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    cartItem.variantLabel,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatPrice(cart.priceFor(cartItem)),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.primaryText,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Уменьшить количество',
                                      onPressed: () => cart.decrementQuantity(
                                        cartItem.key,
                                      ),
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      color: AppColors.secondaryText,
                                    ),
                                    Text(
                                      '${cartItem.quantity}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Увеличить количество',
                                      onPressed: () => cart.incrementQuantity(
                                        cartItem.key,
                                      ),
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      color: AppColors.primaryText,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Итоговая сумма и кнопка
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      if (cart.discountAmount > 0) ...[
                        Text(cart.quote!.promotionName,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Товары'),
                            Text(formatPrice(cart.subtotal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Скидка за количество'),
                            Text('− ${formatPrice(cart.discountAmount)}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (cart.quote?.hint.isNotEmpty == true) ...[
                        Text(cart.quote!.hint),
                        const SizedBox(height: 12),
                      ],
                      if (cart.checking) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text('Проверяем цену и скидку…'),
                        const SizedBox(height: 12),
                      ],
                      if (cart.quoteError.isNotEmpty) ...[
                        Text(cart.quoteError,
                            style: const TextStyle(color: AppColors.error)),
                        TextButton(
                          onPressed: cart.refreshQuote,
                          child: const Text('Повторить проверку'),
                        ),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cart.quote == null ? 'Предварительно:' : 'Итого:',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            formatPrice(cart.totalAmount),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            cart.canCheckout ? () => _checkout(context) : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text(
                          'Оформить заказ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
