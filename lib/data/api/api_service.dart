import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_detail_model.dart';
import '../models/banner_model.dart';
import '../models/news_model.dart';

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
    
    // LogInterceptor полезен для отладки
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('get_categories.php');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
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
    String? type,        // 'sale' | 'new' | 'hit'
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (categoryId != null) params['section_id'] = categoryId;
      if (type != null) params['type'] = type;

      final response = await _dio.get('get_products.php', queryParameters: params);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
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

  Future<ProductDetail> getProductDetail(String id) async {
    try {
      final response = await _dio.get('get_product_detail.php', queryParameters: {'id': id});
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
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

  Future<bool> createOrder(String name, String phone, String email, List<Map<String, dynamic>> items) async {
    try {
      final response = await _dio.post(
        'create_order.php',
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'items': items,
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
      final response = await _dio.get('search.php', queryParameters: {'q': query});
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
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
        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
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
    try {
      final response = await _dio.get('get_news.php', queryParameters: {'limit': limit});
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = response.data;
        if (json['status'] == 'success' && json['data'] != null) {
          return (json['data'] as List).map((e) => NewsItem.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
