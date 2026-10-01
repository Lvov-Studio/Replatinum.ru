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
      appBar: AppBar(title: Text(compare ? 'Сравнение' : 'Избранное')),
      body: Consumer<SavedProductsProvider>(builder: (context, provider, _) {
        if (!provider.ready) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = (compare ? provider.comparison : provider.favorites)
            .values
            .toList();
        if (items.isEmpty) {
          return Center(
              child: Text(compare
                  ? 'Добавьте товары для сравнения'
                  : 'Добавьте понравившиеся товары в избранное'));
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
                                          : 'По запросу'))
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
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                  onTap: () => _open(context, item),
                  leading: SizedBox(
                      width: 64,
                      height: 64,
                      child: item.product.image.isEmpty
                          ? const Icon(Icons.image_outlined)
                          : CachedNetworkImage(
                              imageUrl: item.product.image,
                              fit: BoxFit.contain)),
                  title: Text(item.product.name),
                  subtitle: Text(item.product.price > 0
                      ? formatPrice(item.product.price)
                      : 'Цена по запросу'),
                  trailing: IconButton(
                      tooltip: 'Убрать из избранного',
                      onPressed: () => provider.toggle(item),
                      icon: const Icon(Icons.favorite, color: Colors.red)));
            });
      }));
}
