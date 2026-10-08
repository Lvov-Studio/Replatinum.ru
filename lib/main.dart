import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/category_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/saved_products_provider.dart';
import 'providers/recent_products_provider.dart';
import 'ui/screens/main_screen.dart';
import 'data/cart_storage.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(
            create: (_) => CartProvider(storage: FileCartStorage())..load()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SavedProductsProvider()..load()),
        ChangeNotifierProvider(create: (_) => RecentProductsProvider()..load()),
      ],
      child: const PlatinumStoreApp(),
    ),
  );
}

class PlatinumStoreApp extends StatelessWidget {
  const PlatinumStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlatinumStore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}
