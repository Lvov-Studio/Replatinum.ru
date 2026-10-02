import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/account_gateway.dart';

enum AccountStep { phone, code, registration, account }

class AccountController extends ChangeNotifier {
  AccountController(this.gateway, {DateTime Function()? now})
      : _now = now ?? DateTime.now;
  final AccountGateway gateway;
  final DateTime Function() _now;
  AccountStep step = AccountStep.phone;
  bool busy = false, connected = false, initialized = false;
  String error = '', phone = '';
  Map<String, dynamic>? profile;
  Map<String, dynamic>? summary, address, orderDetail;
  List<Map<String, dynamic>> orders = [];
  bool hasMoreOrders = false;
  int _orderOffset = 0, _version = 0;
  DateTime? _resendAt;
  Timer? _clock;
  bool _disposed = false;
  int get resendSeconds => _resendAt == null
      ? 0
      : _resendAt!.difference(_now()).inSeconds.clamp(0, 60);
  static String normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 && digits.startsWith('9')) return '7$digits';
    if (digits.length == 11 &&
        (digits.startsWith('7') || digits.startsWith('8')) &&
        digits[1] == '9') {
      return '7${digits.substring(1)}';
    }
    return '';
  }

  Future<void> _run(Future<void> Function(int version) work) async {
    if (busy || _disposed) return;
    final version = ++_version;
    busy = true;
    error = '';
    notifyListeners();
    try {
      await work(version);
    } catch (failure) {
      if (!_current(version)) return;
      if (failure is AccountFailure && failure.unauthorized) {
        _clearAccount();
        connected = false;
        step = AccountStep.phone;
      }
      error = failure is AccountFailure
          ? failure.message
          : 'Не удалось выполнить действие. Попробуйте ещё раз.';
    } finally {
      if (_current(version)) {
        busy = false;
        notifyListeners();
      }
    }
  }

  bool _current(int version) => !_disposed && _version == version;
  Future<void> initialize({bool reconnect = false}) => _run((version) async {
        if (reconnect) await gateway.reconnect();
        final result = await gateway.request('bootstrap');
        if (!_current(version)) return;
        connected = true;
        initialized = true;
        if (result['authorized'] == true) {
          await _rememberSession();
          await _loadAccount(version);
        } else {
          _clearAccount();
          step = AccountStep.phone;
        }
      });
  Future<void> sendCode(String input) async {
    if (busy || resendSeconds > 0) return;
    final normalized = normalizePhone(input);
    if (normalized.isEmpty) {
      error = 'Введите российский мобильный номер.';
      notifyListeners();
      return;
    }
    await _run((version) async {
      await gateway.request('send_code', {'phone': normalized});
      if (!_current(version)) return;
      phone = normalized;
      step = AccountStep.code;
      _resendAt = _now().add(const Duration(seconds: 60));
      _clock?.cancel();
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_disposed) return;
        if (resendSeconds == 0) _clock?.cancel();
        notifyListeners();
      });
    });
  }

  Future<void> verifyCode(String code) async {
    if (!RegExp(r'^\d{4}$').hasMatch(code)) {
      error = 'Введите четыре цифры из SMS.';
      notifyListeners();
      return;
    }
    await _run((version) async {
      final result =
          await gateway.request('verify_code', {'phone': phone, 'code': code});
      if (!_current(version)) return;
      if (result['need_register'] == true) {
        _clock?.cancel();
        step = AccountStep.registration;
      } else {
        await _rememberSession();
        await _loadAccount(version);
      }
    });
  }

  Future<void> register(String name, String lastName, bool consent) async {
    if (name.trim().isEmpty || lastName.trim().isEmpty || !consent) {
      error = 'Укажите имя, фамилию и согласие на обработку данных.';
      notifyListeners();
      return;
    }
    await _run((version) async {
      await gateway.request('register', {
        'name': name.trim(),
        'last_name': lastName.trim(),
        'consent': '1',
        'subscribe': '0'
      });
      await _rememberSession();
      await _loadAccount(version);
    });
  }

  Future<void> _rememberSession() async {
    await gateway.reconnect();
    await gateway.request('remember');
    // Authorize may rotate the PHP session; reload before further CSRF requests.
    await gateway.reconnect();
  }

  Future<void> _loadAccount(int version) async {
    final session = await gateway.request('bootstrap');
    if (session['authorized'] != true) {
      throw const AccountFailure('Войдите в аккаунт.', unauthorized: true);
    }
    if (_current(version)) step = AccountStep.account;
    final result = await gateway.request('profile');
    if (!_current(version)) return;
    profile = Map<String, dynamic>.from(result['profile'] as Map);
    step = AccountStep.account;
    connected = true;
    _clock?.cancel();
    _resendAt = null;
    final totals = await gateway.request('summary');
    if (_current(version)) {
      summary = Map<String, dynamic>.from(totals['summary'] as Map);
    }
  }

  Future<void> loadSummary() => _run((version) async {
        final result = await gateway.request('summary');
        if (_current(version)) {
          summary = Map<String, dynamic>.from(result['summary'] as Map);
        }
      });
  Future<void> loadAddress() => _run((version) async {
        final result = await gateway.request('address');
        if (_current(version)) {
          address = Map<String, dynamic>.from(result['address'] as Map);
        }
      });
  Future<void> saveAddress(String city, String street) => _run((version) async {
        final result = await gateway.request(
            'address_update', {'city': city.trim(), 'street': street.trim()});
        if (_current(version)) {
          address = Map<String, dynamic>.from(result['address'] as Map);
        }
      });
  Future<void> loadOrderDetail(String id) async {
    if (busy) return;
    orderDetail = null;
    await _run((version) async {
      final result = await gateway.request('order_detail', {'id': id});
      if (_current(version)) {
        orderDetail = Map<String, dynamic>.from(result['order'] as Map);
      }
    });
  }

  Future<void> loadOrders({bool more = false}) => _run((version) async {
        final result = await gateway
            .request('orders', {'offset': more ? '$_orderOffset' : '0'});
        if (!_current(version)) return;
        final next = (result['orders'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        orders = more ? [...orders, ...next] : next;
        _orderOffset = result['next_offset'] as int;
        hasMoreOrders = result['has_more'] == true;
      });
  Future<void> saveProfile(String name, String lastName, String email) =>
      _run((version) async {
        final result = await gateway.request('profile_update', {
          'name': name.trim(),
          'last_name': lastName.trim(),
          'email': email.trim()
        });
        if (_current(version)) {
          profile = Map<String, dynamic>.from(result['profile'] as Map);
        }
      });
  Future<void> logout() => _run((version) async {
        await gateway.request('logout');
        if (!_current(version)) return;
        _clearAccount();
        phone = '';
        step = AccountStep.phone;
        _resendAt = null;
        connected = false;
        await gateway.reconnect();
        await gateway.request('bootstrap');
        if (_current(version)) connected = true;
      });

  void _clearAccount() {
    profile = null;
    summary = null;
    address = null;
    orderDetail = null;
    orders = [];
    hasMoreOrders = false;
    _orderOffset = 0;
  }

  void changePhone() {
    if (busy) return;
    step = AccountStep.phone;
    error = '';
    notifyListeners();
  }

  void cancelChallenge() {
    gateway.cancelChallenge();
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    _clock?.cancel();
    gateway.dispose();
    super.dispose();
  }
}
