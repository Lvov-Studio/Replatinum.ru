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
    _BuyerItem(
        icon: Icons.build_outlined,
        label: 'Сервисный центр',
        screenType: 'service'),
    _BuyerItem(
        icon: Icons.swap_horiz, label: 'Trade-in', screenType: 'tradein'),
    _BuyerItem(
        icon: Icons.credit_card, label: 'Рассрочка', screenType: 'credit'),
    _BuyerItem(
        icon: Icons.local_shipping_outlined,
        label: 'Доставка',
        screenType: 'delivery'),
    _BuyerItem(
        icon: Icons.security_outlined,
        label: 'Гарантия',
        screenType: 'warranty'),
    _BuyerItem(
        icon: Icons.location_on_outlined,
        label: 'Контакты',
        screenType: 'contacts'),
  ];

  void _openNativeScreen(String screenType) {
    Widget screen;
    switch (screenType) {
      case 'service':
        screen = const ServiceScreen();
        break;
      case 'tradein':
        screen = const TradeInScreen();
        break;
      case 'credit':
        screen = const CreditScreen();
        break;
      case 'delivery':
        screen = const DeliveryScreen();
        break;
      case 'warranty':
        screen = const WarrantyScreen();
        break;
      case 'contacts':
        screen = const ContactsScreen();
        break;
      default:
        return;
    }
    // Открываем через навигатор текущего таба — нижнее меню остаётся
    final tabNav =
        MainScreen.tabNavigatorKeys[MainScreen.currentTabIndex].currentState;
    if (tabNav != null) {
      tabNav.push(MaterialPageRoute(builder: (_) => screen));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.85;
    return Drawer(
      width: drawerWidth > 320 ? 320 : drawerWidth,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top,
            child: const ColoredBox(color: Color(0xFF1E1E26)),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Шапка ─────────────────────────────────────
                Container(
                  color: const Color(0xFF1E1E26),
                  padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
                  child: Row(
                    children: [
                      // Логотип и закрытие расположены как в мобильном меню сайта.
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter'),
                          children: [
                            TextSpan(
                                text: 're',
                                style: TextStyle(color: Colors.white)),
                            TextSpan(
                                text: 'platinum',
                                style:
                                    TextStyle(color: AppColors.primaryAccent)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Semantics(
                        button: true,
                        label: 'Закрыть меню',
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close,
                                    color: Color(0xFF555555), size: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Поиск ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      showSearch(
                        context: context,
                        delegate: ProductSearchDelegate(),
                      );
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search,
                              color: Color(0xFFAAAAAA), size: 17),
                          const SizedBox(width: 10),
                          const Text('Поиск товаров...',
                              style: TextStyle(
                                  color: Color(0xFFBBBBBB), fontSize: 14)),
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
                        padding: EdgeInsets.fromLTRB(18, 14, 18, 6),
                        child: Text('КАТАЛОГ',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: Color(0xFFAAAAAA))),
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
                                  MainScreen.of(context)
                                      ?.switchToCatalog(category: cat);
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const Divider(height: 24, indent: 16, endIndent: 16),

                      // Покупателям (раскрывается)
                      InkWell(
                        onTap: () =>
                            setState(() => _buyerExpanded = !_buyerExpanded),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                                          size: 18,
                                          color: AppColors.secondaryText),
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
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            // Картинка категории
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 52,
                height: 52,
                color: const Color(0xFFF2F2F7),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: (_, __) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.category_outlined,
                                color: AppColors.secondaryText, size: 24)),
                        imageBuilder: (_, imageProvider) => Padding(
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.category_outlined,
                            color: AppColors.secondaryText, size: 24)),
              ),
            ),
            const SizedBox(width: 13),
            // Название
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mainText)),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 16),
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
  const _BuyerItem(
      {required this.icon, required this.label, required this.screenType});
}
