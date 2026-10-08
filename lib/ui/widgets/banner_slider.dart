import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/api/api_service.dart';
import '../../data/models/banner_model.dart';
import '../../data/banner_destination.dart';
import '../screens/banner_catalog_screen.dart';
import '../screens/info_screens.dart';
import '../screens/main_screen.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  late final ApiService _apiService = widget.apiService ?? ApiService();
  final _carousel = CarouselSliderController();
  bool _opening = false;
  late Future<List<BannerModel>> _bannersFuture;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _bannersFuture = _apiService.getBanners();
  }

  void _retry() {
    setState(() {
      _currentIndex = 0;
      _bannersFuture = _apiService.getBanners();
    });
  }

  Future<void> _openBanner(BannerModel banner) async {
    final destination = BannerDestination.resolve(banner);
    if (destination == null || _opening) return;
    setState(() => _opening = true);
    try {
      if (destination.kind == BannerDestinationKind.newStore) {
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const ContactsScreen(highlightNewStore: true)));
      } else if (destination.kind == BannerDestinationKind.catalog) {
        if (destination.categoryCode == null) {
          MainScreen.of(context)?.switchToCatalog();
        } else {
          await Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => BannerCatalogScreen(
                  destination: destination, apiService: _apiService)));
        }
      } else {
        final opened = await launchUrl(destination.uri,
            mode: LaunchMode.externalApplication);
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось открыть страницу')));
        }
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final height = 144.0 +
        (MediaQuery.textScalerOf(context).scale(17) - 17).clamp(0, 34) * 7;
    return FutureBuilder<List<BannerModel>>(
      future: _bannersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _BannerFailure(onRetry: _retry);
        }

        final banners = snapshot.data ?? const <BannerModel>[];
        if (banners.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            CarouselSlider.builder(
              carouselController: _carousel,
              itemCount: banners.length,
              options: CarouselOptions(
                height: height,
                viewportFraction: 1,
                autoPlay: banners.length > 1 && !reducedMotion && !_opening,
                enableInfiniteScroll: banners.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 450),
                onPageChanged: (index, _) {
                  setState(() => _currentIndex = index);
                },
              ),
              itemBuilder: (context, index, _) {
                final banner = banners[index];
                final destination = BannerDestination.resolve(banner);
                // The website uses MOBILE_IMAGE first, then PREVIEW_PICTURE.
                final imageUrl = banner.displayImage;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Material(
                    color: AppColors.darkAccent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('banner-${banner.id}'),
                      onTap: destination == null
                          ? null
                          : () => _openBanner(banner),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment.centerRight,
                              errorWidget: (_, __, ___) =>
                                  const ColoredBox(color: AppColors.darkAccent),
                            ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xF01A1A22),
                                  Color(0xB81A1A22),
                                  Color(0x001A1A22),
                                ],
                                stops: [0, 0.55, 1],
                              ),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: constraints.maxWidth * 0.64,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (banner.badge.isNotEmpty) ...[
                                        Text(
                                          banner.badge.toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.primaryAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        banner.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (destination != null) ...[
                                        const SizedBox(height: 12),
                                        Row(children: [
                                          Flexible(
                                              child: Text(
                                                  destination.actionLabel,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      height: 1.3))),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.arrow_forward,
                                              size: 14, color: Colors.white),
                                        ]),
                                      ],
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
                );
              },
            ),
            if (banners.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: List.generate(banners.length, (index) {
                    final selected = index == _currentIndex;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label:
                          'Баннер ${index + 1} из ${banners.length}: ${banners[index].title}',
                      child: InkWell(
                        key: ValueKey('banner-dot-$index'),
                        onTap: () {
                          if (reducedMotion) {
                            _carousel.jumpToPage(index);
                          } else {
                            _carousel.animateToPage(index,
                                duration: const Duration(milliseconds: 250));
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 40,
                          height: 44,
                          child: Center(
                              child: AnimatedContainer(
                            duration: reducedMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            width: selected ? 18 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primaryAccent
                                    : AppColors.secondaryText,
                                borderRadius: BorderRadius.circular(3)),
                          )),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BannerFailure extends StatelessWidget {
  const _BannerFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 144,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Не удалось загрузить баннеры'),
              TextButton(onPressed: onRetry, child: const Text('Повторить')),
            ],
          ),
        ),
      ),
    );
  }
}
