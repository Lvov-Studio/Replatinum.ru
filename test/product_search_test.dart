import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/ui/screens/product_search_delegate.dart';

class PendingSearch extends ApiService {
  final calls = <String>[];
  final pending = <Completer<List<Product>>>[];
  @override
  Future<List<Product>> searchProducts(String query) {
    calls.add(query);
    final result = Completer<List<Product>>();
    pending.add(result);
    return result.future;
  }
}

void main() {
  test('website prices, thumbnails and model numbers are mapped correctly',
      () async {
    final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
    addTearDown(dio.close);
    var requests = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests++;
      expect(options.uri.path, '/local/ajax/search.php');
      expect(options.queryParameters['q'], '17 pro');
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'status': 'success',
        'corrected_query': '17 pro',
        'results': [
          {
            'id': '1451',
            'name': 'Фен HD17 Supersonic R Pro',
            'price': 'По запросу'
          },
          {
            'id': '1621',
            'name': 'Apple iPhone 17 Pro',
            'price': '98 990 ₽',
            'image': '/upload/phone.webp'
          },
          {
            'id': '1596',
            'name': 'Apple iPhone 17 Pro Max',
            'price': '104\u00a0990 ₽',
            'image': 'https://replatinum.ru/max.webp'
          },
          {
            'id': '2276',
            'name': 'Apple iPhone 17 Pro Max 2 ТБ',
            'price': 146990
          },
          {'id': '2276', 'name': 'Duplicate', 'price': 1},
          {'id': 'other', 'name': 'Apple iPhone 117 Pro', 'price': 99},
          {
            'id': 'zero',
            'name': 'Apple iPhone 17 Pro special',
            'price': 'По запросу'
          },
        ]
      }));
    }));
    final api = ApiService(client: dio);
    expect(await api.searchProducts(' a '), isEmpty);
    final results = await api.searchProducts(' 17   pro ');
    expect(requests, 1);
    expect(results.map((p) => p.id), ['1621', '1596', '2276', 'zero']);
    expect(results.map((p) => p.price), [98990, 104990, 146990, 0]);
    expect(results.first.image, 'https://replatinum.ru/upload/phone.webp');
    expect(results.last.offerId, 'zero');
  });

  test('uses the server corrected query for Russian synonyms', () async {
    final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
    addTearDown(dio.close);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.queryParameters['q'], 'айфон 17 про');
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'status': 'success',
        'corrected_query': 'iPhone 17 Pro',
        'results': [
          {'id': '1', 'name': 'Apple iPhone 17 Pro', 'price': '98 990 ₽'},
        ]
      }));
    }));
    expect(
        (await ApiService(client: dio).searchProducts('айфон 17 про'))
            .single
            .price,
        98990);
  });

  testWidgets('debounce clears old results and ignores old responses',
      (tester) async {
    final api = PendingSearch();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showSearch(
                        context: context,
                        delegate: ProductSearchDelegate(apiService: api)),
                    child: const Text('Search'))))));
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '17 pro');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump();
    expect(api.calls, ['17 pro']);
    await tester.enterText(find.byType(TextField), 'iphone');
    await tester.pump();
    api.pending.first.complete(
        [Product(id: 'old', name: 'OLD RESULT', price: 1, image: '')]);
    await tester.pump();
    expect(find.text('OLD RESULT'), findsNothing);
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump();
    api.pending.last.complete(
        [Product(id: 'new', name: 'NEW RESULT', price: 0, image: '')]);
    await tester.pumpAndSettle();
    expect(find.text('NEW RESULT'), findsOneWidget);
    expect(find.text('Под заказ'), findsOneWidget);
    expect(find.text('0 ₽'), findsNothing);
    await tester.enterText(find.byType(TextField), 'i');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('NEW RESULT'), findsNothing);
    expect(api.calls, ['17 pro', 'iphone']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search errors show retry without internal exception text',
      (tester) async {
    final api = PendingSearch();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showSearch(
                        context: context,
                        delegate: ProductSearchDelegate(apiService: api)),
                    child: const Text('Search'))))));
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '17 pro');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump();
    api.pending.first.completeError(Exception('private backend details'));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить результаты'), findsOneWidget);
    expect(find.textContaining('private backend'), findsNothing);
    await tester.tap(find.text('Повторить'));
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump();
    api.pending.last.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });
}
