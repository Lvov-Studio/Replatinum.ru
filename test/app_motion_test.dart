import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/models/banner_model.dart';
import 'package:platinumstore_app/ui/widgets/banner_slider.dart';
import 'package:platinumstore_app/ui/widgets/navigation_tab_surface.dart';
import 'package:platinumstore_app/ui/widgets/product_thumbnail.dart';

class MotionApi extends ApiService {
  @override
  Future<List<BannerModel>> getBanners() async => [
        for (final id in ['first', 'second'])
          BannerModel(
              id: id,
              title: id,
              subtitle: '',
              image: '',
              mobileImage: '',
              bgImage: '',
              link: '/catalog/',
              badge: ''),
      ];
}

void main() {
  testWidgets('hidden and background banners pause without changing selection',
      (tester) async {
    final api = MotionApi();
    Future<void> render(bool active) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: TickerMode(
                  enabled: active, child: BannerSlider(apiService: api)))));
      await tester.pumpAndSettle();
    }

    await render(false);
    expect(
        tester
            .widget<CarouselSlider>(find.byType(CarouselSlider))
            .options
            .autoPlay,
        isFalse);
    await tester.pump(const Duration(seconds: 6));
    expect(find.byKey(const ValueKey('banner-first')).hitTestable(),
        findsOneWidget);
    await render(true);
    expect(
        tester
            .widget<CarouselSlider>(find.byType(CarouselSlider))
            .options
            .autoPlay,
        isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(
        tester
            .widget<CarouselSlider>(find.byType(CarouselSlider))
            .options
            .autoPlay,
        isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(
        tester
            .widget<CarouselSlider>(find.byType(CarouselSlider))
            .options
            .autoPlay,
        isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tab feedback is interruptible and respects Remove animations',
      (tester) async {
    var taps = 0;
    Future<void> render({required bool selected, bool reduced = false}) async {
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(
                  body: SizedBox(
                      width: 100,
                      height: 60,
                      child: NavigationTabSurface(
                          selected: selected,
                          color: Colors.green,
                          onTap: () => taps++,
                          child: const Center(child: Text('Каталог'))))))));
    }

    await render(selected: false);
    await render(selected: true);
    await tester.pump(const Duration(milliseconds: 70));
    await tester.tap(find.text('Каталог'));
    await render(selected: false);
    await tester.tap(find.text('Каталог'));
    expect(taps, 2);
    await render(selected: true, reduced: true);
    expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('thumbnail decode sizes follow pixel density with a bounded budget', () {
    expect(ProductThumbnail.decodeSize(48, 3), 192);
    expect(ProductThumbnail.decodeSize(190, 3), 576);
    expect(ProductThumbnail.decodeSize(2000, 3), 1024);
  });
}
