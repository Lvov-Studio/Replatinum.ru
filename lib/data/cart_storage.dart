import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

abstract class CartStorage {
  Future<List<Map<String, dynamic>>> read();
  Future<void> write(List<Map<String, dynamic>> items);
}

class FileCartStorage implements CartStorage {
  Future<File> _file() async =>
      File('${(await getApplicationSupportDirectory()).path}/cart-v1.json');

  @override
  Future<List<Map<String, dynamic>>> read() async {
    final file = await _file();
    if (!await file.exists()) return [];
    final data = jsonDecode(await file.readAsString()) as List;
    return data.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<void> write(List<Map<String, dynamic>> items) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(items), flush: true);
    await temporary.rename(file.path);
  }
}
