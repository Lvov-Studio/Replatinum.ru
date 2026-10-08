import 'dart:convert';
import '../../account/data/account_gateway.dart';

abstract class CheckoutGateway {
  Future<Map<String, dynamic>> context();
  Future<Map<String, dynamic>> submit(Map<String, dynamic> payload);
  void dispose();
}

class SiteCheckoutGateway implements CheckoutGateway {
  final SiteAccountGateway _account = SiteAccountGateway(onChallenge: (_) {});
  bool _contextLoaded = false;
  @override
  Future<Map<String, dynamic>> context() async {
    // Login can rotate the PHP session and its CSRF token in another WebView.
    if (_contextLoaded) await _account.reconnect();
    final result = await _account.request('checkout_context');
    _contextLoaded = true;
    return result;
  }

  @override
  Future<Map<String, dynamic>> submit(Map<String, dynamic> payload) =>
      _account.request('checkout_submit', {'payload': jsonEncode(payload)});
  @override
  void dispose() => _account.dispose();
}
