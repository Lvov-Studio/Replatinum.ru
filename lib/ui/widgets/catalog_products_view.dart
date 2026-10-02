import 'package:flutter/material.dart';
import '../../providers/product_provider.dart';
import '../../data/models/catalog_filter.dart';
import '../../core/theme/app_colors.dart';
import 'catalog_filter_sheet.dart';
import 'product_preview_card.dart';
import 'catalog_subsections_view.dart';
import '../screens/product_search_delegate.dart';

const catalogSortLabels = {
  CatalogSort.original: 'По умолчанию',
  CatalogSort.priceAscending: 'Сначала дешевле',
  CatalogSort.priceDescending: 'Сначала дороже',
  CatalogSort.name: 'По названию',
};

class CatalogProductsView extends StatelessWidget {
  const CatalogProductsView({super.key, required this.provider, this.onBack});
  final ProductProvider provider;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    final products = provider.products;
    final facets = provider.facets;
    return SafeArea(
        bottom: false,
        child: Column(children: [
          SizedBox(
              height: 56,
              child: Row(children: [
                IconButton(
                    tooltip: 'Вернуться к разделам',
                    onPressed: onBack ?? provider.goBack,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
                Expanded(
                    child: Text(provider.sectionTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
                IconButton(
                    tooltip: 'Обновить товары',
                    onPressed: provider.isLoading ? null : provider.retry,
                    icon: const Icon(Icons.refresh, size: 22)),
                IconButton(
                    tooltip: 'Поиск товаров',
                    onPressed: () => showSearch(
                        context: context, delegate: ProductSearchDelegate()),
                    icon: const Icon(Icons.search)),
              ])),
          const Divider(height: 1, color: AppColors.border),
          if (provider.isLoading &&
              (provider.browsing || products.isNotEmpty)) ...[
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (!provider.browsing &&
              !provider.isLoading &&
              provider.error.isEmpty &&
              provider.sectionTotal > 0) ...[
            Row(children: [
              Expanded(
                  child: PopupMenuButton<CatalogSort>(
                      tooltip: 'Сортировка товаров',
                      initialValue: provider.sort,
                      onSelected: provider.setSort,
                      itemBuilder: (_) => [
                            for (final entry in catalogSortLabels.entries)
                              PopupMenuItem(
                                  value: entry.key, child: Text(entry.value))
                          ],
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Row(children: [
                                const Icon(Icons.sort, size: 21),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        catalogSortLabels[provider.sort]!,
                                        maxLines: 2,
                                        style: const TextStyle(fontSize: 13)))
                              ]))))),
              Expanded(
                  child: TextButton.icon(
                      onPressed: () => showCatalogFilters(context, provider),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.mainText,
                          textStyle: const TextStyle(fontSize: 13),
                          minimumSize: const Size(0, 48)),
                      icon: const Icon(Icons.tune, size: 21),
                      label: Text(
                          'Фильтры${provider.filters.count > 0 ? ' (${provider.filters.count})' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis))),
              const SizedBox(width: 8),
            ]),
            const Divider(height: 1, color: AppColors.border),
            if (facets.isNotEmpty)
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(children: [
                        for (final facet in facets.entries.take(8))
                          Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                  backgroundColor: (provider.filters
                                              .values[facet.key]?.isNotEmpty ??
                                          false)
                                      ? const Color(0xFFE2EED2)
                                      : AppColors.background,
                                  side: BorderSide.none,
                                  shape: const StadiumBorder(),
                                  label: Text(facet.value.$1,
                                      style: const TextStyle(fontSize: 12)),
                                  onPressed: () => showCatalogFilters(
                                      context, provider,
                                      facet: facet.key))),
                      ]))),
          ],
          Expanded(
              child: ColoredBox(
                  color:
                      provider.browsing ? Colors.white : AppColors.background,
                  child: provider.browsing && provider.error.isEmpty
                      ? CatalogSubsectionsView(provider: provider)
                      : provider.isLoading && products.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : provider.error.isNotEmpty
                              ? Center(
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                      const Text('Не удалось загрузить товары'),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                          onPressed: provider.retry,
                                          child: const Text('Повторить'))
                                    ]))
                              : products.isEmpty
                                  ? _CatalogEmptyState(provider: provider)
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                      final width =
                                          (constraints.maxWidth - 30) / 2;
                                      final imageHeight =
                                          width < 230 ? width * 1.05 : 230.0;
                                      final scale =
                                          MediaQuery.textScalerOf(context)
                                              .scale(1);
                                      final height = imageHeight +
                                          161 +
                                          (scale - 1).clamp(0, 3) * 86;
                                      return CustomScrollView(
                                          key: ValueKey(
                                              '${provider.selectedCategory?.id}:${provider.filters}:${provider.sort}'),
                                          slivers: [
                                            if (!provider.isLoading)
                                              SliverToBoxAdapter(
                                                  child: Padding(
                                                      padding: const EdgeInsets
                                                          .fromLTRB(
                                                          12, 4, 12, 0),
                                                      child: Text(
                                                          '${provider.total} товаров',
                                                          style: const TextStyle(
                                                              fontSize: 11,
                                                              color: AppColors
                                                                  .mainText)))),
                                            SliverPadding(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                sliver: SliverGrid(
                                                    gridDelegate:
                                                        SliverGridDelegateWithFixedCrossAxisCount(
                                                            crossAxisCount: 2,
                                                            crossAxisSpacing:
                                                                10,
                                                            mainAxisSpacing: 10,
                                                            mainAxisExtent:
                                                                height),
                                                    delegate: SliverChildBuilderDelegate(
                                                        (context, index) =>
                                                            ProductPreviewCard(
                                                                product:
                                                                    products[
                                                                        index],
                                                                imageHeight:
                                                                    imageHeight,
                                                                showStorePrice:
                                                                    true,
                                                                catalogLayout:
                                                                    true),
                                                        childCount:
                                                            products.length))),
                                            if (provider.hasMore)
                                              SliverToBoxAdapter(
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      child: OutlinedButton(
                                                          onPressed:
                                                              provider.loadMore,
                                                          child: Text(
                                                              'Показать ещё (${provider.total - products.length})')))),
                                            const SliverToBoxAdapter(
                                                child: SizedBox(height: 12)),
                                          ]);
                                    }))),
        ]));
  }
}

class _CatalogEmptyState extends StatelessWidget {
  const _CatalogEmptyState({required this.provider});
  final ProductProvider provider;
  @override
  Widget build(BuildContext context) {
    final filtered = provider.filters.count > 0;
    return Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DecoratedBox(
                      decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Icon(
                              filtered
                                  ? Icons.search_off_outlined
                                  : Icons.inventory_2_outlined,
                              size: 36,
                              color: AppColors.primaryAccent))),
                  const SizedBox(height: 20),
                  Text(filtered ? 'Ничего не нашлось' : 'Пока нет товаров',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainText)),
                  const SizedBox(height: 10),
                  Text(
                      filtered
                          ? 'Попробуйте убрать часть фильтров или посмотреть другие разделы каталога.'
                          : 'В этом разделе пока пусто. Посмотрите другие разделы — там может быть то, что вы ищете.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.secondaryText, height: 1.5)),
                  const SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: filtered
                              ? () =>
                                  provider.applyFilters(const CatalogFilters())
                              : provider.clearCategory,
                          child: Text(filtered
                              ? 'Сбросить фильтры'
                              : 'Перейти в каталог'))),
                  if (filtered)
                    TextButton(
                        onPressed: provider.clearCategory,
                        child: const Text('Другие разделы')),
                ]))));
  }
}
