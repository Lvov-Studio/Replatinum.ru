import 'package:html/parser.dart' as parser;

/// Keeps the storefront's CSS while excluding executable product content.
String productDescriptionDocument(String html, {bool scrollable = false}) {
  final fragment = parser.parseFragment(html);
  for (final element in fragment
      .querySelectorAll('script,iframe,object,embed,form,link,meta,base')) {
    element.remove();
  }
  for (final element in fragment.querySelectorAll('*')) {
    element.attributes.removeWhere((name, value) =>
        name.toString().toLowerCase().startsWith('on') ||
        (const ['href', 'src', 'action'].contains(name) &&
            !const ['http', 'https', '']
                .contains(Uri.tryParse(value.trim())?.scheme.toLowerCase())));
  }
  return '''<!doctype html><html lang="ru"><head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src https: http: data:; font-src https: data:; script-src 'none'">
<style>html,body{margin:0;padding:0;background:#fff;overflow:${scrollable ? 'auto' : 'hidden'}}
body{font-family:system-ui,sans-serif;font-size:14px;line-height:1.5}
#description-content{display:flow-root}img{max-width:100%;height:auto}</style>
</head><body><div id="description-content">${fragment.outerHtml}</div>
</body></html>''';
}
