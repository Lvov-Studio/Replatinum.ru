import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/data/api/api_service.dart';

Map<String, dynamic> item(String model, String offer) => {
      'id': model,
      'offer_id': offer,
      'name': 'Phone $offer',
      'price': 123,
      'store_price': 150,
      'can_buy': true,
      'image': '',
      'path': '/catalog/smartfony/iphone/phone/',
      'rustore_warning': true,
      'model_specs': [
        {'code': 'MEMORY', 'name': 'Память', 'value': 'Модель'}
      ],
      'specs': [
        {'code': 'MEMORY', 'name': 'Память', 'value': '256 ГБ'}
      ],
    };

Map<String, dynamic> page(
        {int next = 8, int total = 9, bool complete = false}) =>
    {
      'status': 'success',
      'schema_version': 1,
      'data': [
        for (var id = next == 8 ? 1 : next; id <= next; id++)
          item('$id', 'sku-$id')
      ],
      'total_models': total,
      'next_offset': next,
      'complete': complete,
    };

void main() {
  group('Compact catalog API', () {
    test('should fetch pages without product details and preserve SKU facets',
        () async {
      final paths = <String>[];
      final offsets = <int>[];
      final progress = <int>[];
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      addTearDown(dio.close);
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        paths.add(options.path);
        offsets.add(options.queryParameters['offset'] as int);
        expect(options.queryParameters['section_id'], '83');
        expect(options.queryParameters['type'], 'new');
        final last = offsets.last == 8;
        handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: page(next: last ? 9 : 8, complete: last)));
      }));
      final result = await ApiService(client: dio).getCatalogItems(
          categoryId: '83',
          type: 'new',
          onProgress: (items) => progress.add(items.length));
      expect(paths, ['get_catalog.php', 'get_catalog.php']);
      expect(offsets, [0, 8]);
      expect(progress, [8, 9]);
      expect(result.last.product.offerId, 'sku-9');
      expect(result.last.product.price, 123);
      expect(result.last.product.storePrice, 150);
      expect(result.last.product.ruStoreWarning, true);
      expect(result.last.attributes['model:MEMORY']!.value, 'Модель');
      expect(result.last.attributes['offer:MEMORY']!.value, '256 ГБ');
    });
    test('should fallback once on absent endpoint and remember older server',
        () async {
      final paths = <String>[];
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      addTearDown(dio.close);
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        paths.add(options.path);
        if (options.path == 'get_catalog.php') {
          handler.reject(DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 404)));
        } else {
          handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'status': 'success', 'total': 0, 'data': []}));
        }
      }));
      final api = ApiService(client: dio);
      expect(await api.getCatalogItems(), isEmpty);
      expect(await api.getCatalogItems(), isEmpty);
      expect(
          paths, ['get_catalog.php', 'get_products.php', 'get_products.php']);
    });
    test('should keep server errors visible without legacy request storm',
        () async {
      final paths = <String>[];
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      addTearDown(dio.close);
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        paths.add(options.path);
        handler.reject(DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 503)));
      }));
      await expectLater(ApiService(client: dio).getCatalogItems(),
          throwsA(isA<DioException>()));
      expect(paths, ['get_catalog.php']);
    });
    test('should reject broken pagination instead of reporting complete facets',
        () async {
      for (final broken in [
        page(next: 0),
        page(next: 8, complete: true),
        {...page(), 'data': []},
        {...page(), 'schema_version': 2},
      ]) {
        final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
        addTearDown(dio.close);
        dio.interceptors.add(InterceptorsWrapper(
            onRequest: (options, handler) => handler.resolve(Response(
                requestOptions: options, statusCode: 200, data: broken))));
        await expectLater(ApiService(client: dio).getCatalogItems(),
            throwsA(isA<FormatException>()));
      }
    });
    test('should stop requesting more pages after cancellation', () async {
      var current = true;
      var calls = 0;
      final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
      addTearDown(dio.close);
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        calls++;
        handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: page()));
      }));
      final result = await ApiService(client: dio).getCatalogItems(
          isCurrent: () => current, onProgress: (_) => current = false);
      expect(calls, 1);
      expect(result, isEmpty);
    });
  });
}
