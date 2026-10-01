import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'placeholder_screens.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../data/models/category_model.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/burger_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const homeTab = 0;
  static const catalogTab = 1;
  static const cartTab = 2;
  static const profileTab = 3;

  // GlobalKey для открытия drawer из CustomAppBar
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  // Вложенные навигаторы для каждого таба (нижнее меню не исчезает)
  static final tabNavigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  // Текущий активный таб (для burger menu)
  static int currentTabIndex = 0;

  @override
  State<MainScreen> createState() => _MainScreenState();

  // ignore: library_private_types_in_public_api
  static _MainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenState>();
  }
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    MainScreen.currentTabIndex = MainScreen.homeTab;
  }

  void switchToTab(int index) {
    final navState = MainScreen.tabNavigatorKeys[index].currentState;

    if (index == _currentIndex) {
      // Уже на этом табе — поп до корня (закрывает инфо-экраны из бургер-меню)
      if (navState != null && navState.canPop()) {
        navState.popUntil((r) => r.isFirst);
      }
      if (index == MainScreen.catalogTab) {
        context.read<ProductProvider>().clearCategory();
      }
      return;
    }

    // Переключение на другой таб
    MainScreen.currentTabIndex = index;
    setState(() => _currentIndex = index);
  }

  /// Переключиться на каталог с фильтром категории
  void switchToCatalog({Category? category}) {
    context.read<ProductProvider>().setCategory(category);
    MainScreen.currentTabIndex = MainScreen.catalogTab;
    setState(() => _currentIndex = MainScreen.catalogTab);
  }

  Widget _buildTabScreen(int index) {
    const screens = [
      HomeScreen(),
      CatalogScreen(),
      CartScreen(),
      ProfileScreen(),
    ];
    return Navigator(
      key: MainScreen.tabNavigatorKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => screens[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Перехватываем кнопку «Назад» — сначала пробуем поп внутри таба
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navState =
            MainScreen.tabNavigatorKeys[_currentIndex].currentState;
        if (navState != null && navState.canPop()) {
          navState.pop();
        }
      },
      child: Scaffold(
        key: MainScreen.scaffoldKey,
        drawer: const BurgerMenu(),
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(4, _buildTabScreen),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    const bgColor = Color(0xFF1E1E26);
    const activeColor = AppColors.primaryAccent;
    const inactiveColor = Color(0xFFB1B1BC);

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
          height: 56 +
              (MediaQuery.textScalerOf(context).scale(11) - 11).clamp(0, 33) *
                  4,
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
              // 1 — Каталог
              _TabItem(
                index: MainScreen.catalogTab,
                currentIndex: _currentIndex,
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                label: 'Каталог',
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => switchToTab(MainScreen.catalogTab),
              ),
              // 2 — Корзина (с бейджем)
              _CartTabItem(
                index: MainScreen.cartTab,
                currentIndex: _currentIndex,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => switchToTab(MainScreen.cartTab),
              ),
              // 3 — Кабинет
              _TabItem(
                index: MainScreen.profileTab,
                currentIndex: _currentIndex,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Кабинет',
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => switchToTab(MainScreen.profileTab),
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.11)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isActive
                            ? Icons.shopping_bag
                            : Icons.shopping_bag_outlined,
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
                              border: Border.all(
                                  color: const Color(0xFF1E1E26), width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
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
              const SizedBox(height: 4),
              Text(
                'Корзина',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
