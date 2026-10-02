import 'package:platinumstore_app/ui/widgets/buyer_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/ui/screens/info_screens.dart';
import 'package:platinumstore_app/ui/screens/service_tradein_screens.dart';

void main() {
  final bannerHeights = <(double, double), double>{};
  final screens = <String, Widget>{
    'Сервисный центр': const ServiceScreen(),
    'Trade-in': const TradeInScreen(),
    'Рассрочка и кредит': const CreditScreen(),
    'Доставка': const DeliveryScreen(),
    'Гарантия': const WarrantyScreen(),
    'Контакты': const ContactsScreen(),
  };
  for (final size in [(320.0, 1.0), (360.0, 2.0), (600.0, 1.0)]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key}: header, complete scroll and back at $size',
          (tester) async {
        tester.view.physicalSize = Size(size.$1, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(size.$2)),
                child: child!),
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => entry.value)),
                        child: const Text('Открыть'))))));
        await tester.tap(find.text('Открыть'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final bar = tester.widget<AppBar>(find.byType(AppBar));
        expect(bar.backgroundColor, Colors.white);
        expect(bar.titleTextStyle!.color, isNot(Colors.white));
        expect(find.byType(BackButton), findsOneWidget);
        final hero = find.byType(BuyerHero);
        expect(hero, findsOneWidget);
        final heroSize = tester.getSize(hero);
        final expectedHeight =
            bannerHeights.putIfAbsent(size, () => heroSize.height);
        expect(heroSize.height, closeTo(expectedHeight, 0.1));
        expect(tester.getTopLeft(hero).dx, 16);
        expect(heroSize.width, size.$1 - 32);
        final barBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
        expect(tester.getTopLeft(hero).dy - barBottom, closeTo(16, 0.1));

        final list = find.byType(ListView).first;
        if (entry.value is CreditScreen) {
          for (final title in [
            'Виды рассрочки в replatinum',
            'Условия рассрочки',
            'Почему цена отличается?',
            'Кредит',
            'Досрочное погашение'
          ]) {
            await tester.scrollUntilVisible(find.text(title), 400,
                scrollable: find.byType(Scrollable).first);
            await tester.ensureVisible(find.text(title));
            await tester.pumpAndSettle();
            await tester.tap(find.text(title));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(find.text(title));
            await tester.pumpAndSettle();
            await tester.tap(find.text(title));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }

        var last = -1.0;
        for (var i = 0; i < 30; i++) {
          await tester.drag(list, const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final scrollable = tester.state<ScrollableState>(find
              .descendant(of: list, matching: find.byType(Scrollable))
              .first);
          final position = scrollable.position.pixels;
          if (position == last) break;
          last = position;
        }
        if (entry.value is ServiceScreen || entry.value is TradeInScreen) {
          final button = find.widgetWithText(
              ElevatedButton,
              entry.value is ServiceScreen
                  ? 'Отправить заявку'
                  : 'Рассчитать стоимость');
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.text('Укажите модель'), findsOneWidget);
          expect(find.text('Укажите телефон'), findsOneWidget);
          await tester.enterText(find.byType(TextFormField).last, '9041974295');
          expect(find.text('+7 (904) 197-42-95'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Открыть'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
