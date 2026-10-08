import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/api/api_service.dart';
import '../../account/data/account_gateway.dart';
import '../data/checkout_gateway.dart';

class CheckoutController extends ChangeNotifier {
  CheckoutController(this.cart, this.gateway) {
    if (cart.pendingCheckout case final pending?) {
      _pendingPayload = Map.of(pending);
      deliveryType = '${pending['delivery_type']}';
      pickupStore = '${pending['pickup_store']}';
    }
  }
  final CartProvider cart;
  final CheckoutGateway gateway;
  bool loading = false, ready = false, submitting = false, _disposed = false;
  bool authorized = false;
  String error = '';
  Map<String, dynamic> profile = {};
  List<Map<String, dynamic>> stores = [];
  int cityDeliveryMinor = 0;
  String deliveryType = 'pickup', pickupStore = '';
  Map<String, dynamic>? _pendingPayload;
  int? orderId;
  bool get awaitingConfirmation => _pendingPayload != null;
  int get deliveryMinor => deliveryType == 'delivery' ? cityDeliveryMinor : 0;
  int get totalMinor =>
      _pendingPayload?['expected_total_minor'] as int? ??
      (cart.quote?.totalMinor ?? 0) + deliveryMinor;

  Future<void> initialize() async {
    if (loading || _disposed) return;
    loading = true;
    error = '';
    notifyListeners();
    try {
      final data = await gateway.context();
      if (_disposed) return;
      if (data['schema_version'] != 1 ||
          data['city_delivery_minor'] is! int ||
          (data['city_delivery_minor'] as int) < 0 ||
          data['pickup_stores'] is! List ||
          !(data['payment_types'] as List? ?? []).contains('cash')) {
        throw const FormatException('Unsupported checkout');
      }
      cityDeliveryMinor = data['city_delivery_minor'] as int;
      authorized = data['authorized'] == true;
      stores = (data['pickup_stores'] as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});
      if (_pendingPayload != null) profile.addAll(_pendingPayload!);
      ready = true;
    } catch (failure) {
      if (_disposed) return;
      error = failure is AccountFailure
          ? failure.message
          : 'Не удалось загрузить условия оформления. Повторите попытку.';
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void chooseDelivery(String type) {
    if (submitting ||
        awaitingConfirmation ||
        !['pickup', 'delivery', 'express'].contains(type)) {
      return;
    }
    deliveryType = type;
    notifyListeners();
  }

  void chooseStore(String id) {
    if (submitting ||
        awaitingConfirmation ||
        !stores
            .any((store) => store['id'] == id && store['available'] == true)) {
      return;
    }
    pickupStore = id;
    notifyListeners();
  }

  static String normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) digits = '7$digits';
    if (digits.length == 11 && digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    }
    return RegExp(r'^7\d{10}$').hasMatch(digits) ? digits : '';
  }

  static String? validateName(String? value) =>
      (value ?? '').trim().isEmpty ? 'Введите имя получателя' : null;
  static String? validatePhone(String? value) =>
      normalizePhone(value ?? '').isEmpty
          ? 'Введите полный номер телефона'
          : null;
  static String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    return email.isEmpty ||
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? null
        : 'Проверьте email';
  }

  Future<bool> submit(Map<String, String> fields,
      {required bool consent}) async {
    if (submitting || !ready || _disposed || orderId != null) return false;
    error = '';
    if (_pendingPayload == null) {
      error = validateName(fields['first_name']) ??
          validatePhone(fields['phone']) ??
          validateEmail(fields['email']) ??
          '';
      if (error.isEmpty && !consent) {
        error = 'Подтвердите согласие на обработку данных.';
      }
      if (error.isEmpty &&
          deliveryType == 'pickup' &&
          !stores.any((store) =>
              store['id'] == pickupStore && store['available'] == true)) {
        error = 'Выберите магазин самовывоза.';
      }
      if (error.isEmpty &&
          deliveryType != 'pickup' &&
          (fields['delivery_address'] ?? '').trim().isEmpty) {
        error = 'Введите адрес доставки.';
      }
      if (error.isNotEmpty) {
        notifyListeners();
        return false;
      }
    }
    if (!(_pendingPayload != null && cart.checkoutInProgress) &&
        !cart.beginCheckout()) {
      error = 'Проверьте выбранные товары и повторите проверку цены в корзине.';
      notifyListeners();
      return false;
    }
    submitting = true;
    notifyListeners();
    var completed = false;
    try {
      if (_pendingPayload == null) {
        final previousQuote = cart.quote!.id;
        if (!await cart.refreshQuote()) throw AccountFailure(cart.quoteError);
        if (_disposed) return false;
        if (cart.quote!.id != previousQuote) {
          throw const AccountFailure(
              'Цена или скидка изменилась. Проверьте новый итог и подтвердите ещё раз.');
        }
        _pendingPayload = {
          for (final entry in fields.entries) entry.key: entry.value.trim(),
          'phone': normalizePhone(fields['phone'] ?? ''),
          'items': cart.orderItems,
          'quote_id': cart.quote!.id,
          'expected_total_minor': totalMinor,
          'consent': true,
          'delivery_type': deliveryType,
          'pickup_store': deliveryType == 'pickup' ? pickupStore : '',
          'payment_type': 'cash',
          'request_id': List.generate(16, (_) => Random.secure().nextInt(256))
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join(),
        };
      }
      if (cart.pendingCheckout == null) {
        await cart.rememberCheckout(_pendingPayload!);
      }
      final response = await gateway.submit(_pendingPayload!);
      final id = int.tryParse('${response['order_id']}');
      if (response['success'] != true || id == null || id <= 0) {
        throw const AccountFailure(
            'Сервер не подтвердил номер заказа. Повторите подтверждение.',
            uncertain: true);
      }
      orderId = id;
      completed = true;
      _pendingPayload = null;
      return true;
    } catch (failure) {
      if (failure is CartApiFailure) {
        _pendingPayload = null;
        if (!_disposed) error = failure.message;
        return false;
      }
      final uncertain = failure is! AccountFailure || failure.uncertain;
      if (!uncertain) _pendingPayload = null;
      if (!_disposed) {
        error = uncertain
            ? 'Результат отправки пока не подтверждён. Нажмите «Проверить заказ», чтобы повторно получить ответ.'
            : (failure).message;
      }
      return false;
    } finally {
      if (completed || _pendingPayload == null) {
        cart.endCheckout(completed: completed);
      }
      if (!_disposed) {
        submitting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    gateway.dispose();
    super.dispose();
  }
}
