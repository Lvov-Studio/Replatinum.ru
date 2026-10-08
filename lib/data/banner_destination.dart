import 'catalog_navigation.dart';
import 'models/banner_model.dart';

enum BannerDestinationKind { catalog, newStore, website }

class BannerDestination {
  const BannerDestination(this.kind, this.uri,
      {this.categoryCode, this.section});

  final BannerDestinationKind kind;
  final Uri uri;
  final String? categoryCode;
  final CatalogNode? section;

  String get actionLabel => switch (kind) {
        BannerDestinationKind.newStore => 'О магазине',
        BannerDestinationKind.catalog =>
          section == null ? 'В каталог' : 'Смотреть модели',
        BannerDestinationKind.website => 'Подробнее на сайте',
      };

  static BannerDestination? resolve(BannerModel banner) {
    if (banner.link.trim().isEmpty) return null;
    final link = Uri.tryParse(banner.link.trim());
    if (link == null) return null;
    final uri = Uri.parse('https://replatinum.ru').resolveUri(link);
    if (uri.port != 443 ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        !const {'replatinum.ru', 'www.replatinum.ru'}.contains(uri.host)) {
      return null;
    }
    // Explicit app-only destination for the opening campaign. The website
    // currently points this banner to /catalog/; never infer from its title.
    if (banner.id == '2509' && uri.path == '/catalog/') {
      return BannerDestination(BannerDestinationKind.newStore, uri);
    }
    final path = '/${uri.pathSegments.where((s) => s.isNotEmpty).join('/')}/';
    if (path == '/catalog/') {
      return BannerDestination(BannerDestinationKind.catalog, uri);
    }
    const extraSections = {
      'naushniki_i_kolonki': [
        CatalogNode(
            '/catalog/naushniki_i_kolonki/besprovodnye_naushniki/airpods/',
            'AirPods'),
      ],
      'foto_i_video': [
        CatalogNode('/catalog/foto_i_video/fotoapparaty_canon/', 'Canon'),
      ],
      'umnye_chasy_i_fitnes_braslety': [
        CatalogNode(
            '/catalog/umnye_chasy_i_fitnes_braslety/apple_/watch-series-12/',
            'Apple Watch Series 12'),
      ],
    };
    Iterable<CatalogNode> flatten(List<CatalogNode> nodes) sync* {
      for (final node in nodes) {
        yield node;
        yield* flatten(node.children);
      }
    }

    for (final code in {...catalogNavigation.keys, ...extraSections.keys}) {
      if (path == '/catalog/$code/') {
        return BannerDestination(BannerDestinationKind.catalog, uri,
            categoryCode: code);
      }
      for (final node in flatten([
        ...?catalogNavigation[code],
        ...?extraSections[code],
      ])) {
        final shortPath =
            '/catalog/${Uri.parse(node.path).pathSegments.where((s) => s.isNotEmpty).last}/';
        if (path == node.path || path == shortPath) {
          return BannerDestination(BannerDestinationKind.catalog, uri,
              categoryCode: code, section: node);
        }
      }
    }
    return BannerDestination(BannerDestinationKind.website, uri);
  }
}
