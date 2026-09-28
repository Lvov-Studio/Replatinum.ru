import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../screens/main_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, this.collapsed = false});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1E1E26),
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: true,
      toolbarHeight: collapsed ? 0 : 56,
      leadingWidth: 72,
      leading: collapsed
          ? null
          : Padding(
              padding:
                  const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 16),
              child: IconButton(
                tooltip: 'Открыть меню',
                onPressed: () =>
                    MainScreen.scaffoldKey.currentState?.openDrawer(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
      title: collapsed
          ? null
          : RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 're', style: TextStyle(color: Colors.white)),
                  TextSpan(
                      text: 'platinum',
                      style: TextStyle(color: AppColors.primaryAccent)),
                ],
              ),
            ),
      actions: collapsed
          ? null
          : [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  tooltip: 'Позвонить',
                  icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
              ),
            ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(collapsed ? 0 : 56);
}
