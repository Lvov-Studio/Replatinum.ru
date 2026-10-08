import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:platinumstore_app/data/api/api_service.dart';
import 'package:platinumstore_app/data/banner_destination.dart';
import 'package:platinumstore_app/data/models/banner_model.dart';
import 'package:platinumstore_app/data/models/news_model.dart';
import 'package:platinumstore_app/ui/screens/news_screen.dart';

NewsItem article(String code) => NewsItem.fromJson({
      'id': code,
      'code': code,
      'title': 'Обзор $code',
      'body':
          '<p>Полный текст $code</p><a href="/news/second/">Следующая статья</a>',
    });

class NewsApi extends ApiService {
  bool fail = false;
  final pages = <int>[];
  final codes = <String>[];
  @override
  Future<NewsPage> getNewsPage({int limit = 20, int page = 1}) async {
    pages.add(page);
    if (fail) throw Exception('offline');
    return NewsPage([article(page == 1 ? 'first' : 'second')], page == 1);
  }

  @override
  Future<NewsItem> getArticle(String code) async {
    codes.add(code);
    if (fail) throw Exception('offline');
    return article(code);
  }
}

void main() {
  test('article routes accept only our HTTPS article paths', () {
    expect(
        articleCode(Uri.parse('https://replatinum.ru/news/first/')), 'first');
    for (final url in [
      'https://other.ru/news/first/',
      'https://replatinum.ru/news/',
      'javascript:alert(1)',
      'https://replatinum.ru:444/news/a/'
    ]) {
      expect(articleCode(Uri.parse(url)), isNull);
    }
    final banner = BannerModel(
        id: '1',
        title: '',
        subtitle: '',
        image: '',
        mobileImage: '',
        bgImage: '',
        link: '/news/first/',
        badge: '');
    expect(BannerDestination.resolve(banner)?.kind, BannerDestinationKind.news);
  });
  test('native body preserves content and resolves images without scripts', () {
    final html = articleHtml(
        '<style>p{display:none}</style><p onclick="x()">Текст</p><img src="/upload/test.jpg"><script>alert(1)</script>');
    expect(html, contains('Текст'));
    expect(html, contains('https://replatinum.ru/upload/test.jpg'));
    expect(html, isNot(contains('<script')));
    expect(html, isNot(contains('onclick')));
  });
  testWidgets(
      'list paginates, opens full article and follows article links natively',
      (tester) async {
    final api = NewsApi();
    await tester.pumpWidget(MaterialApp(home: NewsScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Показать ещё'));
    await tester.pumpAndSettle();
    expect(api.pages, [1, 2]);
    expect(find.text('Показать ещё'), findsNothing);
    await tester.tap(find.text('Обзор first'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Полный текст first'), findsOneWidget);
    tester.widget<Html>(find.byType(Html)).onLinkTap!(
        '/news/second/', {}, null);
    await tester.pumpAndSettle();
    expect(api.codes, ['first', 'second']);
    expect(find.textContaining('Полный текст second'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Полный текст first'), findsOneWidget);
  });
  testWidgets('failed article stays native and retry loads body',
      (tester) async {
    final api = NewsApi()..fail = true;
    await tester
        .pumpWidget(MaterialApp(home: ArticleScreen(code: 'first', api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Повторить'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Полный текст first'), findsOneWidget);
  });
}
