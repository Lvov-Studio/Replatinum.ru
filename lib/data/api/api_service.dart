import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_detail_model.dart';
import '../models/banner_model.dart';
import '../models/news_model.dart';
import '../models/cart_quote.dart';
import '../models/catalog_filter.dart';

class CartApiFailure implements Exception {
  const CartApiFailure(this.message);
  final String message;
}

class ApiService {
  late final Dio _dio;
  bool _compactCatalogEnabled;

  static const String baseUrl = 'https://replatinum.ru/local/api/mobile/v1/';

  ApiService({Dio? client, bool useCompactCatalog = true})
      : _compactCatalogEnabled = useCompactCatalog {
    _dio = client ??
        Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          responseType: ResponseType.json,
        ));

    // Добавляем Interceptors для логов и (в будущем) для токенов
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Здесь можно добавлять токены авторизации в заголовки
        // options.headers['Authorization'] = 'Bearer token';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('get_categories.php');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Category.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format or status');
        }
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<Map<String, dynamic>> getProducts({
    String? categoryId,
    String? type, // 'sale' | 'new' | 'hit'
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (categoryId != null) params['section_id'] = categoryId;
      if (type != null) params['type'] = type;

      final response =
          await _dio.get('get_products.php', queryParameters: params);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return {
            'products': data.map((json) => Product.fromJson(json)).toList(),
            'total': jsonResponse['total'] ?? data.length,
          };
        } else {
          throw Exception('Invalid response format or status');
        }
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  /// Complete section snapshot: facets must include variants beyond page one.
  Future<List<CatalogItem>> getCatalogItems(
      {String? categoryId,
      String? type,
      bool Function()? isCurrent,
      void Function(List<CatalogItem>)? onProgress}) async {
    if (_compactCatalogEnabled) {
      final compact = await _getCompactCatalogItems(
          categoryId: categoryId,
          type: type,
          isCurrent: isCurrent,
          onProgress: onProgress);
      if (compact != null) return compact;
    }
    final result = <String, CatalogItem>{};
    var offset = 0;
    while (true) {
      if (isCurrent?.call() == false) return [];
      final page = await getProducts(
          categoryId: categoryId, type: type, limit: 50, offset: offset);
      final items = page['products'] as List<Product>;
      if (items.isEmpty && offset < (page['total'] as num)) {
        throw StateError('Incomplete catalog response');
      }
      for (var start = 0; start < items.length; start += 4) {
        if (isCurrent?.call() == false) return [];
        // Keep four requests in flight; publish each completed batch immediately.
        final batch = items.skip(start).take(4);
        final groups = await Future.wait(batch.map((parent) async {
          final detail = await getProductDetail(parent.id);
          Map<String, CatalogAttribute> attributes(
                  List<ProductSpec> specs, String scope) =>
              {
                for (final spec in specs)
                  if (spec.value.trim().isNotEmpty &&
                      spec.name.trim().isNotEmpty)
                    '$scope:${spec.code.isEmpty ? '${spec.group}:${spec.name}' : spec.code}':
                        CatalogAttribute(spec.name, spec.value.trim()),
              };
          final modelAttributes = attributes(detail.specs, 'model');
          final preview = parent.copyWith(
              ruStoreWarning: parent.ruStoreWarning || detail.ruStoreWarning);
          if (detail.offers.isNotEmpty) {
            final orderedOffers = [
              ...detail.offers.where((o) => o.price > 0 && o.canBuy == true),
              ...detail.offers.where((o) => o.price > 0 && o.canBuy != true),
              ...detail.offers.where((o) => o.price <= 0),
            ];
            return [
              for (final offer in orderedOffers)
                if (parent.offerId == null || parent.offerId == offer.id)
                  CatalogItem(
                      _offerPreview(preview, offer),
                      {
                        ...modelAttributes,
                        ...attributes(offer.specs, 'offer'),
                      },
                      path: Uri.tryParse(detail.url)?.path ?? '')
            ];
          }
          return [
            CatalogItem(
                Product(
                    id: parent.id,
                    name: detail.name,
                    price: detail.price,
                    storePrice: detail.storePrice,
                    canBuy: detail.canBuy,
                    image: detail.images.isEmpty
                        ? parent.image
                        : detail.images.first,
                    ruStoreWarning: preview.ruStoreWarning,
                    specs: detail.specs),
                modelAttributes,
                path: Uri.tryParse(detail.url)?.path ?? '')
          ];
        }));
        for (final item in groups.expand((group) => group)) {
          result['${item.product.id}:${item.product.offerId ?? 'base'}'] = item;
        }
        if (isCurrent?.call() == false) return [];
        onProgress?.call(List.unmodifiable(result.values));
      }
      offset += items.length;
      if (offset >= (page['total'] as num)) break;
    }
    return result.values.toList();
  }

  Future<List<CatalogItem>?> _getCompactCatalogItems({
    String? categoryId,
    String? type,
    bool Function()? isCurrent,
    void Function(List<CatalogItem>)? onProgress,
  }) async {
    var offset = 0;
    int? expectedTotal;
    final result = <String, CatalogItem>{};
    while (true) {
      if (isCurrent?.call() == false) return [];
      final params = <String, dynamic>{'limit': 8, 'offset': offset};
      if (categoryId != null) params['section_id'] = categoryId;
      if (type != null) params['type'] = type;
      final Response<dynamic> response;
      try {
        response = await _dio.get('get_catalog.php', queryParameters: params);
      } on DioException catch (e) {
        // Only absence on the first page means an older server. Other errors
        // must remain visible rather than triggering another large download.
        if (offset == 0 && e.response?.statusCode == 404) {
          _compactCatalogEnabled = false;
          return null;
        }
        rethrow;
      }
      if (isCurrent?.call() == false) return [];
      final json = response.data;
      if (response.statusCode != 200 ||
          json is! Map ||
          json['status'] != 'success' ||
          json['schema_version'] != 1 ||
          json['data'] is! List ||
          json['total_models'] is! int ||
          json['next_offset'] is! int ||
          json['complete'] is! bool) {
        throw const FormatException('Invalid compact catalog response');
      }
      final total = json['total_models'] as int;
      final next = json['next_offset'] as int;
      final complete = json['complete'] as bool;
      if (total < 0 ||
          next < offset ||
          next > total ||
          next > offset + 8 ||
          (expectedTotal != null && total != expectedTotal) ||
          (complete != (next == total)) ||
          (!complete && next != offset + 8) ||
          (next > offset && (json['data'] as List).isEmpty)) {
        throw const FormatException('Incomplete compact catalog page');
      }
      expectedTotal = total;
      final pageModels = <String>{};
      Map<String, CatalogAttribute> attributes(
              List<ProductSpec> specs, String scope) =>
          {
            for (final spec in specs)
              if (spec.value.trim().isNotEmpty && spec.name.trim().isNotEmpty)
                '$scope:${spec.code.isEmpty ? '${spec.group}:${spec.name}' : spec.code}':
                    CatalogAttribute(spec.name, spec.value.trim()),
          };
      for (final row in json['data'] as List) {
        final data = Map<String, dynamic>.from(row as Map);
        final product = Product.fromJson(data);
        pageModels.add(product.id);
        if (product.id.isEmpty ||
            data['path'] is! String ||
            !(data['path'] as String).startsWith('/catalog/') ||
            data['specs'] is! List ||
            data['model_specs'] is! List ||
            data['price'] is! num ||
            data['store_price'] is! num ||
            data['can_buy'] is! bool) {
          throw const FormatException('Invalid compact catalog item');
        }
        final modelSpecs = parseSpecs(data['model_specs']);
        final item = CatalogItem(
            product,
            {
              ...attributes(modelSpecs, 'model'),
              if (product.offerId != null)
                ...attributes(product.specs, 'offer'),
            },
            path: data['path'] as String);
        final key = '${product.id}:${product.offerId ?? 'base'}';
        if (result.containsKey(key)) {
          throw const FormatException('Duplicate catalog item');
        }
        result[key] = item;
      }
      if (pageModels.length != next - offset) {
        throw const FormatException('Missing catalog models');
      }
      onProgress?.call(List.unmodifiable(result.values));
      if (complete) return result.values.toList();
      offset = next;
    }
  }

  Future<List<Product>> getHomeProducts(String type) async {
    final parents = <Product>[];
    var offset = 0;
    while (true) {
      final page = await getProducts(type: type, limit: 50, offset: offset);
      final items = page['products'] as List<Product>;
      parents.addAll(items);
      offset += items.length;
      if (items.isEmpty || offset >= (page['total'] as num)) break;
    }
    final code =
        {'new': 'NEWPRODUCT', 'hit': 'SALELEADER', 'sale': 'DISCOUNT'}[type]!;
    final result = <Product>[];
    // V2 already returns selected SKUs; legacy returns parent products.
    for (final parent in parents) {
      if (parent.offerId != null) {
        result.add(parent);
        continue;
      }
      final detail = await getProductDetail(parent.id);
      final previewParent = parent.copyWith(
          ruStoreWarning: parent.ruStoreWarning || detail.ruStoreWarning);
      final marked = detail.offers
          .where((o) => o.properties.any((p) =>
              p.code == code &&
              const ['да', 'y', 'yes', 'true', '1']
                  .contains(p.value.toLowerCase())))
          .toList();
      if (marked.isEmpty) {
        final priced = detail.offers.where((o) => o.price > 0).toList()
          ..sort((a, b) => a.price.compareTo(b.price));
        if (priced.isEmpty) {
          result.add(previewParent);
        } else {
          result.add(_offerPreview(previewParent, priced.first));
        }
      } else {
        result.addAll(marked.map((o) => _offerPreview(previewParent, o)));
      }
    }
    final unique = <String, Product>{};
    for (final product in result) {
      unique['${product.id}:${product.offerId ?? 'base'}'] = product;
    }
    return unique.values.toList();
  }

  Product _offerPreview(Product parent, Offer offer) => Product(
      id: parent.id,
      offerId: offer.id,
      name: offer.name,
      price: offer.price,
      image: offer.image.isEmpty ? parent.image : offer.image,
      storePrice: offer.storePrice,
      canBuy: offer.canBuy,
      ruStoreWarning: parent.ruStoreWarning,
      specs: offer.specs);

  Future<ProductDetail> getProductDetail(String id) async {
    try {
      final response =
          await _dio.get('get_product_detail.php', queryParameters: {'id': id});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] != null) {
          return ProductDetail.fromJson(jsonResponse['data']);
        } else {
          throw Exception('Invalid response format or status');
        }
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (e) {
      throw Exception('Error fetching product details: $e');
    }
  }

  Future<void> submitProductInquiry(
      {required String productId,
      required String productName,
      required String name,
      required String phone,
      required String comment}) async {
    final response =
        await _dio.post('https://replatinum.ru/local/ajax/preorder.php', data: {
      'productId': int.tryParse(productId),
      'productTitle': productName,
      'name': name,
      'phone': phone,
      'comment': comment
    });
    if (response.data is! Map || response.data['success'] != true) {
      throw Exception('Inquiry was not delivered');
    }
  }

  Future<void> submitCreditInquiry({
    required String productId,
    required String productName,
    required String productUrl,
    required num price,
    required int months,
    required String name,
    required String phone,
  }) async {
    final response = await _dio.post(
      'https://replatinum.ru/local/ajax/credit_order.php',
      options: Options(receiveTimeout: const Duration(seconds: 60)),
      data: {
        'productId': int.tryParse(productId),
        'productTitle': productName,
        'productUrl': productUrl,
        'productPrice': price,
        'creditPeriod': months,
        'purchasePlace': 'store',
        'firstName': name,
        'phone': phone,
      },
    );
    if (response.statusCode != 200 ||
        response.data is! Map ||
        response.data['success'] != true) {
      throw const FormatException('Credit inquiry was not accepted');
    }
  }

  Future<CartQuote> quoteCart(List<Map<String, dynamic>> items) async {
    try {
      final response =
          await _dio.post('quote_cart.php', data: {'items': items});
      if (response.data is! Map || response.data['status'] != 'success') {
        throw CartApiFailure(response.data is Map
            ? '${response.data['message'] ?? 'Не удалось проверить корзину.'}'
            : 'Не удалось проверить корзину.');
      }
      return CartQuote.fromJson(
          Map<String, dynamic>.from(response.data['data']));
    } on DioException catch (error) {
      final data = error.response?.data;
      throw CartApiFailure(data is Map && data['message'] is String
          ? data['message'] as String
          : 'Нет связи с сервером. Повторите проверку корзины.');
    }
  }

  Future<bool> createOrder(
      String name, String phone, String email, List<Map<String, dynamic>> items,
      {required String quoteId}) async {
    try {
      final response = await _dio.post(
        'create_order.php',
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'items': items,
          'quote_id': quoteId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        if (jsonResponse['status'] == 'success') {
          return true;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error creating order');
        }
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    final input = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (input.length < 2) return [];
    // Share the storefront's synonyms, SKU prices and resized thumbnails.
    final response = await _dio.get(
        Uri.parse(baseUrl).resolve('/local/ajax/search.php').toString(),
        queryParameters: {'q': input});
    final payload = response.data;
    if (response.statusCode != 200 ||
        payload is! Map ||
        payload['status'] != 'success' ||
        payload['results'] is! List) {
      throw const FormatException('Invalid search response');
    }
    final terms = _searchWords('${payload['corrected_query'] ?? input}');
    final products = <Product>[];
    final seen = <String>{};
    for (final raw in payload['results'] as List) {
      if (raw is! Map) throw const FormatException('Invalid search item');
      final id = '${raw['id'] ?? ''}';
      final name = '${raw['name'] ?? ''}';
      if (id.isEmpty || name.isEmpty || !seen.add(id)) continue;
      final words = _searchWords(name);
      // A model number is a word: searching 17 must not match HD17 or 117.
      if (terms.any(
          (term) => RegExp(r'^\d+$').hasMatch(term) && !words.contains(term))) {
        continue;
      }
      final price = raw['price'] is num
          ? raw['price'] as num
          : num.tryParse('${raw['price'] ?? ''}'
                  .replaceAll(RegExp(r'[\s\u00a0\u202f₽]'), '')
                  .replaceAll(',', '.')) ??
              0;
      final image = '${raw['image'] ?? ''}';
      final uri = Uri.tryParse(image);
      products.add(Product(
          id: id,
          offerId: id,
          name: name,
          price: price > 0 ? price : 0,
          image: image.isEmpty || uri == null
              ? ''
              : Uri.parse(baseUrl).resolveUri(uri).toString()));
    }
    int rank(Product product) {
      final words = _searchWords(product.name);
      final joined = words.join(' ');
      final phrase = terms.join(' ');
      return (phrase.isNotEmpty && joined.contains(phrase) ? 100 : 0) +
          terms.where((term) => words.contains(term)).length * 10;
    }

    final order = {for (var i = 0; i < products.length; i++) products[i].id: i};
    products.sort((a, b) {
      final relevance = rank(b).compareTo(rank(a));
      return relevance != 0 ? relevance : order[a.id]!.compareTo(order[b.id]!);
    });
    return products;
  }

  static List<String> _searchWords(String value) => RegExp(r'[a-zа-яё0-9]+')
      .allMatches(value.toLowerCase().replaceAll('ё', 'е'))
      .map((match) => match.group(0)!)
      .toList();

  Future<List<BannerModel>> getBanners() async {
    try {
      final response = await _dio.get('get_slider.php');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => BannerModel.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format or status');
        }
      } else {
        throw Exception('Failed to get banners');
      }
    } catch (e) {
      throw Exception('Error getting banners: $e');
    }
  }

  Future<List<NewsItem>> getNews({int limit = 8}) async =>
      (await getNewsPage(limit: limit)).items;

  Future<NewsPage> getNewsPage({int limit = 20, int page = 1}) async {
    final response = await _dio
        .get('get_news.php', queryParameters: {'limit': limit, 'page': page});
    if (response.statusCode != 200) {
      throw Exception('Failed to load news');
    }
    final Map<String, dynamic> json = response.data;
    if (json['status'] != 'success' || json['data'] is! List) {
      throw const FormatException('Invalid news response');
    }
    return NewsPage(
        (json['data'] as List)
            .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        json['has_more'] == true);
  }

  Future<NewsItem> getArticle(String code) async {
    final response =
        await _dio.get('get_news.php', queryParameters: {'code': code});
    final Map<String, dynamic> json = response.data;
    if (json['status'] != 'success' ||
        json['data'] is! List ||
        (json['data'] as List).isEmpty) {
      throw const FormatException('Article unavailable');
    }
    return NewsItem.fromJson(
        (json['data'] as List).first as Map<String, dynamic>);
  }
}
