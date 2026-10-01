import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/saved_products_provider.dart';
import '../screens/saved_products_screen.dart';
import '../screens/info_screens.dart';

void openSavedProducts(BuildContext context, {bool compare = false}) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => SavedProductsScreen(compare: compare),
  ));
}

/// Persistent access from the catalog, even after the home header collapses.
class SavedProductsActions extends StatelessWidget {
  const SavedProductsActions({super.key});

  @override
  Widget build(BuildContext context) => Consumer<SavedProductsProvider>(
        builder: (context, saved, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (compare, count, icon, label) in [
              (
                false,
                saved.favorites.length,
                Icons.favorite_border,
                'Избранное'
              ),
              (true, saved.comparison.length, Icons.bar_chart, 'Сравнение'),
            ])
              IconButton(
                tooltip: '$label ($count)',
                onPressed: () => openSavedProducts(context, compare: compare),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Badge(
                  isLabelVisible: saved.ready && count > 0,
                  label: Text(count > 99 ? '99+' : '$count'),
                  backgroundColor: AppColors.primaryAccent,
                  textColor: AppColors.onPrimary,
                  child: Icon(icon, size: 22),
                ),
              ),
          ],
        ),
      );
}

class SavedProductsTiles extends StatelessWidget {
  const SavedProductsTiles({super.key});

  @override
  Widget build(BuildContext context) => Consumer<SavedProductsProvider>(
        builder: (context, saved, _) => LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth =
                ((constraints.maxWidth - 20) / 3).clamp(0.0, 118.0);
            return Row(
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _SavedTile(
                    label: 'Избранное',
                    icon: Icons.favorite_border,
                    count: saved.favorites.length,
                    ready: saved.ready,
                    error: saved.error != null,
                    onTap: () => openSavedProducts(context),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: tileWidth,
                  child: _SavedTile(
                    label: 'Сравнение',
                    icon: Icons.bar_chart,
                    count: saved.comparison.length,
                    ready: saved.ready,
                    error: saved.error != null,
                    onTap: () => openSavedProducts(context, compare: true),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: tileWidth,
                  child: _SavedTile(
                    label: 'Магазины',
                    icon: Icons.location_on_outlined,
                    count: 0,
                    ready: true,
                    error: false,
                    subtitle: 'Адреса',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const ContactsScreen())),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.ready,
    required this.error,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool ready;
  final bool error;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final status = subtitle ??
        (!ready
            ? 'Загрузка…'
            : error
                ? 'Ошибка хранения'
                : count == 0
                    ? 'Нет товаров'
                    : 'Товаров: $count');
    return Material(
      color: const Color(0xFF2B2B34),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primaryAccent, size: 22),
              const SizedBox(height: 10),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFFC8C8D0), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
