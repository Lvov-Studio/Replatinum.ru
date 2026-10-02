import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_detail_model.dart';
import '../models/banner_model.dart';
import '../models/news_model.dart';
import '../models/cart_quote.dart';
import '../models/catalog_filter.dart';

class ApiService {
  late final Dio _dio;

  static const String baseUrl = 'https://replatinum.ru/local/api/mobile/v1/';

  ApiService({Dio? client}) {
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
      {String? categoryId, String? type, bool Function()? isCurrent}) async {
    final parents = <Product>[];
    var offset = 0;
    while (true) {
      if (isCurrent?.call() == false) return [];
      final page = await getProducts(
          categoryId: categoryId, type: type, limit: 50, offset: offset);
      final items = page['products'] as List<Product>;
      if (items.isEmpty && offset < (page['total'] as num)) {
        throw StateError('Incomplete catalog response');
      }
      parents.addAll(items);
      offset += items.length;
      if (offset >= (page['total'] as num)) break;
    }
    final result = <String, CatalogItem>{};
    for (var start = 0; start < parents.length; start += 4) {
      if (isCurrent?.call() == false) return [];
      final batch = parents.skip(start).take(4);
      final groups = await Future.wait(batch.map((parent) async {
        final detail = await getProductDetail(parent.id);
        Map<String, CatalogAttribute> attributes(
                List<ProductSpec> specs, String scope) =>
            {
              for (final spec in specs)
                if (spec.value.trim().isNotEmpty && spec.name.trim().isNotEmpty)
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
    }
    return result.values.toList();
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

  Future<CartQuote> quoteCart(List<Map<String, dynamic>> items) async {
    final response = await _dio.post('quote_cart.php', data: {'items': items});
    if (response.data is! Map || response.data['status'] != 'success') {
      throw const FormatException('Cart quote unavailable');
    }
    return CartQuote.fromJson(Map<String, dynamic>.from(response.data['data']));
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
    try {
      final response =
          await _dio.get('search.php', queryParameters: {'q': query});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Product.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format or status');
        }
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

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

  Future<List<NewsItem>> getNews({int limit = 8}) async {
    final response =
        await _dio.get('get_news.php', queryParameters: {'limit': limit});
    if (response.statusCode != 200) {
      throw Exception('Failed to load news');
    }
    final Map<String, dynamic> json = response.data;
    if (json['status'] != 'success' || json['data'] is! List) {
      throw const FormatException('Invalid news response');
    }
    return (json['data'] as List)
        .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
