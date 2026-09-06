import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.darkAccent,
      centerTitle: true,
      leading: Builder(
        builder: (ctx) => IconButton(
          padding: const EdgeInsets.all(8),
          icon: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: RichText(
        text: const TextSpan(
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
          children: [
            TextSpan(text: 're', style: TextStyle(color: Colors.white)),
            TextSpan(text: 'platinum',
                style: TextStyle(color: AppColors.primaryAccent)),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, color: Colors.white),
          onPressed: () async {
            final Uri url = Uri(scheme: 'tel', path: '+78000000000');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Не удалось открыть набор номера')),
                );
              }
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
