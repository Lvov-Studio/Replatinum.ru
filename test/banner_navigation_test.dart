import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/banner_destination.dart';
import 'package:platinumstore_app/data/models/banner_model.dart';
import 'package:platinumstore_app/data/models/catalog_filter.dart';
import 'package:platinumstore_app/data/models/category_model.dart';
import 'package:platinumstore_app/data/models/product_model.dart';
import 'package:platinumstore_app/providers/product_provider.dart';
import 'package:platinumstore_app/ui/screens/banner_catalog_screen.dart';
import 'package:platinumstore_app/ui/screens/info_screens.dart';
import 'package:platinumstore_app/ui/widgets/banner_slider.dart';

BannerModel banner(String link, {String id = 'test'}) => BannerModel(
    id: id,
    title: 'Открытие нового Replatinum',
    subtitle: '',
    image: '',
    mobileImage: '',
    bgImage: '',
    link: link,
    badge: '');

class BannerApi extends ApiService {
  BannerApi(this.banners);
  final List<BannerModel> banners;
  final sections = <String?>[];
  bool fail = false;
  bool empty = false;
  @override
  Future<List<BannerModel>> getBanners() async => banners;
  @override
  Future<List<Category>> getCategories() async => [
        Category(
            id: '8',
            name: 'Наушники и колонки',
            code: 'naushniki_i_kolonki',
            image: '')
      ];
  @override
  Future<List<CatalogItem>> getCatalogItems(
      {String? categoryId,
      String? type,
      bool Function()? isCurrent,
      void Function(List<CatalogItem>)? onProgress}) async {
    sections.add(categoryId);
    if (fail) throw Exception('offline');
    if (empty) return [];
    return [
      CatalogItem(Product(id: '1', name: 'AirPods', price: 100, image: ''), {},
          path:
              '/catalog/naushniki_i_kolonki/besprovodnye_naushniki/airpods/model/'),
      CatalogItem(Product(id: '2', name: 'JBL', price: 100, image: ''), {},
          path: '/catalog/naushniki_i_kolonki/portativnye_kolonki/jbl/model/'),
    ];
  }
}

void main() {
  group('BannerDestination', () {
    for (final (link, code, suffix) in [
      ('/catalog/iphone-18-pro-max/', 'smartfony', 'iphone-18-pro-max/'),
      ('/catalog/iphone/', 'smartfony', 'iphone/'),
      ('/catalog/iphone-duo/', 'smartfony', 'iphone-duo/'),
      ('/catalog/airpods/', 'naushniki_i_kolonki', 'airpods/'),
      ('/catalog/fotoapparaty_canon/', 'foto_i_video', 'fotoapparaty_canon/'),
      (
        '/catalog/galaxy-z-fold7-galaxy-z-flip7/',
        'smartfony',
        'galaxy-z-fold7-galaxy-z-flip7/'
      ),
      (
        '/catalog/umnye_chasy_i_fitnes_braslety/apple_/watch-series-12/',
        'umnye_chasy_i_fitnes_braslety',
        'watch-series-12/'
      ),
    ]) {
      test('should open $link in the exact native section', () {
        final target = BannerDestination.resolve(banner(link))!;
        expect(target.kind, BannerDestinationKind.catalog);
        expect(target.categoryCode, code);
        expect(target.section!.path, endsWith(suffix));
      });
    }
    test('should use explicit campaign ID without guessing from title', () {
      expect(BannerDestination.resolve(banner('/catalog/', id: '2509'))!.kind,
          BannerDestinationKind.newStore);
      expect(BannerDestination.resolve(banner('/catalog/'))!.kind,
          BannerDestinationKind.catalog);
      expect(BannerDestination.resolve(banner('/news/', id: '2509'))!.kind,
          BannerDestinationKind.website);
    });
    test('should retain unknown site links and reject invalid destinations',
        () {
      expect(BannerDestination.resolve(banner('/news/?id=12'))!.uri.query,
          'id=12');
      for (final link in [
        '',
        'https://other.example/catalog/iphone/',
        'javascript:alert(1)',
        'https://user@replatinum.ru/',
        'https://replatinum.ru:123/catalog/',
        'https://['
      ]) {
        expect(BannerDestination.resolve(banner(link)), isNull, reason: link);
      }
    });
  });
  group('BannerSlider', () {
    testWidgets('should select a banner by its indicator with reduced motion',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!),
          home: Scaffold(
              body: BannerSlider(
                  apiService: BannerApi([
            banner('/catalog/iphone/', id: 'first'),
            banner('/catalog/', id: '2509'),
          ])))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('banner-dot-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('banner-2509')).hitTestable(),
          findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(find.byKey(const ValueKey('banner-2509')).hitTestable(),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    for (final (width, scale) in [(320.0, 1.0), (360.0, 2.0), (600.0, 1.0)]) {
      testWidgets(
          'should remove purchase buttons and open store at $width/$scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
                body: BannerSlider(
                    apiService:
                        BannerApi([banner('/catalog/', id: '2509')])))));
        await tester.pumpAndSettle();
        expect(find.text('Купить'), findsNothing);
        expect(find.text('О магазине'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('banner-2509')));
        await tester.pumpAndSettle();
        expect(find.byType(ContactsScreen), findsOneWidget);
        expect(find.text('Краснодар, ул. Северная, 364'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
  group('Banner catalog', () {
    test('should filter exact section and preserve it when retrying', () async {
      final api = BannerApi([]);
      final provider = ProductProvider(apiService: api);
      addTearDown(provider.dispose);
      final target = BannerDestination.resolve(banner('/catalog/airpods/'))!;
      await provider.fetchProducts(
          category: (await api.getCategories()).first,
          subsection: target.section);
      expect(provider.products.map((p) => p.id), ['1']);
      api.fail = true;
      await provider.retry();
      expect(provider.error, isNotEmpty);
      api.fail = false;
      await provider.retry();
      expect(provider.sectionTitle, 'AirPods');
      expect(provider.products.map((p) => p.id), ['1']);
    });
    testWidgets(
        'should open native catalog and request the correct root category',
        (tester) async {
      final api = BannerApi([banner('/catalog/airpods/')])..empty = true;
      // Keep the list empty for this navigation check; provider filtering is
      // verified separately above without replacing the real provider logic.
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: BannerSlider(apiService: api))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('banner-test')));
      await tester.pumpAndSettle();
      expect(find.byType(BannerCatalogScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(api.sections, ['8']);
      expect(tester.takeException(), isNull);
    });
  });
}
