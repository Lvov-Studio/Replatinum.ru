import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/providers/credit_inquiry_controller.dart';
import 'package:platinumstore_app/ui/widgets/product_credit_sheet.dart';

class CreditApi extends ApiService {
  int attempts = 0;
  final pending = Completer<void>();
  String? id, phone;
  int? term;
  @override
  Future<void> submitCreditInquiry(
      {required String productId,
      required String productName,
      required String productUrl,
      required num price,
      required int months,
      required String name,
      required String phone}) async {
    attempts++;
    id = productId;
    this.phone = phone;
    term = months;
    if (attempts == 1) await pending.future;
  }
}

void main() {
  group('Credit inquiry', () {
    test('should submit website credit fields and require explicit acceptance',
        () async {
      final dio = Dio();
      addTearDown(dio.close);
      var accepted = false;
      RequestOptions? request;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        request = options;
        handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': accepted}));
      }));
      final api = ApiService(client: dio);
      Future<void> send() => api.submitCreditInquiry(
          productId: '1713',
          productName: 'SKU 256 ГБ',
          productUrl: 'https://replatinum.ru/catalog/phone/#sku=1713',
          price: 181190,
          months: 12,
          name: 'Тест',
          phone: '9000000000');
      await expectLater(send(), throwsA(isA<FormatException>()));
      expect(request!.uri.toString(),
          'https://replatinum.ru/local/ajax/credit_order.php');
      expect(request!.data, {
        'productId': 1713,
        'productTitle': 'SKU 256 ГБ',
        'productUrl': 'https://replatinum.ru/catalog/phone/#sku=1713',
        'productPrice': 181190,
        'creditPeriod': 12,
        'purchasePlace': 'store',
        'firstName': 'Тест',
        'phone': '9000000000',
      });
      expect(request!.contentType, Headers.jsonContentType);
      expect(request!.receiveTimeout, const Duration(seconds: 60));
      accepted = true;
      await send();
    });
    test(
        'should validate term, prevent duplicates and keep a disposed controller quiet',
        () async {
      final api = CreditApi();
      final c = CreditInquiryController(
          productId: '1713',
          productName: 'SKU',
          productUrl: '',
          price: 181190,
          api: api);
      expect(c.months, isNull);
      c.select(5);
      expect(c.months, isNull);
      await c.submit(name: '', phone: '9000000000');
      expect(api.attempts, 0);
      c.select(24);
      expect(c.payment(24), 7550);
      final sending = c.submit(name: '', phone: '8 (900) 000-00-00');
      await c.submit(name: '', phone: '9000000000');
      expect(api.attempts, 1);
      expect(api.phone, '9000000000');
      c.dispose();
      api.pending.complete();
      await sending;
    });
    for (final (width, scale) in [(320.0, 1.0), (360.0, 2.0), (600.0, 1.0)]) {
      testWidgets(
          'should select term, validate, retry and preserve SKU at $width / $scale',
          (tester) async {
        tester.view.physicalSize = Size(width * 2, 1800);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final api = CreditApi();
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => showProductCreditSheet(context,
                            productId: '1713',
                            productName:
                                'Смартфон Apple iPhone 18 Pro Max 256 ГБ чёрный (eSim)',
                            productUrl:
                                'https://replatinum.ru/catalog/phone/#sku=1713',
                            price: 181190,
                            apiService: api),
                        child: const Text('Открыть'))))));
        await tester.tap(find.text('Открыть'));
        await tester.pumpAndSettle();
        final apply = find.text('Оформить заявку');
        await tester.ensureVisible(apply);
        await tester.tap(apply);
        await tester.pump();
        expect(find.text('Ваши данные'), findsNothing);
        await tester.ensureVisible(find.text('12 мес.'));
        await tester.tap(find.text('12 мес.'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(apply);
        await tester.tap(apply);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Отправить заявку'));
        await tester.tap(find.text('Отправить заявку'));
        await tester.pumpAndSettle();
        expect(api.attempts, 0);
        await tester.enterText(find.byType(TextFormField).at(0), 'Тест');
        await tester.enterText(
            find.byType(TextFormField).at(1), '+7 (900) 000-00-00');
        await tester.ensureVisible(find.text('Отправить заявку'));
        await tester.tap(find.text('Отправить заявку'));
        await tester.pump();
        expect(api.id, '1713');
        expect(api.phone, '9000000000');
        expect(api.term, 12);
        expect(find.text('Отправляем…'), findsOneWidget);
        api.pending.completeError(Exception('Server unavailable'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Не удалось подтвердить'), findsOneWidget);
        await tester.ensureVisible(find.text('Отправить заявку'));
        await tester.tap(find.text('Отправить заявку'));
        await tester.pumpAndSettle();
        expect(find.text('Заявка принята'), findsOneWidget);
        expect(api.attempts, 2);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
