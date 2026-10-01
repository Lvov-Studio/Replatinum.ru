import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/utils/product_description_document.dart';

void _openDescriptionLink(String? url) {
  final uri = Uri.tryParse(url ?? '');
  if (uri != null && const ['https', 'http'].contains(uri.scheme)) {
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class ProductDescription extends StatefulWidget {
  final String html;
  const ProductDescription({super.key, required this.html});
  @override
  State<ProductDescription> createState() => _ProductDescriptionState();
}

class _ProductDescriptionState extends State<ProductDescription> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    // Simple descriptions stay native; styled storefront blocks need full CSS.
    final styled =
        RegExp(r'<style\b', caseSensitive: false).hasMatch(widget.html);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (styled)
        SizedBox(height: 240, child: _StyledDescriptionView(html: widget.html))
      else
        ClipRect(
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: _expanded ? double.infinity : 240),
                child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Html(
                        data: widget.html,
                        onLinkTap: (url, _, __) => _openDescriptionLink(url),
                        style: {
                          'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              fontSize: FontSize(14),
                              lineHeight: const LineHeight(1.5))
                        })))),
      TextButton.icon(
          onPressed: () {
            if (styled) {
              Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Описание')),
                      body: SafeArea(
                          child: _StyledDescriptionView(
                              html: widget.html, scrollable: true)))));
            } else {
              setState(() => _expanded = !_expanded);
            }
          },
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(_expanded ? 'Свернуть' : 'Подробнее')),
    ]);
  }
}

/// A bounded viewport avoids oversized Android WebView render surfaces.
class _StyledDescriptionView extends StatefulWidget {
  final String html;
  final bool scrollable;
  const _StyledDescriptionView({required this.html, this.scrollable = false});
  @override
  State<_StyledDescriptionView> createState() => _StyledDescriptionViewState();
}

class _StyledDescriptionViewState extends State<_StyledDescriptionView> {
  late final WebViewController _web;
  bool _loading = true;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setBackgroundColor(Colors.white)
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (request) {
          if (_loading &&
              (request.url == 'about:blank' ||
                  request.url == 'https://replatinum.ru/')) {
            return NavigationDecision.navigate;
          }
          if (request.isMainFrame) _openDescriptionLink(request.url);
          return NavigationDecision.prevent;
        },
        onWebResourceError: (error) {
          if (mounted && error.isForMainFrame == true) {
            setState(() {
              _loading = false;
              _failed = true;
            });
          }
        },
      ));
    _load();
  }

  void _load() {
    _web.loadHtmlString(
        productDescriptionDocument(widget.html, scrollable: widget.scrollable),
        baseUrl: 'https://replatinum.ru/');
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Не удалось загрузить оформление описания.'),
        TextButton(
            onPressed: () {
              setState(() {
                _failed = false;
                _loading = true;
              });
              _load();
            },
            child: const Text('Повторить')),
      ]));
    }
    return Stack(children: [
      Positioned.fill(child: WebViewWidget(controller: _web)),
      if (_loading)
        const Positioned.fill(
            child: ColoredBox(
                color: Colors.white,
                child: Center(child: CircularProgressIndicator()))),
    ]);
  }
}
