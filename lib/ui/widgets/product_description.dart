import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

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
  double _styledHeight = 240;
  @override
  Widget build(BuildContext context) {
    // Simple descriptions stay native; styled storefront blocks need full CSS.
    final styled =
        RegExp(r'<style\b', caseSensitive: false).hasMatch(widget.html);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (styled)
        SizedBox(
            height: _expanded ? _styledHeight : 240,
            child: _StyledDescriptionView(
                html: widget.html,
                onHeight: (height) {
                  if (mounted && (height - _styledHeight).abs() > 1) {
                    setState(() => _styledHeight = height);
                  }
                }))
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
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(_expanded ? 'Свернуть' : 'Подробнее')),
    ]);
  }
}

/// Styled HTML shares the product page's scroll; its height follows the content.
class _StyledDescriptionView extends StatefulWidget {
  final String html;
  final ValueChanged<double> onHeight;
  const _StyledDescriptionView({required this.html, required this.onHeight});
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
      // Product scripts/handlers are stripped and CSP blocks page scripts.
      // Only our injected observer measures layout after images finish loading.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('DescriptionHeight', onMessageReceived: (message) {
        final height = double.tryParse(message.message);
        if (mounted && height != null && height.isFinite && height > 0) {
          widget.onHeight(height.ceilToDouble());
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (!mounted) return;
          setState(() => _loading = false);
          _web.runJavaScript('''
            (() => {
              const content = document.getElementById('description-content');
              if (!content) return;
              const report = () => DescriptionHeight.postMessage(String(Math.ceil(content.getBoundingClientRect().height)));
              new ResizeObserver(report).observe(content);
              report();
            })();
          ''');
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
    _web.loadHtmlString(productDescriptionDocument(widget.html),
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
      Positioned.fill(
          child: WebViewWidget.fromPlatformCreationParams(
        params: _web.platform is AndroidWebViewController
            ? AndroidWebViewWidgetCreationParams(
                controller: _web.platform, displayWithHybridComposition: true)
            : PlatformWebViewWidgetCreationParams(controller: _web.platform),
      )),
      if (_loading)
        const Positioned.fill(
            child: ColoredBox(
                color: Colors.white,
                child: Center(child: CircularProgressIndicator()))),
    ]);
  }
}
