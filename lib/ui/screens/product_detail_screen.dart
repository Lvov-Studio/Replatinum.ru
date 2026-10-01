import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/product_model.dart';
import '../../data/api/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_detail_controller.dart';
import '../../providers/saved_products_provider.dart';
import '../../providers/recent_products_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../widgets/product_purchase_sheets.dart';
import '../widgets/product_description.dart';
import 'main_screen.dart';
import 'saved_products_screen.dart';
import 'info_screens.dart';
import 'service_tradein_screens.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product productPreview;
  final String? initialOfferId;
  final ApiService? apiService;
  const ProductDetailScreen(
      {super.key,
      required this.productPreview,
      this.initialOfferId,
      this.apiService});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductDetailController _controller;
  final _gallery = PageController();
  int _image = 0;
  bool _showSpecs = false;
  @override
  void initState() {
    super.initState();
    _controller =
        ProductDetailController(widget.productPreview, api: widget.apiService)
          ..load().then((_) {
            if (!mounted) return;
            for (final offer in _controller.detail?.offers ?? []) {
              if (offer.id ==
                  (widget.initialOfferId ?? widget.productPreview.offerId)) {
                _controller.selectedOffer = offer;
              }
            }
            _recordView();
            setState(() {});
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    _gallery.dispose();
    super.dispose();
  }

  void _openCart() {
    final main = MainScreen.of(context);
    Navigator.of(context).pop();
    main?.switchToTab(MainScreen.cartTab);
  }

  Future<void> _purchase() async {
    if (_controller.action != PurchaseAction.cart) {
      await showProductInformation(
          context,
          _controller.actionLabel,
          ProductInquiryForm(
              productId: _controller.id, productName: _controller.name));
      return;
    }
    context
        .read<CartProvider>()
        .addItem(_controller.cartProduct, offer: _controller.selectedOffer);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Добавлено в корзину'),
        action: SnackBarAction(label: 'Открыть', onPressed: _openCart)));
  }

  void _select(String code, String value) {
    _controller.select(code, value);
    _recordView();
    setState(() {
      _image = 0;
    });
    if (_gallery.hasClients) _gallery.jumpToPage(0);
  }

  void _recordView() {
    final c = _controller;
    if (c.detail == null || c.error != null) return;
    context.read<RecentProductsProvider?>()?.record(Product(
          id: c.detail!.id,
          offerId: c.selectedOffer?.id,
          name: c.name,
          price: c.price,
          storePrice: c.storePrice,
          canBuy: c.canBuy,
          image:
              c.images.isEmpty ? widget.productPreview.image : c.images.first,
          ruStoreWarning: c.detail!.ruStoreWarning,
        ));
  }

  Future<void> _zoom() async {
    final images = _controller.images;
    final page = PageController(initialPage: _image);
    await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
            builder: (_) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    title: const Text('Фото товара')),
                body: PageView(controller: page, children: [
                  for (final url in images)
                    InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                            child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => const Icon(
                                    Icons.image_outlined,
                                    color: Colors.white,
                                    size: 64))))
                ]))));
    page.dispose();
  }

  Widget _photo(String url) => CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) => const Icon(Icons.image_outlined,
          size: 48, color: AppColors.secondaryText));
  Widget _section(List<Widget> children) => Material(
      color: Colors.white,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children)));
  void _navigate(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        final loaded = !c.loading && c.error == null && c.detail != null;
        return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
                toolbarHeight: 48,
                leading: IconButton(
                    tooltip: 'Назад',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back)),
                actions: loaded ? _headerActions() : null,
                surfaceTintColor: Colors.white,
                scrolledUnderElevation: 0,
                shape:
                    const Border(bottom: BorderSide(color: AppColors.border)),
                backgroundColor: Colors.white,
                systemOverlayStyle: SystemUiOverlayStyle.dark),
            body: c.loading
                ? const Center(child: CircularProgressIndicator())
                : c.error != null
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.wifi_off_outlined, size: 48),
                        const SizedBox(height: 12),
                        Text(c.error!),
                        TextButton(
                            onPressed: c.load, child: const Text('Повторить'))
                      ]))
                    : _content(),
            bottomNavigationBar: loaded
                ? ColoredBox(
                    color: Colors.white,
                    child: SafeArea(
                        top: false,
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child:
                                LayoutBuilder(builder: (context, constraints) {
                              final price = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                        c.price > 0
                                            ? formatPrice(c.price)
                                            : 'Цена по запросу',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800)),
                                    if (c.storePrice > c.price && c.price > 0)
                                      Text(formatPrice(c.storePrice),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.secondaryText,
                                              decoration:
                                                  TextDecoration.lineThrough))
                                  ]);
                              final button = FilledButton(
                                  onPressed: _purchase,
                                  style: FilledButton.styleFrom(
                                      foregroundColor: AppColors.onPrimary,
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10))),
                                  child: Text(c.actionLabel));
                              if (constraints.maxWidth < 280 ||
                                  MediaQuery.textScalerOf(context).scale(1) >
                                      1.3) {
                                return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      price,
                                      const SizedBox(height: 8),
                                      button
                                    ]);
                              }
                              return Row(children: [
                                Expanded(child: price),
                                const SizedBox(width: 12),
                                Expanded(child: button)
                              ]);
                            }))))
                : null);
      });
  List<Widget> _headerActions() {
    final c = _controller;
    return [
      Consumer<SavedProductsProvider>(
          builder: (context, saved, _) => Row(children: [
                IconButton(
                    tooltip: saved.comparison.containsKey(c.id)
                        ? 'Убрать из сравнения'
                        : 'Сравнить',
                    onPressed: saved.ready
                        ? () => saved.toggle(
                            SavedProduct(c.cartProduct, c.id, c.specs),
                            compare: true)
                        : null,
                    icon: Icon(Icons.bar_chart,
                        color: saved.comparison.containsKey(c.id)
                            ? AppColors.primaryText
                            : AppColors.darkAccent)),
                IconButton(
                    tooltip: saved.favorites.containsKey(c.id)
                        ? 'Убрать из избранного'
                        : 'В избранное',
                    onPressed: saved.ready
                        ? () => saved
                            .toggle(SavedProduct(c.cartProduct, c.id, c.specs))
                        : null,
                    icon: Icon(
                        saved.favorites.containsKey(c.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: saved.favorites.containsKey(c.id)
                            ? AppColors.primaryText
                            : AppColors.darkAccent)),
              ])),
      Consumer<CartProvider>(
          builder: (context, cart, _) => IconButton(
              tooltip: 'Корзина',
              onPressed: _openCart,
              icon: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  label: Text('${cart.itemCount}'),
                  child: const Icon(Icons.shopping_bag_outlined)))),
      const SizedBox(width: 4),
    ];
  }

  Widget _panel(List<Widget> children) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border)),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children))));

  Widget _variantSelectors() {
    final c = _controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final group in c.variantGroups.entries) ...[
        const SizedBox(height: 12),
        Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: '${group.value.first.name}: ',
                  style: const TextStyle(color: AppColors.secondaryText)),
              TextSpan(
                  text: c.label(group.value.firstWhere(
                      (p) => p.value == c.selectedOffer?.valueOf(group.key),
                      orElse: () => group.value.first)),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            style: const TextStyle(fontSize: 14, height: 1.3)),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final property in group.value)
            if (group.key == 'COLOR')
              Semantics(
                  button: true,
                  selected:
                      property.value == c.selectedOffer?.valueOf(group.key),
                  label: 'Цвет: ${c.label(property)}',
                  child: Tooltip(
                      message: c.label(property),
                      child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _select(group.key, property.value),
                          child: Container(
                              width: 48,
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          property.value == c.selectedOffer?.valueOf(group.key)
                                              ? AppColors.primaryText
                                              : AppColors.border,
                                      width:
                                          property.value == c.selectedOffer?.valueOf(group.key)
                                              ? 2
                                              : 1)),
                              child: c.imageFor(property).isEmpty
                                  ? const Icon(Icons.palette_outlined)
                                  : _photo(c.imageFor(property))))))
            else
              Semantics(
                  selected:
                      property.value == c.selectedOffer?.valueOf(group.key),
                  child: OutlinedButton(
                      onPressed: () => _select(group.key, property.value),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(56, 36), padding: const EdgeInsets.symmetric(horizontal: 12), foregroundColor: AppColors.mainText, backgroundColor: property.value == c.selectedOffer?.valueOf(group.key) ? AppColors.primaryAccent.withValues(alpha: .1) : Colors.white, side: BorderSide(color: property.value == c.selectedOffer?.valueOf(group.key) ? AppColors.primaryText : AppColors.border, width: property.value == c.selectedOffer?.valueOf(group.key) ? 2 : 1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: Text(c.label(property), style: const TextStyle(fontSize: 14)))),
        ]),
      ],
    ]);
  }

  Widget _content() {
    final c = _controller, detail = c.detail!;
    final images = c.images;
    return ListView(children: [
      ColoredBox(
          color: Colors.white,
          child: Column(children: [
            Stack(children: [
              SizedBox(
                  height: (MediaQuery.sizeOf(context).width * .8)
                      .clamp(220.0, 340.0),
                  width: double.infinity,
                  child: images.isEmpty
                      ? const Icon(Icons.image_outlined, size: 64)
                      : PageView.builder(
                          controller: _gallery,
                          onPageChanged: (i) => setState(() => _image = i),
                          itemCount: images.length,
                          itemBuilder: (_, i) => GestureDetector(
                              onTap: _zoom,
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: _photo(images[i]))))),
              if (images.isNotEmpty)
                Positioned(
                    bottom: 0,
                    right: 8,
                    child: IconButton(
                        tooltip: 'Увеличить фото',
                        onPressed: _zoom,
                        icon: const Icon(Icons.fullscreen, size: 20))),
            ]),
            if (images.length > 1)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < images.length; i++)
                  Semantics(
                      label: 'Фото ${i + 1} из ${images.length}',
                      selected: _image == i,
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                              child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _image == i
                                          ? AppColors.primaryText
                                          : AppColors.border))))),
              ]),
          ])),
      _section([
        Text(c.name,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, height: 1.25)),
        _variantSelectors(),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
              child: Text('Артикул: ${c.id}',
                  style: const TextStyle(
                      color: AppColors.secondaryText, fontSize: 11))),
          if (detail.ruStoreWarning)
            TextButton.icon(
                onPressed: () => showProductInformation(
                    context,
                    'Без RuStore',
                    const Text(
                        'В товаре имеется недостаток: RuStore недоступен на устройствах Apple')),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryText,
                    textStyle: const TextStyle(fontSize: 12)),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Без RuStore')),
        ]),
      ]),
      _panel([
        Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(c.price > 0 ? formatPrice(c.price) : 'Цена по запросу',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
              if (c.storePrice > c.price && c.price > 0)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(formatPrice(c.storePrice),
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                          decoration: TextDecoration.lineThrough)),
                  IconButton(
                      tooltip: 'О ценах',
                      onPressed: () => showProductInformation(
                          context,
                          'О ценах',
                          const Text(
                              'Цена на сайте — при оформлении заказа на сайте и оплате наличными. Цена в магазине — розничная цена без оформления заказа на сайте.')),
                      icon: const Icon(Icons.info_outline, size: 16)),
                ]),
            ]),
        if (c.canBuy == true && c.storePrice > c.price && c.price > 0)
          Text('Выгода ${formatPrice(c.storePrice - c.price)}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.primaryText)),
        const SizedBox(height: 8),
        SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: _purchase,
                style: FilledButton.styleFrom(
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: Text(c.action == PurchaseAction.cart
                    ? 'Добавить в корзину'
                    : c.actionLabel))),
        if (c.price > 0 && c.storePrice > 0)
          TextButton.icon(
              onPressed: () => showProductInformation(context, 'Рассрочка',
                  InstallmentCalculator(price: c.storePrice)),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryText,
                  padding: EdgeInsets.zero),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              label: Text(
                  'Рассрочка от ${formatPrice((c.storePrice / 24).ceil())}/мес.',
                  style: const TextStyle(fontSize: 13))),
        if (detail.promoTiers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(detail.promoName,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, children: [
            for (final tier in detail.promoTiers)
              Chip(label: Text('${tier.$1} шт. → −${tier.$2}%'))
          ]),
        ],
        Consumer<SavedProductsProvider>(
            builder: (context, saved, _) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (saved.comparison.isNotEmpty)
                    TextButton(
                        onPressed: () =>
                            _navigate(const SavedProductsScreen(compare: true)),
                        child: Text('Сравнение (${saved.comparison.length})')),
                  if (saved.error != null)
                    Text(saved.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                ])),
      ]),
      _panel([
        const Text('Способы получения',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        if (c.canBuy == true)
          ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.store_outlined, size: 22),
              title: const Text('Самовывоз в Краснодаре',
                  style: TextStyle(fontSize: 14)),
              subtitle: const Text('Наличие уточните перед поездкой',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => _navigate(const ContactsScreen()))
        else
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  c.action == PurchaseAction.order
                      ? 'Наличие, цену и срок поставки уточняйте у менеджера'
                      : c.canBuy == false
                          ? 'Этот вариант доступен по предзаказу'
                          : 'Наличие уточняется у менеджера',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.secondaryText))),
        ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.local_shipping_outlined, size: 22),
            title: const Text('Доставка и условия',
                style: TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _navigate(const DeliveryScreen())),
      ]),
      _panel([
        ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.verified_user_outlined, size: 22),
            title: const Text('Гарантия', style: TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _navigate(const WarrantyScreen())),
        const Divider(height: 1),
        ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.swap_horiz, size: 22),
            title: const Text('Trade-in', style: TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _navigate(const TradeInScreen())),
      ]),
      Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Описание')),
                      ButtonSegment(value: true, label: Text('Характеристики'))
                    ],
                    selected: {
                      _showSpecs
                    },
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        setState(() => _showSpecs = value.first),
                    style: SegmentedButton.styleFrom(
                        selectedForegroundColor: AppColors.primaryText,
                        selectedBackgroundColor: Colors.white,
                        foregroundColor: AppColors.secondaryText,
                        backgroundColor: AppColors.border,
                        minimumSize: const Size(0, 44),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))))),
            const SizedBox(height: 12),
            if (_showSpecs) ...[
              if (c.specs.isEmpty)
                const Text(
                    'Характеристики для этого варианта пока не переданы.'),
              for (final group in c.specs.map((s) => s.group).toSet()) ...[
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(group,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700))),
                for (final spec in c.specs.where((s) => s.group == group))
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Text(spec.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.secondaryText))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(spec.value,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 13))),
                          ])),
              ],
              const SizedBox(height: 12),
              const Text(
                  'Характеристики носят справочный характер. Актуальную информацию уточняйте перед покупкой.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.secondaryText)),
            ] else if (c.description.isEmpty)
              const Text('Описание пока не добавлено.')
            else
              ProductDescription(
                  key: ValueKey(c.description), html: c.description),
          ])),
      const SizedBox(height: 16),
    ]);
  }
}
