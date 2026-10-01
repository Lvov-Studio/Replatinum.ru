import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_colors.dart';

class CatalogSubsectionsView extends StatelessWidget {
  const CatalogSubsectionsView({super.key, required this.provider});
  final ProductProvider provider;
  @override
  Widget build(BuildContext context) => ListView(children: [
        Material(
            color: Colors.white,
            child: ListTile(
                minTileHeight: 64,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Смотреть все',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: provider.openSubsection)),
        const Divider(height: 1, color: AppColors.border),
        for (final node in provider.subsections) ...[
          Material(
              color: Colors.white,
              child: ExpansionTile(
                  key: PageStorageKey(node.path),
                  minTileHeight: 64,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  textColor: AppColors.mainText,
                  iconColor: AppColors.secondaryText,
                  leading: SizedBox(
                      width: 48,
                      height: 48,
                      child: provider.imageOf(node).isEmpty
                          ? const Icon(Icons.category_outlined)
                          : CachedNetworkImage(
                              imageUrl: provider.imageOf(node),
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.category_outlined))),
                  title: Text(node.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  children: [
                    Material(
                        color: AppColors.background,
                        child: Column(children: [
                          _model('Смотреть все модели',
                              () => provider.openSubsection(node)),
                          for (final child in provider.childrenOf(node)) ...[
                            const Padding(
                                padding: EdgeInsets.only(left: 24),
                                child: Divider(
                                    height: 1, color: AppColors.border)),
                            _model(child.title,
                                () => provider.openSubsection(child)),
                          ],
                        ]))
                  ])),
          const Divider(height: 1, color: AppColors.border),
        ],
      ]);
  Widget _model(String title, VoidCallback onTap) => ListTile(
      minTileHeight: 48,
      contentPadding: const EdgeInsets.only(left: 24, right: 16),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: onTap);
}
