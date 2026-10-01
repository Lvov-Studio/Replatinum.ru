import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/providers/saved_products_provider.dart';
import 'package:platinumstore_app/ui/widgets/sliver_home_header.dart';

void main() {
  group('SliverHomeHeader', () {
    for (final (width, scale) in [
      (320.0, 1.0),
      (320.0, 1.3),
      (360.0, 2.0),
      (600.0, 1.0),
    ]) {
      testWidgets(
          'should fade with scroll, pin search and restore shortcuts at $width / $scale',
          (tester) async {
        tester.view.physicalSize = Size(width * 2, 1600);
        tester.view.devicePixelRatio = 2;
        tester.view.padding = const FakeViewPadding(top: 48);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final controller = ScrollController();
        addTearDown(controller.dispose);
        var menuTaps = 0;
        var searchTaps = 0;
        final saved = SavedProductsProvider()..ready = true;
        addTearDown(saved.dispose);
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: saved,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CustomScrollView(controller: controller, slivers: [
                SliverHomeHeader(
                  onMenu: () => menuTaps++,
                  onSearch: () => searchTaps++,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 2000)),
              ]),
            ),
          ),
        ));
        expect(find.text('Добро пожаловать!'), findsOneWidget);
        expect(find.text('Нет товаров'), findsNWidgets(2));
        await tester.tap(find.text('Избранное'));
        await tester.pumpAndSettle();
        expect(find.text('Добавьте понравившиеся товары в избранное'),
            findsOneWidget);
        Navigator.of(tester.element(find.text('Избранное').first)).pop();
        await tester.pumpAndSettle();

        final initialSearchY =
            tester.getTopLeft(find.byKey(const ValueKey('home-search'))).dy;
        controller.jumpTo(50);
        await tester.pump();
        final fade = tester
            .widget<Opacity>(find.byKey(const ValueKey('home-header-fade')));
        expect(fade.opacity, inExclusiveRange(0, 1));
        expect(tester.getTopLeft(find.byKey(const ValueKey('home-search'))).dy,
            lessThan(initialSearchY));
        expect(tester.takeException(), isNull);

        for (final offset in [60.0, 75.0, 90.0]) {
          controller.jumpTo(offset);
          await tester.pump();
          final menu = find.byKey(const ValueKey('home-collapsed-menu'));
          expect(tester.getSize(menu).width, greaterThanOrEqualTo(48));
          await tester.tap(menu);
        }
        expect(menuTaps, 3);

        controller.jumpTo(500);
        await tester.pump();
        expect(
            tester
                .widget<Opacity>(find.byKey(const ValueKey('home-header-fade')))
                .opacity,
            0);
        final pinnedY =
            tester.getTopLeft(find.byKey(const ValueKey('home-search'))).dy;
        expect(pinnedY, greaterThanOrEqualTo(24));
        controller.jumpTo(800);
        await tester.pump();
        expect(tester.getTopLeft(find.byKey(const ValueKey('home-search'))).dy,
            pinnedY);
        await tester.tap(find.byKey(const ValueKey('home-collapsed-menu')));
        await tester.tap(find.byKey(const ValueKey('home-search')));
        expect(menuTaps, 4);
        expect(searchTaps, 1);
        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find
              .byWidgetPredicate(
                  (widget) => widget is AnnotatedRegion<SystemUiOverlayStyle>)
              .first,
        );
        expect(region.value.statusBarIconBrightness, Brightness.dark);

        controller.jumpTo(0);
        await tester.pump();
        expect(
            tester
                .widget<Opacity>(find.byKey(const ValueKey('home-header-fade')))
                .opacity,
            1);
        await tester.tap(find.text('Сравнение'));
        await tester.pumpAndSettle();
        expect(find.text('Добавьте товары для сравнения'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    testWidgets('should accept a verified name and honor reduced motion',
        (tester) async {
      final saved = SavedProductsProvider()..ready = true;
      final controller = ScrollController();
      addTearDown(saved.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: saved,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: CustomScrollView(controller: controller, slivers: [
                SliverHomeHeader(
                    displayName: 'Евгений', onMenu: () {}, onSearch: () {}),
                const SliverToBoxAdapter(child: SizedBox(height: 2000)),
              ]),
            ),
          ),
        ),
      ));
      expect(find.text('Здравствуйте, Евгений!'), findsOneWidget);
      controller.jumpTo(30);
      await tester.pump();
      expect(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('home-header-fade')))
              .opacity,
          1);
      controller.jumpTo(100);
      await tester.pump();
      expect(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('home-header-fade')))
              .opacity,
          0);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(find
          .byWidgetPredicate(
              (widget) => widget is AnnotatedRegion<SystemUiOverlayStyle>)
          .first);
      expect(region.value.statusBarIconBrightness, Brightness.dark);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
