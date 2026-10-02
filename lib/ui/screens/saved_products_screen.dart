import '../../features/account/ui/account_menu_tile.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/saved_products_provider.dart';
import '../../core/utils/price_formatter.dart';
import 'product_detail_screen.dart';

class SavedProductsScreen extends StatelessWidget {
  final bool compare;
  const SavedProductsScreen({super.key, this.compare = false});
  void _open(BuildContext context, SavedProduct item) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
              productPreview: item.product, initialOfferId: item.skuId)));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          title: Text(compare ? 'Сравнение' : 'Избранное'),
          actions: [
            Consumer<SavedProductsProvider>(
                builder: (context, saved, _) => saved.accountConnected
                    ? IconButton(
                        tooltip: 'Обновить',
                        onPressed: saved.syncing ? null : saved.refreshRemote,
                        icon: const Icon(Icons.refresh))
                    : const SizedBox.shrink()),
          ]),
      body: Consumer<SavedProductsProvider>(builder: (context, provider, _) {
        if (!provider.ready || provider.syncing) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(provider.error!),
                    if (provider.accountConnected)
                      TextButton(
                          onPressed: provider.refreshRemote,
                          child: const Text('Повторить')),
                  ])));
        }
        final items = (compare ? provider.comparison : provider.favorites)
            .values
            .toList();
        if (items.isEmpty) {
          return AccountEmptyState(
              icon: compare
                  ? Icons.bar_chart_rounded
                  : Icons.favorite_border_rounded,
              title: compare
                  ? 'Выбирайте и сравнивайте'
                  : 'Сохраните то, что нравится',
              message: compare
                  ? 'Добавьте товары для сравнения'
                  : 'Добавьте понравившиеся товары в избранное');
        }
        if (compare) {
          final names = items.expand((i) => i.specs.map((s) => s.name)).toSet();
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Цены и характеристики сохранены в момент добавления. Откройте товар для актуальных данных.')),
                Expanded(
                    child: SingleChildScrollView(
                        child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(16)),
                                headingRowColor: const WidgetStatePropertyAll(
                                    Color(0xFFF0F4EA)),
                                dividerThickness: 0.5,
                                dataTextStyle: const TextStyle(
                                    fontSize: 13, color: AppColors.mainText),
                                columns: [
                                  const DataColumn(label: Text('Параметр')),
                                  for (final item in items)
                                    DataColumn(
                                        label: SizedBox(
                                            width: 180,
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(item.product.name,
                                                      maxLines: 3,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                  TextButton(
                                                      onPressed: () =>
                                                          _open(context, item),
                                                      child:
                                                          const Text('Открыть'))
                                                ])))
                                ],
                                headingRowHeight: 140,
                                rows: [
                                  DataRow(cells: [
                                    const DataCell(Text('Цена')),
                                    for (final item in items)
                                      DataCell(Text(item.product.price > 0
                                          ? formatPrice(item.product.price)
                                          : 'Под заказ'))
                                  ]),
                                  for (final name in names)
                                    DataRow(cells: [
                                      DataCell(SizedBox(
                                          width: 140, child: Text(name))),
                                      for (final item in items)
                                        DataCell(SizedBox(
                                            width: 180,
                                            child: Text(item.specs
                                                    .where(
                                                        (s) => s.name == name)
                                                    .map((s) => s.value)
                                                    .join(' / ')
                                                    .isEmpty
                                                ? '—'
                                                : item.specs
                                                    .where(
                                                        (s) => s.name == name)
                                                    .map((s) => s.value)
                                                    .join(' / '))))
                                    ]),
                                  DataRow(cells: [
                                    const DataCell(Text('Удалить')),
                                    for (final item in items)
                                      DataCell(IconButton(
                                          tooltip: 'Убрать из сравнения',
                                          onPressed: () => provider.toggle(item,
                                              compare: true),
                                          icon: const Icon(Icons.close)))
                                  ])
                                ]))))
              ]);
        }
        return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return AccountSectionCard(
                  child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      onTap: () => _open(context, item),
                      leading: SizedBox(
                          width: 64,
                          height: 64,
                          child: item.product.image.isEmpty
                              ? const Icon(Icons.image_outlined)
                              : CachedNetworkImage(
                                  imageUrl: item.product.image,
                                  fit: BoxFit.contain)),
                      title: Text(item.product.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          item.product.price > 0
                              ? formatPrice(item.product.price)
                              : 'Под заказ',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText)),
                      trailing: IconButton(
                          tooltip: 'Убрать из избранного',
                          onPressed: () => provider.toggle(item),
                          icon: const Icon(Icons.favorite_rounded,
                              color: AppColors.primaryText))));
            });
      }));
}
