// Read-only live probe: dart --packages=.dart_tool/package_config.json tools/probe_catalog_loading.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:platinumstore_app/data/api/api_service.dart';

Future<void> main(List<String> args) async {
  var requests = 0;
  var jsonBytes = 0;
  final client = Dio(BaseOptions(
      baseUrl: ApiService.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30)));
  client.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    requests++;
    handler.next(options);
  }, onResponse: (response, handler) {
    jsonBytes += utf8.encode(jsonEncode(response.data)).length;
    handler.next(response);
  }));
  final watch = Stopwatch()..start();
  int? firstMs;
  final result = await ApiService(
          client: client, useCompactCatalog: !args.contains('--legacy'))
      .getCatalogItems(
          categoryId: '83',
          onProgress: (items) {
            if (firstMs != null) return;
            firstMs = watch.elapsedMilliseconds;
            stdout.writeln(
                'First batch: ${items.length} variants in $firstMs ms');
          });
  stdout.writeln(jsonEncode({
    'section': '83',
    'variants': result.length,
    'requests': requests,
    'first_batch_ms': firstMs,
    'complete_ms': watch.elapsedMilliseconds,
    'decoded_json_bytes': jsonBytes,
  }));
  client.close();
}
