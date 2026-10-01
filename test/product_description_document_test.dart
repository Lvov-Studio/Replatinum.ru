import 'package:flutter_test/flutter_test.dart';
import 'package:platinumstore_app/core/utils/product_description_document.dart';

void main() {
  test('preserves responsive storefront CSS and content', () {
    final document = productDescriptionDocument('''
<style>.hero{background:linear-gradient(red,blue)}
@media(max-width:650px){.grid{display:grid}}</style>
<div class="hero"><h1>Смартфон</h1><img src="/image.jpg"></div>''');
    expect(document, contains('linear-gradient(red,blue)'));
    expect(document, contains('@media(max-width:650px)'));
    expect(document, contains('width=device-width'));
    expect(document, contains('src="/image.jpg"'));
    expect(productDescriptionDocument('<p>Текст</p>', scrollable: true),
        contains('overflow:auto'));
  });

  test('excludes executable markup while retaining safe links', () {
    final document = productDescriptionDocument('''
<script>alert('unsafe')</script><iframe src="https://example.com"></iframe>
<p onclick="alert(1)">Текст</p><a href="javascript:alert(1)">Плохая ссылка</a>
<a href="https://replatinum.ru/">Магазин</a>''');
    expect(document, isNot(contains("alert('unsafe')")));
    expect(document, isNot(contains('<iframe')));
    expect(document, isNot(contains('onclick')));
    expect(document, isNot(contains('javascript:')));
    expect(document, contains('href="https://replatinum.ru/"'));
    expect(document, contains("script-src 'none'"));
  });
}
