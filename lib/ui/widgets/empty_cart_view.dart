import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/api_service.dart';
import '../../data/models/product_model.dart';
import '../screens/main_screen.dart';
import 'home_product_carousel.dart';

class EmptyCartView extends StatefulWidget {
  const EmptyCartView({super.key, this.apiService, this.onCatalog});
  final ApiService? apiService;
  final VoidCallback? onCatalog;
  @override
  State<EmptyCartView> createState() => _EmptyCartViewState();
}

class _EmptyCartViewState extends State<EmptyCartView> {
  late final ApiService _api = widget.apiService ?? ApiService();
  late Future<List<Product>> _hits = _api.getHomeProducts('hit');
  late Future<List<Product>> _new = _api.getHomeProducts('new');

  @override
  Widget build(BuildContext context) => ListView(
        key: const PageStorageKey('empty-cart-scroll'),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
            child: Column(children: [
              const Text('В корзине пока ничего нет',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainText)),
              const SizedBox(height: 10),
              const Text(
                  'Перейдите в каталог или воспользуйтесь поиском, чтобы найти нужный товар.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.secondaryText)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onCatalog ??
                    () => MainScreen.of(context)?.switchToCatalog(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkAccent,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(160, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('В каталог'),
              ),
            ]),
          ),
          HomeProductCarousel(
              title: 'Хиты продаж',
              badge: 'ХИТ ПРОДАЖ',
              badgeColor: AppColors.primaryAccent,
              future: _hits,
              onRetry: () =>
                  setState(() => _hits = _api.getHomeProducts('hit'))),
          const SizedBox(height: 16),
          HomeProductCarousel(
              title: 'Новинки',
              badge: 'НОВИНКА',
              badgeColor: const Color(0xFFFF9800),
              future: _new,
              onRetry: () =>
                  setState(() => _new = _api.getHomeProducts('new'))),
        ],
      );
}
