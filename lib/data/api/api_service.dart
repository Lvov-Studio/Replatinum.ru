import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_detail_model.dart';
import '../models/banner_model.dart';
import '../models/news_model.dart';
import '../models/cart_quote.dart';

class ApiService {
  late final Dio _dio;

  static const String baseUrl = 'https://replatinum.ru/local/api/mobile/v1/';

  ApiService() {
    _dio = Dio(BaseOptions(
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
