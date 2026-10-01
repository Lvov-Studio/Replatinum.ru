import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/product_provider.dart';
import '../../data/models/catalog_filter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/price_formatter.dart';

Future<void> showCatalogFilters(BuildContext context, ProductProvider provider,
    {String? facet}) async {
  final result = await showModalBottomSheet<CatalogFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      builder: (_) => FractionallySizedBox(
          heightFactor: .93,
          child: CatalogFilterSheet(provider: provider, facet: facet)));
  if (result != null && context.mounted) provider.applyFilters(result);
}

class CatalogFilterSheet extends StatefulWidget {
  const CatalogFilterSheet({super.key, required this.provider, this.facet});
  final ProductProvider provider;
  final String? facet;
  @override
  State<CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<CatalogFilterSheet> {
  late final TextEditingController _min, _max;
  late bool _available;
  late Map<String, Set<String>> _values;
  final Set<String> _expanded = {};
  @override
  void initState() {
    super.initState();
    final filters = widget.provider.filters;
    _min = TextEditingController(text: filters.minPrice?.toString() ?? '');
    _max = TextEditingController(text: filters.maxPrice?.toString() ?? '');
    _available = filters.availableOnly;
    _values = {
      for (final entry in filters.values.entries) entry.key: {...entry.value}
    };
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  CatalogFilters get _draft => CatalogFilters(
      minPrice: num.tryParse(_min.text),
      maxPrice: num.tryParse(_max.text),
      availableOnly: _available,
      values: _values);
  bool get _valid =>
      _min.text.isEmpty ||
      _max.text.isEmpty ||
      num.parse(_min.text) <= num.parse(_max.text);
  void _reset() => setState(() {
        _min.clear();
        _max.clear();
        _available = false;
        _values = {};
      });
  @override
  Widget build(BuildContext context) {
    final bounds = widget.provider.priceBounds;
    final facets = widget.provider.facets;
    final count = widget.provider.countMatching(_draft);
    final range = RangeValues(
        (num.tryParse(_min.text)?.toDouble() ?? bounds.$1)
            .clamp(bounds.$1, bounds.$2),
        (num.tryParse(_max.text)?.toDouble() ?? bounds.$2)
            .clamp(bounds.$1, bounds.$2));
    return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(children: [
          SizedBox(
              height: 56,
              child: Row(children: [
                const SizedBox(width: 48),
                Expanded(
                    child: Text(
                        widget.facet == null
                            ? 'Фильтры'
                            : facets[widget.facet]?.$1 ?? 'Фильтры',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
                IconButton(
                    tooltip: 'Закрыть фильтры',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ])),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
              child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                if (widget.facet == null) ...[
                  const SizedBox(height: 16),
                  const Text('Цена на сайте, ₽',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _priceInput(_min, 'От', bounds.$1)),
                    const SizedBox(width: 12),
                    Expanded(child: _priceInput(_max, 'До', bounds.$2))
                  ]),
                  if (!_valid)
                    const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Цена «До» должна быть не меньше цены «От»',
                            style: TextStyle(color: AppColors.error))),
                  if (bounds.$2 > bounds.$1)
                    SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.darkAccent,
                            inactiveTrackColor: AppColors.border,
                            thumbColor: Colors.white,
                            overlayColor: Colors.black12,
                            trackHeight: 3),
                        child: RangeSlider(
                            min: bounds.$1,
                            max: bounds.$2,
                            values: _valid
                                ? range
                                : RangeValues(bounds.$1, bounds.$2),
                            labels: RangeLabels('${range.start.round()} ₽',
                                '${range.end.round()} ₽'),
                            onChanged: (value) => setState(() {
                                  _min.text = '${value.start.round()}';
                                  _max.text = '${value.end.round()}';
                                }))),
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Только в наличии'),
                      value: _available,
                      onChanged: (value) =>
                          setState(() => _available = value ?? false)),
                  const Divider(height: 24, color: AppColors.border),
                ],
                for (final facet in facets.entries.where(
                    (f) => widget.facet == null || f.key == widget.facet)) ...[
                  Row(children: [
                    Expanded(
                        child: Text(facet.value.$1,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600))),
                    if (facet.value.$2.length > 6)
                      TextButton(
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryText),
                          onPressed: () => setState(() {
                                if (!_expanded.add(facet.key)) {
                                  _expanded.remove(facet.key);
                                }
                              }),
                          child: Text(_expanded.contains(facet.key)
                              ? 'Свернуть'
                              : 'Все ›'))
                  ]),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final value in facet.value.$2.take(
                        widget.facet != null || _expanded.contains(facet.key)
                            ? facet.value.$2.length
                            : 6))
                      FilterChip(
                          label: Text(value),
                          backgroundColor: AppColors.background,
                          selectedColor: const Color(0xFFE2EED2),
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                          selected:
                              _values[facet.key]?.contains(value) ?? false,
                          onSelected: (checked) => setState(() {
                                final selected = _values[facet.key] ??= {};
                                if (checked) {
                                  selected.add(value);
                                } else {
                                  selected.remove(value);
                                }
                              })),
                  ]),
                  const Divider(height: 36, color: AppColors.border),
                ],
              ])),
          const Divider(height: 1, color: AppColors.border),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryText),
                  onPressed: _reset,
                  child: const Text('Сбросить'))),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          onPressed: _valid
                              ? () => Navigator.pop(context, _draft)
                              : null,
                          child: Text('Показать товары ($count)',
                              maxLines: 1, overflow: TextOverflow.ellipsis))))),
        ]));
  }

  Widget _priceInput(
          TextEditingController controller, String label, double bound) =>
      TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9)
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 6),
                child: Text(label.toLowerCase(),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.secondaryText)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 32),
              hintText: formatPrice(bound).replaceAll(' ₽', ''),
              filled: true,
              fillColor: AppColors.background,
              border: const OutlineInputBorder()));
}
