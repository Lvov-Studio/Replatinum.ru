import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/category_model.dart';

class CatalogCategoryList extends StatelessWidget {
  const CatalogCategoryList({
    super.key,
    required this.categories,
    required this.onSelected,
  });

  final List<Category> categories;
  final ValueChanged<Category> onSelected;

  @override
  Widget build(BuildContext context) => ListView.separated(
        key: const PageStorageKey('catalog-category-list'),
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, thickness: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final category = categories[index];
          return Material(
            color: Colors.white,
            child: InkWell(
              key: ValueKey('catalog-category-${category.id}'),
              onTap: () => onSelected(category),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: category.image.isEmpty
                              ? const Icon(Icons.category_outlined,
                                  color: AppColors.secondaryText, size: 30)
                              : CachedNetworkImage(
                                  imageUrl: category.image,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) =>
                                      const SizedBox.shrink(),
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.category_outlined,
                                      color: AppColors.secondaryText,
                                      size: 30),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(category.name,
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mainText)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.chevron_right,
                          size: 20, color: AppColors.secondaryText),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
