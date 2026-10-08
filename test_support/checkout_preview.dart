// LOCAL UI PREVIEW ONLY. Never used by lib/main.dart or the release workflow.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/cart_recommendations.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/data/models/product_detail_model.dart';
import 'package:platinumstore_app/providers/cart_provider.dart';
import 'package:platinumstore_app/providers/saved_products_provider.dart';
import 'package:platinumstore_app/ui/screens/cart_screen.dart';
import 'package:platinumstore_app/features/checkout/data/checkout_gateway.dart';
import 'package:platinumstore_app/features/account/data/account_gateway.dart';

class PreviewCheckoutGateway implements CheckoutGateway {
  @override
  Future<Map<String, dynamic>> context() async => {
        'success': true,
        'schema_version': 1,
        'city_delivery_minor': 100000,
        'payment_types': ['cash'],
        'profile': <String, dynamic>{},
        'pickup_stores': [
          {
            'id': 'sbs',
            'name': 'СБС Мегамолл',
            'address':
                'Краснодар, ул. Уральская, 79/1 · 2 этаж, зона кинотеатров IMAX',
            'available': true
          },
          {
            'id': 'severnaya',
            'name': 'Северная, 364',
            'address': 'Краснодар, ул. Северная, 364',
            'available': false,
            'notice': 'Будет доступен с 16 октября.'
          },
        ],
      };
  @override
  Future<Map<String, dynamic>> submit(Map<String, dynamic> payload) async =>
      throw const AccountFailure(
          'Локальный просмотр: заказ на сервер не отправлялся.');
  @override
  void dispose() {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prices and stock validation are real public, read-only API requests.
  final cart = CartProvider(quoteLoader: ApiService().quoteCart);
  final detail = await ApiService().getProductDetail('2297');
  final offer = detail.offers.firstWhere((offer) => offer.id == '2297');
  cart.addItem(
      Product(
          id: detail.id,
          name: detail.name,
          price: offer.price,
          storePrice: offer.storePrice,
          image: offer.image),
      offer: offer);
  final recommendations = CartRecommendations(
      load: (id) async => ProductDetail(
          id: id,
          name: '',
          price: 0,
          description: '',
          images: [],
          offers: [],
          basketAccessoryIds: []));
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cart),
        ChangeNotifierProvider(create: (_) => SavedProductsProvider()),
      ],
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          builder: (context, child) => Banner(
              message: 'ЛОКАЛЬНО',
              location: BannerLocation.topEnd,
              child: child!),
          home: CartScreen(
              recommendations: recommendations,
              checkoutGatewayFactory: PreviewCheckoutGateway.new))));
}
