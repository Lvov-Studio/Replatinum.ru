import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/saved_products_shortcuts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/saved_products_provider.dart';
import 'info_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Кабинет',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
              'Вход в аккаунт пока в разработке. '
              'Избранное и сравнение сохраняются на этом устройстве.',
              style: TextStyle(color: AppColors.mainText)),
          const SizedBox(height: 20),
          Consumer<SavedProductsProvider>(
            builder: (context, saved, _) => Column(children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.favorite_border),
                title: const Text('Избранное'),
                trailing: Text(saved.ready ? '${saved.favorites.length}' : '…'),
                onTap: () => openSavedProducts(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bar_chart),
                title: const Text('Сравнение'),
                trailing:
                    Text(saved.ready ? '${saved.comparison.length}' : '…'),
                onTap: () => openSavedProducts(context, compare: true),
              ),
            ]),
          ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Позвонить в магазин'),
            subtitle: const Text('+7 (918) 007-23-33'),
            onTap: () async {
              try {
                final opened =
                    await launchUrl(Uri(scheme: 'tel', path: '+79180072333'));
                if (!opened) throw StateError('Dialer unavailable');
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Не удалось открыть набор номера')));
                }
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Магазины и контакты'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const ContactsScreen())),
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline,
                size: 72, color: AppColors.primaryAccent),
            const SizedBox(height: 16),
            const Text(
              'Избранное',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Здесь появятся понравившиеся товары',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
