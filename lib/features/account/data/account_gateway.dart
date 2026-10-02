import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:webview_flutter/webview_flutter.dart';

class AccountFailure implements Exception {
  const AccountFailure(this.message,
      {this.unauthorized = false, this.cancelled = false});
  final String message;
  final bool unauthorized, cancelled;
}

abstract class AccountGateway {
  Future<Map<String, dynamic>> request(String action,
      [Map<String, String> fields = const {}]);
  Future<void> reconnect();
  void cancelChallenge();
  void dispose();
}

// Session/HttpOnly cookies stay in the OS WebView cookie store, never in Dart files.
class SiteAccountGateway implements AccountGateway {
  SiteAccountGateway({required this.onChallenge}) {
    browser = WebViewController();
    _configure();
  }
  Future<void> _configure() async {
    try {
      await browser.setJavaScriptMode(JavaScriptMode.unrestricted);
      await browser.addJavaScriptChannel('AccountBridge',
          onMessageReceived: _message);
      await browser.setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) =>
            !request.isMainFrame || _isBridge(request.url)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent,
        onPageStarted: (url) => _trusted = _isBridge(url),
        onPageFinished: (url) async {
          if (!_isBridge(url) || _disposed || _ready.isCompleted) return;
          // Initial inline JS can run before Android delivers onPageStarted.
          // Repeat the authenticated handshake once the document has loaded.
          _trusted = true;
          try {
            await browser.runJavaScript(
                "if(typeof window.rpAccountRequest === 'function') window.AccountBridge.postMessage(JSON.stringify({event:'ready',nonce:window.location.hash.slice(1)}));");
          } catch (_) {
            _failReady();
          }
        },
        onHttpError: (error) {
          if (error.request?.uri.path == _url.path) _failReady();
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? false) _failReady();
        },
      ));
      await browser.loadRequest(_loadUrl());
    } catch (_) {
      _failReady();
    }
  }

  static final _url =
      Uri.parse('https://replatinum.ru/local/api/mobile/v1/account_bridge.php');
  late final WebViewController browser;
  final void Function(bool) onChallenge;
  Completer<void> _ready = Completer<void>();
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  int _sequence = 0;
  bool _trusted = false, _disposed = false;
  String _nonce = _newNonce();
  Uri _loadUrl() => _url.replace(queryParameters: {
        'reload': DateTime.now().microsecondsSinceEpoch.toString()
      }, fragment: _nonce);
  static String _newNonce() =>
      List.generate(24, (_) => Random.secure().nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
  bool _isBridge(String value) {
    final uri = Uri.tryParse(value);
    return uri?.scheme == 'https' &&
        uri?.host == _url.host &&
        uri?.port == 443 &&
        uri?.path == _url.path;
  }

  void _failReady() {
    if (!_ready.isCompleted) {
      _ready.completeError(const AccountFailure(
          'Не удалось подключиться к кабинету. Попробуйте позже.'));
    }
  }

  void _message(JavaScriptMessage message) {
    if (!_trusted || _disposed) return;
    try {
      final payload = jsonDecode(message.message) as Map<String, dynamic>;
      if (payload['nonce'] != _nonce) return;
      if (payload['event'] == 'ready') {
        if (!_ready.isCompleted) _ready.complete();
      } else if (payload['event'] == 'captcha_required') {
        onChallenge(true);
      } else if (payload['event'] == 'captcha_complete') {
        onChallenge(false);
      } else if (payload['id'] is int) {
        final waiter = _pending.remove(payload['id']);
        if (waiter == null) return;
        final data = Map<String, dynamic>.from(payload['data'] as Map);
        if (data['success'] == true) {
          waiter.complete(data);
        } else {
          waiter.completeError(AccountFailure(
              '${data['error'] ?? 'Не удалось выполнить действие.'}',
              unauthorized:
                  payload['status'] == 401 || payload['status'] == 403));
        }
      }
    } catch (_) {
      // Ignore malformed/unsolicited messages, never promote them to account data.
    }
  }

  @override
  Future<Map<String, dynamic>> request(String action,
      [Map<String, String> fields = const {}]) async {
    await _ready.future.timeout(const Duration(seconds: 15),
        onTimeout: () => throw const AccountFailure(
            'Не удалось подключиться к кабинету. Повторите попытку.'));
    if (_disposed || !_trusted) {
      throw const AccountFailure('Соединение с кабинетом закрыто.');
    }
    final id = ++_sequence;
    final response = Completer<Map<String, dynamic>>();
    final result = response.future.timeout(
        Duration(seconds: action == 'send_code' ? 180 : 30),
        onTimeout: () => throw const AccountFailure(
            'Не удалось подтвердить результат. Попробуйте позже.'));
    _pending[id] = response;
    try {
      final values = await Future.wait<Object?>([
        browser.runJavaScript(
            'window.rpAccountRequest($id, ${jsonEncode(action)}, ${jsonEncode(fields)});'),
        result,
      ], eagerError: true);
      return values[1] as Map<String, dynamic>;
    } finally {
      _pending.remove(id);
      onChallenge(false);
    }
  }

  @override
  Future<void> reconnect() async {
    if (_disposed) return;
    _trusted = false;
    _nonce = _newNonce();
    _ready = Completer<void>();
    // Attach an error handler before network callbacks can fire.
    final ready = _ready.future.timeout(const Duration(seconds: 15),
        onTimeout: () =>
            throw const AccountFailure('Не удалось подключиться к кабинету.'));
    // Changing only the fragment does not reload an existing WebView document.
    await browser.loadRequest(_loadUrl());
    await ready;
  }

  @override
  void cancelChallenge() {
    for (final waiter in _pending.values) {
      if (!waiter.isCompleted) {
        waiter.completeError(const AccountFailure('', cancelled: true));
      }
    }
    _pending.clear();
    onChallenge(false);
    if (_trusted) browser.runJavaScript('window.rpAccountCancel();');
  }

  @override
  void dispose() {
    _disposed = true;
    cancelChallenge();
  }
}

class UnavailableAccountGateway implements AccountGateway {
  @override
  Future<Map<String, dynamic>> request(String action,
          [Map<String, String> fields = const {}]) async =>
      throw const AccountFailure('Кабинет недоступен на этом устройстве.');
  @override
  Future<void> reconnect() async {}
  @override
  void cancelChallenge() {}
  @override
  void dispose() {}
}
