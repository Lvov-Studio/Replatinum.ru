import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/api/api_service.dart';
import '../../data/models/banner_model.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final ApiService _apiService = ApiService();
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
    if (banner.link.isEmpty) return;
    final uri = Uri.tryParse('https://replatinum.ru')?.resolve(banner.link);
    if (uri == null ||
        uri.scheme != 'https' ||
        !const {'replatinum.ru', 'www.replatinum.ru'}.contains(uri.host)) {
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть страницу товара')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerModel>>(
      future: _bannersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 148,
            child: Center(child: CircularProgressIndicator()),
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
              itemCount: banners.length,
              options: CarouselOptions(
                height: 148,
                viewportFraction: 1,
                autoPlay: banners.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 450),
                onPageChanged: (index, _) {
                  setState(() => _currentIndex = index);
                },
              ),
              itemBuilder: (context, index, _) {
                final banner = banners[index];
                // The website uses MOBILE_IMAGE first, then PREVIEW_PICTURE.
                final imageUrl = banner.displayImage;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Material(
                    color: AppColors.darkAccent,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: banner.link.isEmpty
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
                                  width: constraints.maxWidth * 0.60,
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
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          height: 1.15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (banner.link.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryAccent,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 14),
                                            child: SizedBox(
                                              height: 38,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Купить',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.onPrimary,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      )),
                                                  SizedBox(width: 4),
                                                  Icon(Icons.arrow_forward,
                                                      size: 14,
                                                      color:
                                                          AppColors.onPrimary),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
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
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(banners.length, (index) {
                    final selected = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryAccent
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
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
