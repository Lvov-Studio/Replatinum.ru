import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../data/api/api_service.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_detail_model.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_colors.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product productPreview;
  const ProductDetailScreen({super.key, required this.productPreview});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<ProductDetail> _detailFuture;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  // Выбранный оффер
  Offer? _selectedOffer;

  @override
  void initState() {
    super.initState();
    _detailFuture = _apiService.getProductDetail(widget.productPreview.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _fmt(num price) {
    final s = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00A0');
      buf.write(s[i]);
    }
    return '${buf.toString()} ₽';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        title: Text(
          widget.productPreview.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: () => Navigator.pop(context),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: AppColors.primaryAccent, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('${cart.itemCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: FutureBuilder<ProductDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryAccent));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.wifi_off, size: 64, color: AppColors.secondaryText),
                const SizedBox(height: 12),
                const Text('Не удалось загрузить товар'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _detailFuture =
                        _apiService.getProductDetail(widget.productPreview.id);
                  }),
                  child: const Text('Повторить'),
                ),
              ]),
            );
          }
          if (!snapshot.hasData) return const Center(child: Text('Нет данных'));

          final detail = snapshot.data!;
          _selectedOffer ??= detail.offers.isNotEmpty ? detail.offers.first : null;

          return _buildContent(detail);
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              context.read<CartProvider>().addItem(widget.productPreview);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Добавлено в корзину'),
                duration: const Duration(seconds: 1),
                backgroundColor: AppColors.primaryAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ));
            },
            child: const Text('Добавить в корзину',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ProductDetail detail) {
    // Фото: если выбран оффер с фото — показываем его, иначе галерея товара
    final offerImg = _selectedOffer?.image ?? '';
    final images = offerImg.isNotEmpty ? [offerImg, ...detail.images] : detail.images;
    final price = _selectedOffer != null && _selectedOffer!.price > 0
        ? _selectedOffer!.price
        : detail.price;

    // Группируем свойства офферов по названию свойства
    final Map<String, List<Offer>> groupedOffers = {};
    for (final offer in detail.offers) {
      for (final prop in offer.properties) {
        groupedOffers.putIfAbsent(prop.name, () => []);
        if (!groupedOffers[prop.name]!.contains(offer)) {
          groupedOffers[prop.name]!.add(offer);
        }
      }
    }

    // Уникальные значения по каждому свойству
    final Map<String, List<String>> propValues = {};
    for (final entry in groupedOffers.entries) {
      final vals = <String>{};
      for (final offer in entry.value) {
        for (final p in offer.properties) {
          if (p.name == entry.key) vals.add(p.value);
        }
      }
      propValues[entry.key] = vals.toList();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Галерея фото ──────────────────────────────────
          Container(
            height: 300,
            color: Colors.white,
            child: images.isNotEmpty
                ? Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) =>
                            setState(() => _currentImageIndex = i),
                        itemCount: images.length,
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryAccent)),
                          errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.image_outlined,
                                  size: 80, color: Color(0xFFCCCCCC))),
                        ),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 12, left: 0, right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentImageIndex == i ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _currentImageIndex == i
                                    ? AppColors.primaryAccent
                                    : const Color(0xFFDDDDDD),
                              ),
                            )),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: Icon(Icons.image_outlined,
                        size: 80, color: Color(0xFFCCCCCC))),
          ),

          // ── Название и цена ───────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, height: 1.3)),
                const SizedBox(height: 10),
                Text(
                  price > 0 ? _fmt(price) : 'По запросу',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryAccent),
                ),
              ],
            ),
          ),

          // ── Вариации (цвет, память, SIM и т.д.) ──────────
          if (detail.offers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Миниатюры офферов (если есть фото)
                  if (detail.offers.any((o) => o.image.isNotEmpty)) ...[
                    const Text('Выберите вариант:',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: detail.offers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final offer = detail.offers[i];
                          final isSelected = _selectedOffer?.id == offer.id;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedOffer = offer;
                              _currentImageIndex = 0;
                            }),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryAccent
                                      : const Color(0xFFE0E0E0),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: offer.image.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: offer.image,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(
                                            Icons.image_outlined, size: 24,
                                            color: Color(0xFFCCCCCC)),
                                      )
                                    : Container(
                                        color: const Color(0xFFF0F0F0),
                                        child: const Icon(Icons.image_outlined,
                                            size: 24, color: Color(0xFFCCCCCC)),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Свойства по группам (Цвет, Память, SIM)
                  ...propValues.entries.map((entry) {
                    final propName = entry.key;
                    final values = entry.value;
                    // Текущее значение для этого свойства
                    final currentVal = _selectedOffer?.properties
                        .firstWhere((p) => p.name == propName,
                            orElse: () => OfferProperty(
                                code: '', name: propName, value: ''))
                        .value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$propName:  ',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: values.map((val) {
                            final isSelected = val == currentVal;
                            return GestureDetector(
                              onTap: () {
                                // Найти оффер с этим значением
                                final found = detail.offers.firstWhere(
                                  (o) => o.properties.any(
                                      (p) => p.name == propName && p.value == val),
                                  orElse: () => detail.offers.first,
                                );
                                setState(() {
                                  _selectedOffer = found;
                                  _currentImageIndex = 0;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryAccent
                                        : const Color(0xFFDDDDDD),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  color: isSelected
                                      ? AppColors.primaryAccent.withValues(alpha: 0.08)
                                      : Colors.white,
                                ),
                                child: Text(
                                  val,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.primaryAccent
                                        : AppColors.mainText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],

          // ── Описание ──────────────────────────────────────
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Описание',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Html(
                    data: detail.description,
                    style: {
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: AppColors.mainText,
                        lineHeight: const LineHeight(1.5),
                        fontSize: FontSize(14),
                      ),
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
