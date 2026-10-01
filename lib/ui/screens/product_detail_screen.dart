import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/product_model.dart';
import '../../data/api/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_detail_controller.dart';
import '../../providers/saved_products_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';
import '../widgets/product_purchase_sheets.dart';
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
  bool _showSpecs = false, _expanded = false;
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
    main?.switchToTab(3);
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
    setState(() {
      _image = 0;
      _expanded = false;
    });
    if (_gallery.hasClients) _gallery.jumpToPage(0);
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
  Widget _galleryAction(IconData icon, String label, VoidCallback action) =>
      Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: IconButton(
              onPressed: action,
              tooltip: label,
              icon: Icon(icon),
              constraints:
                  const BoxConstraints.tightFor(width: 48, height: 48)));
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
                toolbarHeight: loaded ? 0 : 48,
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
                                      minimumSize: const Size(0, 48)),
                                  child: Text(c.actionLabel));
                              if (constraints.maxWidth < 340 ||
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
                                Flexible(child: button)
                              ]);
                            }))))
                : null);
      });
  Widget _content() {
    final c = _controller, detail = c.detail!;
    final images = c.images;
    return ListView(children: [
      ColoredBox(
          color: Colors.white,
          child: Column(children: [
            Stack(children: [
              SizedBox(
                  height: (MediaQuery.sizeOf(context).width * .82)
                      .clamp(240.0, 360.0),
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
              Positioned(
                  top: 8,
                  left: 8,
                  child: _galleryAction(Icons.arrow_back, 'Назад',
                      () => Navigator.of(context).pop())),
              Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<CartProvider>(
                      builder: (context, cart, _) => Badge(
                          isLabelVisible: cart.itemCount > 0,
                          label: Text('${cart.itemCount}'),
                          child: _galleryAction(Icons.shopping_bag_outlined,
                              'Корзина', _openCart)))),
              if (images.isNotEmpty)
                Positioned(
                    bottom: 8,
                    right: 8,
                    child: _galleryAction(
                        Icons.fullscreen, 'Увеличить фото', _zoom)),
            ]),
            if (images.length > 1)
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                      height: 56,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => Semantics(
                              label: 'Фото ${i + 1} из ${images.length}',
                              selected: _image == i,
                              button: true,
                              child: InkWell(
                                  onTap: () => _gallery.jumpToPage(i),
                                  child: Container(
                                      width: 56,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: _image == i
                                                  ? AppColors.darkAccent
                                                  : const Color(0xFFE0E0E0),
                                              width: _image == i ? 2 : 1)),
                                      child: _photo(images[i]))))))),
          ])),
      _section([
        Text(c.name,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, height: 1.3)),
        const SizedBox(height: 8),
        Text('Артикул: ${c.id}',
            style:
                const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
        if (detail.ruStoreWarning)
          TextButton.icon(
              onPressed: () => showProductInformation(
                  context,
                  'Без RuStore',
                  const Text(
                      'В товаре имеется недостаток: RuStore недоступен на устройствах Apple')),
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Без RuStore'))
      ]),
      if (c.variantGroups.isNotEmpty) ...[
        const SizedBox(height: 8),
        _section([
          for (final group in c.variantGroups.entries) ...[
            Text(
                '${group.value.first.name}: ${c.label(group.value.firstWhere((p) => p.value == c.selectedOffer?.valueOf(group.key), orElse: () => group.value.first))}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in group.value)
                if (group.key == 'COLOR')
                  Semantics(
                      button: true,
                      selected: p.value == c.selectedOffer?.valueOf(group.key),
                      label: 'Цвет: ${c.label(p)}',
                      child: Tooltip(
                          message: c.label(p),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _select(group.key, p.value),
                              child: Container(
                                  width: 76,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: p.value ==
                                                  c.selectedOffer
                                                      ?.valueOf(group.key)
                                              ? AppColors.darkAccent
                                              : const Color(0xFFE0E0E0),
                                          width: 2)),
                                  child: Column(children: [
                                    SizedBox(
                                        height: 48,
                                        child: c.imageFor(p).isEmpty
                                            ? const Icon(Icons.palette_outlined)
                                            : _photo(c.imageFor(p))),
                                    const SizedBox(height: 4),
                                    Text(c.label(p),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis)
                                  ])))))
                else
                  ChoiceChip(
                      label: Text(c.label(p)),
                      selected: p.value == c.selectedOffer?.valueOf(group.key),
                      onSelected: (_) => _select(group.key, p.value),
                      selectedColor: AppColors.darkAccent,
                      labelStyle: TextStyle(
                          color: p.value == c.selectedOffer?.valueOf(group.key)
                              ? Colors.white
                              : AppColors.mainText),
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.padded)
            ]),
            const SizedBox(height: 16),
          ]
        ])
      ],
      const SizedBox(height: 8),
      _section([
        Wrap(
            spacing: 20,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(c.price > 0 ? formatPrice(c.price) : 'Цена по запросу',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800)),
              if (c.storePrice > c.price && c.price > 0)
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (c.canBuy == true)
                    Text('Выгода ${formatPrice(c.storePrice - c.price)}',
                        style: const TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w700)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(formatPrice(c.storePrice),
                        style: const TextStyle(
                            color: AppColors.secondaryText,
                            decoration: TextDecoration.lineThrough)),
                    IconButton(
                        tooltip: 'О ценах',
                        onPressed: () => showProductInformation(
                            context,
                            'О ценах',
                            const Text(
                                'Цена на сайте — при оформлении заказа на сайте и оплате наличными. Цена в магазине — розничная цена без оформления заказа на сайте.')),
                        icon: const Icon(Icons.info_outline, size: 18))
                  ])
                ])
            ]),
        if (c.price > 0 && c.storePrice > 0)
          TextButton.icon(
              onPressed: () => showProductInformation(context, 'Рассрочка',
                  InstallmentCalculator(price: c.storePrice)),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
              label: Text(
                  'Рассрочка от ${formatPrice((c.storePrice / 24).ceil())}/мес.')),
        Consumer<SavedProductsProvider>(
            builder: (context, saved, _) => Row(children: [
                  Expanded(
                      child: FilledButton(
                          onPressed: _purchase, child: Text(c.actionLabel))),
                  IconButton(
                      tooltip: saved.favorites.containsKey(c.id)
                          ? 'Убрать из избранного'
                          : 'В избранное',
                      onPressed: saved.ready
                          ? () => saved.toggle(
                              SavedProduct(c.cartProduct, c.id, c.specs))
                          : null,
                      icon: Icon(
                          saved.favorites.containsKey(c.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: saved.favorites.containsKey(c.id)
                              ? Colors.red
                              : AppColors.darkAccent)),
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
                ])),
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
                            color: Theme.of(context).colorScheme.error))
                ])),
        const SizedBox(height: 12),
        if (c.canBuy == true)
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.store_outlined),
              title: const Text('Самовывоз в Краснодаре'),
              subtitle: const Text(
                  'Наличие в выбранном магазине уточните перед поездкой'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigate(const ContactsScreen()))
        else
          Text(
              c.action == PurchaseAction.order
                  ? 'Наличие, цену и срок поставки уточняйте у менеджера'
                  : c.canBuy == false
                      ? 'Этот вариант доступен по предзаказу'
                      : 'Наличие уточняется у менеджера',
              style: const TextStyle(color: AppColors.secondaryText)),
        TextButton.icon(
            onPressed: () => _navigate(const DeliveryScreen()),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Доставка и условия')),
        if (detail.promoTiers.isNotEmpty) ...[
          const Divider(),
          Text(detail.promoName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Wrap(spacing: 8, children: [
            for (final tier in detail.promoTiers)
              Chip(label: Text('${tier.$1} шт. → −${tier.$2}%'))
          ])
        ],
      ]),
      const SizedBox(height: 8),
      _section([
        Row(children: [
          Expanded(
              child: TextButton(
                  onPressed: () => setState(() => _showSpecs = false),
                  child: Text('Описание',
                      style: TextStyle(
                          fontWeight: !_showSpecs
                              ? FontWeight.w800
                              : FontWeight.w400)))),
          Expanded(
              child: TextButton(
                  onPressed: () => setState(() => _showSpecs = true),
                  child: Text('Характеристики',
                      style: TextStyle(
                          fontWeight:
                              _showSpecs ? FontWeight.w800 : FontWeight.w400))))
        ]),
        const Divider(),
        if (_showSpecs) ...[
          if (c.specs.isEmpty)
            const Text('Характеристики для этого варианта пока не переданы.'),
          for (final group in c.specs.map((s) => s.group).toSet()) ...[
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(group,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            for (final spec in c.specs.where((s) => s.group == group))
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Text(spec.name,
                                style: const TextStyle(
                                    color: AppColors.secondaryText))),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Text(spec.value, textAlign: TextAlign.right))
                      ])),
          ],
          const SizedBox(height: 16),
          const Text(
              'Характеристики носят справочный характер. Актуальную информацию уточняйте перед покупкой.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText))
        ] else if (c.description.isEmpty)
          const Text('Описание пока не добавлено.')
        else ...[
          ClipRect(
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: _expanded ? double.infinity : 240),
                  child: SingleChildScrollView(
                      physics: _expanded
                          ? null
                          : const NeverScrollableScrollPhysics(),
                      child: Html(
                          data: c.description,
                          onLinkTap: (url, _, __) {
                            final uri = Uri.tryParse(url ?? '');
                            if (uri != null &&
                                const ['https', 'http'].contains(uri.scheme)) {
                              launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          style: {
                            'body': Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                fontSize: FontSize(14),
                                lineHeight: const LineHeight(1.5))
                          })))),
          TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(_expanded ? 'Свернуть' : 'Подробнее')),
        ],
      ]),
      const SizedBox(height: 8),
      _section([
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Гарантия'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigate(const WarrantyScreen())),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Trade-in'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigate(const TradeInScreen())),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}
