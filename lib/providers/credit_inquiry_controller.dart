import 'package:flutter/foundation.dart';
import '../data/api/api_service.dart';

class CreditInquiryController extends ChangeNotifier {
  CreditInquiryController(
      {required this.productId,
      required this.productName,
      required this.productUrl,
      required this.price,
      ApiService? api})
      : _api = api ?? ApiService();
  static const terms = [3, 6, 9, 12, 18, 24];
  final String productId, productName, productUrl;
  final num price;
  final ApiService _api;
  int? months;
  bool sending = false, sent = false;
  String? error;
  bool _disposed = false;
  int payment(int term) => (price / term).ceil();
  void select(int term) {
    if (!terms.contains(term) || sending || sent) return;
    months = term;
    notifyListeners();
  }

  static String normalizePhone(String phone) => phone
      .replaceAll(RegExp(r'\D'), '')
      .replaceFirst(RegExp(r'^[78](?=\d{10}$)'), '');
  Future<void> submit({required String name, required String phone}) async {
    final digits = normalizePhone(phone);
    if (sending ||
        sent ||
        months == null ||
        price <= 0 ||
        digits.length != 10) {
      return;
    }
    sending = true;
    error = null;
    notifyListeners();
    try {
      await _api.submitCreditInquiry(
          productId: productId,
          productName: productName,
          productUrl: productUrl,
          price: price,
          months: months!,
          name: name.trim(),
          phone: digits);
      if (!_disposed) sent = true;
    } catch (_) {
      if (!_disposed) {
        error =
            'Не удалось подтвердить отправку заявки. Попробуйте позже или уточните её статус у менеджера.';
      }
    } finally {
      sending = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
