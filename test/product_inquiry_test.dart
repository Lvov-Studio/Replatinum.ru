import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/ui/widgets/product_purchase_sheets.dart';

class InquiryApi extends ApiService {
  int attempts = 0;
  String? id, phone, name, comment;
  final first = Completer<void>();
  @override
  Future<void> submitProductInquiry(
      {required String productId,
      required String productName,
      required String name,
      required String phone,
      required String comment}) async {
    attempts++;
    id = productId;
    this.phone = phone;
    this.name = name;
    this.comment = comment;
    if (attempts == 1) await first.future;
  }
}

void main() {
  test('inquiry uses website handler and refuses unconfirmed delivery',
      () async {
    final client = Dio();
    var accepted = false;
    RequestOptions? captured;
    client.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      captured = options;
      handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'success': accepted}));
    }));
    final api = ApiService(client: client);
    Future<void> send() => api.submitProductInquiry(
        productId: '1713',
        productName: 'SKU 256',
        name: 'Тест',
        phone: '9000000000',
        comment: 'Test');
    await expectLater(send(), throwsException);
    expect(captured!.uri.toString(),
        'https://replatinum.ru/local/ajax/preorder.php');
    expect(captured!.data['productId'], 1713);
    expect(captured!.data['productTitle'], 'SKU 256');
    expect(captured!.contentType, Headers.jsonContentType);
    accepted = true;
    await send();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'order sheet validates, prevents duplicates, reports failure and retries at font $scale',
        (tester) async {
      tester.view.physicalSize = const Size(640, 1600);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final api = InquiryApi();
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showProductOrderSheet(context,
                          productId: '1713',
                          productName: 'Смартфон выбранный вариант 256 ГБ',
                          productImage: '',
                          apiService: api),
                      child: const Text('Открыть'))))));
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('Позвонить в магазин'), findsNothing);
      await tester.ensureVisible(find.text('Заказать товар'));
      await tester.tap(find.text('Заказать товар'));
      await tester.pumpAndSettle();
      expect(api.attempts, 0);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Тест');
      await tester.enterText(fields.at(1), '+7 (900) 000-00-00');
      await tester.enterText(fields.at(2), 'Проверка');
      await tester.ensureVisible(find.text('Заказать товар'));
      await tester.tap(find.text('Заказать товар'));
      await tester.pump();
      expect(api.id, '1713');
      expect(api.phone, '9000000000');
      expect(api.comment, 'Проверка');
      expect(find.text('Отправляем…'), findsOneWidget);
      expect(api.attempts, 1);
      api.first.completeError(Exception('Telegram unavailable'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Заявка не отправлена'), findsOneWidget);
      await tester.ensureVisible(find.text('Заказать товар'));
      await tester.tap(find.text('Заказать товар'));
      await tester.pumpAndSettle();
      expect(api.attempts, 2);
      expect(find.textContaining('Заявка отправлена.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductInquiryForm), findsNothing);
    });
  }
}
