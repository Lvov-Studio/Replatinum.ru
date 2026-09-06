import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'placeholder_screens.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();

  // ignore: library_private_types_in_public_api
  static _MainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenState>();
  }
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),   // Избранное (заглушка)
    const CatalogScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Тёмный статус-бар под цвет шапки
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    const bgColor = Color(0xFF1E1E26);
    const activeColor = AppColors.primaryAccent;
    const inactiveColor = Color(0xFF6B6B7A);

    return Container(
      decoration: const BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              // 0 — Главная
              _TabItem(
                index: 0,
                currentIndex: _currentIndex,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Главная',
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => switchToTab(0),
              ),
              // 1 — Избранное
              _TabItem(
                index: 1,
                currentIndex: _currentIndex,
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite,
                label: 'Избранное',
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => switchToTab(1),
              ),
              // 2 — Каталог
              _TabItem(
                index: 2,
                currentIndex: _currentIndex,
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                label: 'Каталог',
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => switchToTab(2),
              ),
              // 3 — Корзина (с бейджем)
              _CartTabItem(
                index: 3,
                currentIndex: _currentIndex,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => switchToTab(3),
              ),
              // 4 — Кабинет
              _TabItem(
                index: 4,
                currentIndex: _currentIndex,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Кабинет',
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => switchToTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Обычная вкладка ──────────────────────────────────────────────────────────
class _TabItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _TabItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Активная точка
            if (isActive)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 8),
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Вкладка Корзина с бейджем ─────────────────────────────────────────────────
class _CartTabItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _CartTabItem({
    required this.index,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 8),
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isActive ? Icons.shopping_bag : Icons.shopping_bag_outlined,
                      color: isActive ? activeColor : inactiveColor,
                      size: 22,
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1E1E26), width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 3),
            Text(
              'Корзина',
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
