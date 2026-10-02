import '../../../ui/screens/main_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AccountMenuTile extends StatelessWidget {
  const AccountMenuTile(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            DecoratedBox(
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F4EA),
                    borderRadius: BorderRadius.circular(12)),
                child: SizedBox.square(
                    dimension: 40,
                    child: Icon(icon, size: 22, color: AppColors.primaryText))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.secondaryText))
                  ],
                ])),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.secondaryText),
          ])));
}

class AccountSectionCard extends StatelessWidget {
  const AccountSectionCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border)),
      child: child);
}

class AccountMenuDivider extends StatelessWidget {
  const AccountMenuDivider({super.key});
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 16,
      color: AppColors.border);
}

void openAccountCatalog(BuildContext context) {
  final main = MainScreen.of(context);
  if (main == null) return;
  Navigator.of(context).popUntil((route) => route.isFirst);
  main.switchToCatalog();
}

class AccountEmptyState extends StatelessWidget {
  const AccountEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Center(
      child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F4EA),
                        borderRadius: BorderRadius.circular(22)),
                    child: Icon(icon, size: 32, color: AppColors.primaryText)),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.secondaryText)),
                if (MainScreen.of(context) != null) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                      onPressed: () => openAccountCatalog(context),
                      child: const Text('Перейти в каталог')),
                ],
              ]))));
}

InputDecoration accountFieldDecoration(String label) => InputDecoration(
      labelText: label,
      counterText: '',
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
    );
