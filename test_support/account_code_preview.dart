import 'package:flutter/material.dart';
import 'package:platinumstore_app/core/theme/app_theme.dart';
import 'package:platinumstore_app/features/account/data/account_gateway.dart';
import 'package:platinumstore_app/features/account/ui/account_controller.dart';
import 'package:platinumstore_app/features/account/ui/account_screen.dart';

class PreviewGateway implements AccountGateway {
  @override
  Future<Map<String, dynamic>> request(String action,
          [Map<String, String> fields = const {}]) async =>
      {'success': true};
  @override
  Future<void> reconnect() async {}
  @override
  void cancelChallenge() {}
  @override
  void dispose() {}
}

void main() {
  final account = AccountController(PreviewGateway())
    ..step = AccountStep.code
    ..phone = '79991234567'
    ..connected = true;
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AccountScreen(controller: account)));
}
