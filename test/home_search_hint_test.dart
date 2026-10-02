import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/ui/widgets/home_search_hint.dart';

void main() {
  testWidgets('types, holds, erases and moves to the next website phrase',
      (tester) async {
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: HomeSearchHint())));
    expect(find.text('Поиск товаров'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('S'), findsOneWidget);
    final first = HomeSearchHint.phrases.first;
    for (var i = 1; i < first.length; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.text(first), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.text(first), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text(first.substring(0, first.length - 1)), findsOneWidget);
    for (var i = 1; i < first.length; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('A'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
  testWidgets('stops on a hidden tab and honors reduced motion',
      (tester) async {
    Future<void> render({bool enabled = true, bool reduce = false}) =>
        tester.pumpWidget(MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduce),
                child: TickerMode(
                    enabled: enabled,
                    child: const Scaffold(body: HomeSearchHint())))));
    await render();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('S'), findsOneWidget);
    await render(enabled: false);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Поиск товаров'), findsOneWidget);
    await render();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Sa'), findsOneWidget);
    await render(reduce: true);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Поиск товаров'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
