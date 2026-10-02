import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProductBadge extends StatelessWidget {
  const ProductBadge(this.label, {super.key});
  final String label;
  String get _text => switch (label.trim().toLowerCase()) {
        'хит' || 'хит продаж' => 'Хит',
        'новинка' => 'Новинка',
        'акция' => 'Акция',
        _ => label,
      };
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          color: AppColors.primaryAccent.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(4)),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(_text,
              style:
                  const TextStyle(fontSize: 9, color: AppColors.primaryText))));
}
