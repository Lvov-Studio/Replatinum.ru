import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'saved_products_shortcuts.dart';

/// A single scroll surface: shortcuts fade away while search stays pinned.
class SliverHomeHeader extends StatelessWidget {
  const SliverHomeHeader({
    super.key,
    required this.onMenu,
    required this.onSearch,
    this.displayName,
  });

  final VoidCallback onMenu;
  final VoidCallback onSearch;
  // Only pass a name supplied by an authenticated profile, never form history.
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeHeaderDelegate(
        topInset: MediaQuery.paddingOf(context).top,
        expandedHeight: 192 + (scale - 1).clamp(0, 2) * 112,
        greetingHeight: 52 + (scale - 1).clamp(0, 2) * 32,
        searchHeight: 64 + (scale - 1).clamp(0, 2) * 20,
        reduceMotion: MediaQuery.disableAnimationsOf(context),
        displayName: displayName,
        onMenu: onMenu,
        onSearch: onSearch,
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({
    required this.topInset,
    required this.expandedHeight,
    required this.greetingHeight,
    required this.searchHeight,
    required this.reduceMotion,
    required this.displayName,
    required this.onMenu,
    required this.onSearch,
  });

  final double topInset;
  final double expandedHeight;
  final double greetingHeight;
  final double searchHeight;
  final bool reduceMotion;
  final String? displayName;
  final VoidCallback onMenu;
  final VoidCallback onSearch;
  static const _dark = Color(0xFF1E1E26);

  @override
  double get minExtent => topInset + searchHeight;
  @override
  double get maxExtent => minExtent + expandedHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / expandedHeight).clamp(0.0, 1.0);
    // Finish fading before the dark surface becomes too pale for white text.
    final opacity = reduceMotion
        ? (progress < .4 ? 1.0 : 0.0)
        : (1 - progress / .65).clamp(0.0, 1.0);
    final background = reduceMotion
        ? (progress < .4 ? _dark : AppColors.background)
        : Color.lerp(_dark, AppColors.background, progress)!;
    final menuProgress = reduceMotion
        ? (shrinkOffset <= 0 ? 0.0 : 1.0)
        : (shrinkOffset / 32).clamp(0.0, 1.0);
    final lightStatusSurface = reduceMotion ? progress >= .4 : progress >= .5;
    final name = displayName?.trim();
    final greeting = name == null || name.isEmpty
        ? 'Добро пожаловать!'
        : 'Здравствуйте, $name!';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            lightStatusSurface ? Brightness.dark : Brightness.light,
        statusBarBrightness:
            lightStatusSurface ? Brightness.light : Brightness.dark,
      ),
      child: ClipRect(
        child: ColoredBox(
          color: background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: topInset - shrinkOffset,
                left: 16,
                right: 16,
                height: expandedHeight,
                child: IgnorePointer(
                  ignoring: opacity < .25,
                  child: ExcludeSemantics(
                    excluding: opacity < .25,
                    child: Opacity(
                      key: const ValueKey('home-header-fade'),
                      opacity: opacity,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: Column(
                          children: [
                            SizedBox(
                              height: greetingHeight,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(greeting,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ),
                                  const SizedBox(width: 8),
                                  IgnorePointer(
                                    ignoring: menuProgress >= .75,
                                    child: ExcludeSemantics(
                                      excluding: menuProgress >= .75,
                                      child: Opacity(
                                        opacity: 1 - menuProgress,
                                        child: IconButton(
                                          tooltip: 'Открыть меню',
                                          onPressed: onMenu,
                                          color: Colors.white,
                                          icon: const Icon(Icons.menu_rounded),
                                          constraints: const BoxConstraints(
                                              minHeight: 48, minWidth: 48),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Expanded(child: SavedProductsTiles()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: searchHeight,
                child: Material(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22 * (1 - progress))),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRect(
                          child: Align(
                            widthFactor: menuProgress,
                            child: IgnorePointer(
                              ignoring: menuProgress < .25,
                              child: ExcludeSemantics(
                                excluding: menuProgress < .25,
                                child: Opacity(
                                  opacity: menuProgress,
                                  child: IconButton(
                                    key: const ValueKey('home-collapsed-menu'),
                                    tooltip: 'Открыть меню',
                                    onPressed: onMenu,
                                    color: AppColors.mainText,
                                    icon: const Icon(Icons.menu_rounded),
                                    constraints: const BoxConstraints(
                                        minHeight: 48, minWidth: 48),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * menuProgress),
                        Expanded(
                          child: Material(
                            color: const Color(0xFFE8E8ED),
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: const ValueKey('home-search'),
                              onTap: onSearch,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Row(
                                  children: [
                                    Icon(Icons.search,
                                        color: AppColors.mainText, size: 23),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text('Поиск товаров',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: AppColors.mainText,
                                              fontSize: 15)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topInset,
                child: ColoredBox(color: background),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) =>
      topInset != oldDelegate.topInset ||
      expandedHeight != oldDelegate.expandedHeight ||
      greetingHeight != oldDelegate.greetingHeight ||
      searchHeight != oldDelegate.searchHeight ||
      reduceMotion != oldDelegate.reduceMotion ||
      displayName != oldDelegate.displayName ||
      onMenu != oldDelegate.onMenu ||
      onSearch != oldDelegate.onSearch;
}
