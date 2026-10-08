import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as parser;

import '../../data/api/api_service.dart';
import '../../data/models/news_model.dart';

/// Only article links on our host are handled as native article routes.
String? articleCode(Uri uri) {
  if (uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      uri.port != 443 ||
      !const {'replatinum.ru', 'www.replatinum.ru'}.contains(uri.host)) {
    return null;
  }
  final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  return parts.length == 2 && parts.first == 'news' ? parts.last : null;
}

String articleHtml(String source) {
  final doc = parser.parse(source);
  for (final el in doc
      .querySelectorAll('script,style,iframe,form,object,embed,link,meta')) {
    el.remove();
  }
  for (final el in doc.querySelectorAll('*')) {
    el.attributes.removeWhere((key, _) =>
        key.toString().startsWith('on') || key == 'style' || key == 'class');
    final src = el.attributes['src'];
    if (src != null) {
      final uri = Uri.tryParse(src);
      final absolute = uri == null
          ? null
          : Uri.parse('https://replatinum.ru/').resolveUri(uri);
      if (absolute?.scheme == 'https') {
        el.attributes['src'] = absolute.toString();
      } else {
        el.attributes.remove('src');
      }
    }
  }
  return doc.body?.innerHtml ?? '';
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, this.api});
  final ApiService? api;
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final ApiService _api = widget.api ?? ApiService();
  final List<NewsItem> _items = [];
  int _page = 1;
  bool _loading = false, _failed = false, _more = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await _api.getNewsPage(page: _page);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _more = result.hasMore;
        _page++;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Новости и обзоры')),
        body: SafeArea(
            child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 32),
          itemBuilder: (context, index) {
            if (index == _items.length) {
              if (_loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_failed) return _NewsError(onRetry: _load);
              if (_items.isEmpty) {
                return const Center(child: Text('Статей пока нет'));
              }
              return _more
                  ? Center(
                      child: TextButton(
                          onPressed: _load, child: const Text('Показать ещё')))
                  : const SizedBox.shrink();
            }
            final item = _items[index];
            return InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ArticleScreen(
                      code: item.code, initial: item, api: _api))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.image.isNotEmpty) _Cover(url: item.image),
                    const SizedBox(height: 12),
                    Text(item.title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text([item.category, item.date]
                        .where((value) => value.isNotEmpty)
                        .join(' · ')),
                  ]),
            );
          },
        )),
      );
}

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key, required this.code, this.initial, this.api});
  final String code;
  final NewsItem? initial;
  final ApiService? api;
  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late final ApiService _api = widget.api ?? ApiService();
  late Future<NewsItem> _future = _api.getArticle(widget.code);
  void _link(String? link) {
    final relative = Uri.tryParse(link ?? '');
    if (relative == null || link == null || link.isEmpty) return;
    final uri = Uri.parse('https://replatinum.ru/news/${widget.code}/')
        .resolveUri(relative);
    final code = articleCode(uri);
    if (code != null) {
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ArticleScreen(code: code, api: _api)));
    } else if (uri.host == 'replatinum.ru' && uri.path == '/news/') {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => NewsScreen(api: _api)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Эта ссылка пока недоступна в приложении')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Статья')),
        body: SafeArea(
            child: FutureBuilder<NewsItem>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: _NewsError(
                      onRetry: () => setState(() {
                            _future = _api.getArticle(widget.code);
                          })));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final item = snapshot.data!;
            return SelectionArea(
                child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: const TextStyle(
                                  fontSize: 28,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Text([item.category, item.date]
                              .where((value) => value.isNotEmpty)
                              .join(' · ')),
                          const SizedBox(height: 24),
                          if (item.image.isNotEmpty) _Cover(url: item.image),
                          if (item.preview.isNotEmpty)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Text(item.preview,
                                    style: const TextStyle(
                                        fontSize: 18, height: 1.5))),
                          Html(
                              data: articleHtml(item.body),
                              onLinkTap: (url, _, __) => _link(url),
                              style: {
                                'body': Style(
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    fontSize: FontSize(17),
                                    lineHeight: const LineHeight(1.6)),
                                'h1': Style(fontSize: FontSize(26)),
                                'h2': Style(fontSize: FontSize(23)),
                                'h3': Style(fontSize: FontSize(20)),
                                'table': Style(width: Width(100, Unit.percent)),
                              }),
                        ],
                      ))),
            ));
          },
        )),
      );
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const SizedBox.shrink()),
      );
}

class _NewsError extends StatelessWidget {
  const _NewsError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Не удалось загрузить статью. Проверьте подключение.'),
        TextButton(onPressed: onRetry, child: const Text('Повторить')),
      ]);
}
