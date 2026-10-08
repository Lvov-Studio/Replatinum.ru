import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/saved_products_provider.dart';
import '../../data/cart_recommendations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../widgets/empty_cart_view.dart';
import '../widgets/cart_price_summary.dart';
import 'checkout_bottom_sheet.dart';
import 'main_screen.dart';
import 'product_detail_screen.dart';
import 'success_screen.dart';
import '../../features/checkout/data/checkout_gateway.dart';

class CartScreen extends StatefulWidget {
  final CartRecommendations? recommendations;
  final CheckoutGateway Function()? checkoutGatewayFactory;
  const CartScreen(
      {super.key, this.recommendations, this.checkoutGatewayFactory});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final _recommendations = widget.recommendations ?? CartRecommendations();
  Future<void> _checkout() async {
    final orderId = await Navigator.of(context).push<int>(MaterialPageRoute(
        builder: (_) => CheckoutBottomSheet(
            gateway: widget.checkoutGatewayFactory?.call())));
    if (!mounted || orderId == null) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => SuccessScreen(orderId: orderId)));
    if (mounted) MainScreen.of(context)?.switchToTab(MainScreen.homeTab);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: const Text('Корзина',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            centerTitle: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.mainText,
            surfaceTintColor: AppColors.surface,
            scrolledUnderElevation: 0,
            shape: const Border(bottom: BorderSide(color: AppColors.border))),
        body: Consumer<CartProvider>(builder: (context, cart, _) {
          if (cart.items.isEmpty) return const EmptyCartView();
          return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                if (cart.storageError.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(cart.storageError,
                          style: const TextStyle(color: AppColors.error))),
                _CartPanel(
                    child: Row(children: [
                  Checkbox(
                      value: cart.allSelected,
                      onChanged: (value) => cart.selectAll(value == true),
                      activeColor: AppColors.primaryText),
                  const Expanded(
                      child:
                          Text('Выбрать все', style: TextStyle(fontSize: 13))),
                  TextButton(
                      onPressed: cart.clear,
                      child: const Text('Удалить все',
                          style: TextStyle(
                              color: AppColors.secondaryText, fontSize: 12))),
                ])),
                for (final item in cart.items.values) ...[
                  const SizedBox(height: 10),
                  _CartItemCard(
                      key: ValueKey(item.key),
                      item: item,
                      recommendations: _recommendations),
                ],
                const SizedBox(height: 12),
                _CartPanel(
                    child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Детали заказа',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 14),
                              CartPriceSummary(cart: cart),
                              const Divider(
                                  height: 24, color: AppColors.border),
                              _AmountRow(
                                  cart.quote == null
                                      ? 'Предварительно'
                                      : 'Итого',
                                  formatPrice(cart.totalAmount),
                                  total: true),
                              if (cart.selectedItems.isEmpty)
                                const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Text(
                                        'Выберите товары для оформления заказа.',
                                        style: TextStyle(
                                            color: AppColors.secondaryText))),
                              if (cart.checking)
                                const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: LinearProgressIndicator()),
                              if (cart.quoteError.isNotEmpty) ...[
                                Text(cart.quoteError,
                                    style: const TextStyle(
                                        color: AppColors.error)),
                                TextButton(
                                    onPressed: cart.refreshQuote,
                                    child: const Text('Повторить проверку')),
                              ],
                              const SizedBox(height: 14),
                              ElevatedButton(
                                  onPressed: cart.canCheckout ||
                                          cart.pendingCheckout != null
                                      ? _checkout
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.darkAccent,
                                      foregroundColor: Colors.white,
                                      disabledForegroundColor: Colors.white,
                                      minimumSize:
                                          const Size(double.infinity, 44),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                  child: Text(
                                      cart.pendingCheckout != null
                                          ? 'Проверить заказ'
                                          : 'Оформить заказ',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600))),
                            ]))),
              ]);
        }),
      );
}

class _CartPanel extends StatelessWidget {
  final Widget child;
  const _CartPanel({required this.child});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: child);
}

class _AmountRow extends StatelessWidget {
  final String label, amount;
  final bool total;
  const _AmountRow(this.label, this.amount, {this.total = false});
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: total ? 18 : 13,
                    fontWeight: total ? FontWeight.w700 : FontWeight.w400))),
        const SizedBox(width: 12),
        Text(amount,
            style: TextStyle(
                fontSize: total ? 22 : 14,
                fontWeight: FontWeight.w700,
                color: AppColors.mainText))
      ]);
}

class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final CartRecommendations recommendations;
  const _CartItemCard(
      {super.key, required this.item, required this.recommendations});
  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  bool _expanded = true;
  late Future<List<CartRecommendation>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.recommendations.forProduct(widget.item.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cart = context.watch<CartProvider>();
    final saved = context.watch<SavedProductsProvider>();
    final favorite = saved.favorites.containsKey(item.catalogId);
    final storePrice = item.offer?.storePrice ?? item.product.storePrice;
    final title = item.offer?.name.isNotEmpty == true
        ? item.offer!.name
        : item.product.name;
    return _CartPanel(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 32,
                    child: Checkbox(
                        value: cart.isSelected(item.key),
                        activeColor: AppColors.primaryText,
                        onChanged: (v) =>
                            cart.selectItem(item.key, v == true))),
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _CartImage(item.image,
                        size:
                            MediaQuery.sizeOf(context).width < 360 ? 52 : 68)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(formatPrice(cart.priceFor(item)),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            if (storePrice > cart.priceFor(item))
                              Text(formatPrice(storePrice),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.secondaryText,
                                      decoration: TextDecoration.lineThrough)),
                          ]),
                      const SizedBox(height: 5),
                      Text(title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, height: 1.3)),
                      if (item.variantLabel.isNotEmpty)
                        Text(item.variantLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.secondaryText)),
                      Row(children: [
                        IconButton(
                            tooltip: 'Удалить товар',
                            style: IconButton.styleFrom(
                                minimumSize: const Size(40, 44),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            constraints: const BoxConstraints.tightFor(
                                width: 40, height: 44),
                            padding: EdgeInsets.zero,
                            onPressed: () => cart.removeItem(item.key),
                            icon: const Icon(Icons.delete_outline, size: 21),
                            color: AppColors.secondaryText),
                        IconButton(
                            tooltip: 'В избранное',
                            style: IconButton.styleFrom(
                                minimumSize: const Size(40, 44),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            constraints: const BoxConstraints.tightFor(
                                width: 40, height: 44),
                            padding: EdgeInsets.zero,
                            onPressed: saved.ready
                                ? () => saved.toggle(SavedProduct(
                                    item.product,
                                    item.catalogId,
                                    item.offer?.specs ?? item.product.specs))
                                : null,
                            icon: Icon(
                                favorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 21),
                            color: favorite
                                ? AppColors.primaryText
                                : AppColors.secondaryText),
                        const Spacer(),
                        _QuantityButton(
                            Icons.remove,
                            item.quantity > 1
                                ? () => cart.decrementQuantity(item.key)
                                : null),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: Text('${item.quantity}')),
                        _QuantityButton(
                            Icons.add, () => cart.incrementQuantity(item.key)),
                      ]),
                    ])),
              ]),
              FutureBuilder<List<CartRecommendation>>(
                  future: _future,
                  builder: (context, snapshot) {
                    final recommendations = (snapshot.data ?? [])
                        .where((rec) => !cart.items.values
                            .any((entry) => entry.catalogId == rec.catalogId))
                        .toList();
                    final available = recommendations.isNotEmpty ||
                        snapshot.hasError ||
                        snapshot.connectionState != ConnectionState.done;
                    return Column(children: [
                      Row(children: [
                        if (available)
                          Expanded(
                              child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                      backgroundColor: AppColors.background,
                                      foregroundColor: AppColors.mainText,
                                      minimumSize: const Size(0, 36)),
                                  onPressed: () =>
                                      setState(() => _expanded = !_expanded),
                                  label: const Text('Рекомендуем',
                                      style: TextStyle(fontSize: 12)),
                                  icon: Icon(
                                      _expanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      size: 18))),
                        if (available) const SizedBox(width: 8),
                        const Expanded(
                            child: TextButton(
                                onPressed: null,
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                          child: Text('Защита устройств',
                                              style: TextStyle(fontSize: 12))),
                                      Icon(Icons.chevron_right, size: 18),
                                    ]))),
                      ]),
                      if (_expanded && available) ...[
                        if (snapshot.connectionState != ConnectionState.done)
                          const Padding(
                              padding: EdgeInsets.all(12),
                              child: LinearProgressIndicator()),
                        if (snapshot.hasError)
                          TextButton(
                              onPressed: () {
                                setState(() {
                                  widget.recommendations.retry(item.product.id);
                                  _future = widget.recommendations
                                      .forProduct(item.product.id);
                                });
                              },
                              child: const Text(
                                  'Повторить загрузку рекомендаций')),
                        if (recommendations.isNotEmpty)
                          SizedBox(
                              height: 78,
                              child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: recommendations.length,
                                  separatorBuilder: (_, index) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) =>
                                      _RecommendationTile(
                                          recommendations[index]))),
                      ],
                    ]);
                  }),
            ])));
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _QuantityButton(this.icon, this.onPressed);
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 30,
      height: 44,
      child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)))));
}

class _CartImage extends StatelessWidget {
  final String url;
  final double size;
  const _CartImage(this.url, {this.size = 48});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: url.isEmpty
          ? const Icon(Icons.image_outlined, color: AppColors.secondaryText)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              errorWidget: (_, url, error) =>
                  const Icon(Icons.image_outlined)));
}

class _RecommendationTile extends StatelessWidget {
  final CartRecommendation recommendation;
  const _RecommendationTile(this.recommendation);
  @override
  Widget build(BuildContext context) {
    final product = recommendation.product;
    return SizedBox(
        width: 270,
        child: _CartPanel(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children: [
                  _CartImage(product.image),
                  const SizedBox(width: 8),
                  Expanded(
                      child: InkWell(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => ProductDetailScreen(
                                      productPreview: product,
                                      initialOfferId: product.offerId))),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                    product.price > 0
                                        ? formatPrice(product.price)
                                        : 'По запросу',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ]))),
                  IconButton(
                      tooltip: 'Добавить в корзину',
                      onPressed: recommendation.canBuy
                          ? () => context
                              .read<CartProvider>()
                              .addItem(product, offer: recommendation.offer)
                          : null,
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.darkAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.background),
                      icon: const Icon(Icons.add, size: 20)),
                ]))));
  }
}
