import 'package:flutter/foundation.dart';

/// Authentication state shared by the cabinet and the app menu.
class AccountSession extends ChangeNotifier {
  bool _authorized = false;
  bool get authorized => _authorized;
  void update(bool value) {
    if (_authorized == value) return;
    _authorized = value;
    notifyListeners();
  }
}
