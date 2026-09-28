import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../screens/main_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.darkAccent,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: true,
      leadingWidth: 60,
      leading: Padding(
        // Отступ от левого края экрана
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        child: IconButton(
          tooltip: 'Открыть меню',
          onPressed: () => MainScreen.scaffoldKey.currentState?.openDrawer(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
        ),
      ),
      title: RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          children: [
            TextSpan(text: 're', style: TextStyle(color: Colors.white)),
            TextSpan(
                text: 'platinum',
                style: TextStyle(color: AppColors.primaryAccent)),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, color: Colors.white),
          onPressed: () async {
            final Uri url = Uri(scheme: 'tel', path: '+79180072333');
            try {
              await launchUrl(url);
            } catch (_) {
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
