import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/category_provider.dart';
import '../../core/theme/app_colors.dart';
import '../screens/main_screen.dart';
import '../screens/product_search_delegate.dart';
import '../screens/info_screens.dart';
import '../screens/service_tradein_screens.dart';

class BurgerMenu extends StatefulWidget {
  const BurgerMenu({super.key});

  @override
  State<BurgerMenu> createState() => _BurgerMenuState();
}

class _BurgerMenuState extends State<BurgerMenu> {
  bool _buyerExpanded = false;

  static const _buyerItems = [
    _BuyerItem(icon: Icons.build_outlined,          label: 'Сервисный центр', screenType: 'service'),
    _BuyerItem(icon: Icons.swap_horiz,              label: 'Trade-in',        screenType: 'tradein'),
    _BuyerItem(icon: Icons.credit_card,             label: 'Рассрочка',       screenType: 'credit'),
    _BuyerItem(icon: Icons.local_shipping_outlined, label: 'Доставка',        screenType: 'delivery'),
    _BuyerItem(icon: Icons.security_outlined,       label: 'Гарантия',         screenType: 'warranty'),
    _BuyerItem(icon: Icons.location_on_outlined,    label: 'Контакты',         screenType: 'contacts'),
  ];

  void _openNativeScreen(String screenType) {
    Widget screen;
    switch (screenType) {
      case 'service':  screen = const ServiceScreen(); break;
      case 'tradein':  screen = const TradeInScreen(); break;
      case 'credit':   screen = const CreditScreen(); break;
      case 'delivery': screen = const DeliveryScreen(); break;
      case 'warranty': screen = const WarrantyScreen(); break;
      case 'contacts': screen = const ContactsScreen(); break;
      default: return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            // ── Шапка ─────────────────────────────────────
            Container(
              color: AppColors.darkAccent,
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter'),
                      children: [
                        TextSpan(text: 're', style: TextStyle(color: Colors.white)),
                        TextSpan(
                            text: 'platinum',
                            style: TextStyle(color: AppColors.primaryAccent)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Поиск ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  showSearch(
                    context: context,
                    delegate: ProductSearchDelegate(),
                  );
                },
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: AppColors.secondaryText, size: 20),
                      const SizedBox(width: 8),
                      const Text('Поиск товаров...',
                          style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Контент ───────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Заголовок КАТАЛОГ
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('КАТАЛОГ',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.secondaryText)),
                  ),

                  // Категории
                  Consumer<CategoryProvider>(
                    builder: (context, catProvider, _) {
                      if (catProvider.isLoading) {
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              color: AppColors.primaryAccent),
                        ));
                      }
                      return Column(
                        children: catProvider.categories.map((cat) {
                          return _CategoryTile(
                            name: cat.name,
                            imageUrl: cat.image,
                            onTap: () {
                              Navigator.of(context).pop();
                              MainScreen.of(context)?.switchToCatalog(category: cat);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const Divider(height: 24, indent: 16, endIndent: 16),

                  // Покупателям (раскрывается)
                  InkWell(
                    onTap: () => setState(() => _buyerExpanded = !_buyerExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            _buyerExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            color: AppColors.primaryAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text('Покупателям',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mainText)),
                        ],
                      ),
                    ),
                  ),

                  if (_buyerExpanded)
                    Container(
                      color: const Color(0xFFF8F9FA),
                      child: Column(
                        children: _buyerItems.map((item) {
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              _openNativeScreen(item.screenType);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(item.icon,
                                      size: 18, color: AppColors.secondaryText),
                                  const SizedBox(width: 12),
                                  Text(item.label,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.mainText)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),

            // ── Войти (прилипает внизу) ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // TODO: переход на экран авторизации
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text('Войти',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Строка категории ──────────────────────────────────────────────────────
class _CategoryTile extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // Картинка
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.category_outlined,
                              color: AppColors.secondaryText),
                    )
                  : const Icon(Icons.category_outlined,
                      color: AppColors.secondaryText),
            ),
            const SizedBox(width: 12),
            // Название
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainText)),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.secondaryText, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Вспомогательный класс ─────────────────────────────────────────────────
class _BuyerItem {
  final IconData icon;
  final String label;
  final String screenType;
  const _BuyerItem({required this.icon, required this.label, required this.screenType});
}
