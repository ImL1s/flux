import 'dart:convert';

import 'package:flux_vm/flux_vm.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage module for Flux
///
/// Basic usage:
/// ```flux
/// await storage.set("key", "value");
/// var val = await storage.get("key");
/// ```
///
/// JSON support:
/// ```flux
/// await storage.setJson("user", {name: "John", age: 30});
/// var user = await storage.getJson("user");
/// ```
///
/// Type-specific methods:
/// ```flux
/// await storage.setInt("count", 42);
/// await storage.setBool("enabled", true);
/// await storage.setDouble("ratio", 3.14);
/// ```
class StorageModule extends FluxModule {
  StorageModule() : super('storage') {
    // String operations (existing)
    register('get', AsyncNativeFunction('storage.get', 1, _get));
    register('set', AsyncNativeFunction('storage.set', 2, _set));
    register('remove', AsyncNativeFunction('storage.remove', 1, _remove));
    register('clear', AsyncNativeFunction('storage.clear', 0, _clear));
    register(
        'containsKey', AsyncNativeFunction('storage.containsKey', 1, _containsKey));

    // JSON operations (new)
    register('getJson', AsyncNativeFunction('storage.getJson', 1, _getJson));
    register('setJson', AsyncNativeFunction('storage.setJson', 2, _setJson));

    // Type-specific operations (new)
    register('getInt', AsyncNativeFunction('storage.getInt', 1, _getInt));
    register('setInt', AsyncNativeFunction('storage.setInt', 2, _setInt));
    register('getBool', AsyncNativeFunction('storage.getBool', 1, _getBool));
    register('setBool', AsyncNativeFunction('storage.setBool', 2, _setBool));
    register('getDouble', AsyncNativeFunction('storage.getDouble', 1, _getDouble));
    register('setDouble', AsyncNativeFunction('storage.setDouble', 2, _setDouble));

    // List operations (new)
    register('getStringList',
        AsyncNativeFunction('storage.getStringList', 1, _getStringList));
    register('setStringList',
        AsyncNativeFunction('storage.setStringList', 2, _setStringList));

    // Utility (new)
    register('getKeys', AsyncNativeFunction('storage.getKeys', 0, _getKeys));
  }

  // ==================== String Operations ====================

  Future<Object?> _get(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<Object?> _set(List<Object?> args) async {
    final key = args[0] as String;
    final value = args[1]?.toString() ?? '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    return null;
  }

  Future<Object?> _remove(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    return null;
  }

  Future<Object?> _clear(List<Object?> args) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    return null;
  }

  Future<Object?> _containsKey(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  // ==================== JSON Operations ====================

  /// Get a JSON-decoded object from storage
  Future<Object?> _getJson(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString);
    } catch (e) {
      // Return null if JSON is invalid
      return null;
    }
  }

  /// Store an object as JSON
  Future<Object?> _setJson(List<Object?> args) async {
    final key = args[0] as String;
    final value = args[1];
    final prefs = await SharedPreferences.getInstance();

    try {
      final jsonString = jsonEncode(value);
      await prefs.setString(key, jsonString);
    } catch (e) {
      throw ArgumentError('Value is not JSON-serializable: $e');
    }
    return null;
  }

  // ==================== Type-Specific Operations ====================

  Future<Object?> _getInt(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<Object?> _setInt(List<Object?> args) async {
    final key = args[0] as String;
    final value = _toInt(args[1]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    return null;
  }

  Future<Object?> _getBool(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<Object?> _setBool(List<Object?> args) async {
    final key = args[0] as String;
    final value = _toBool(args[1]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    return null;
  }

  Future<Object?> _getDouble(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  Future<Object?> _setDouble(List<Object?> args) async {
    final key = args[0] as String;
    final value = _toDouble(args[1]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
    return null;
  }

  // ==================== List Operations ====================

  Future<Object?> _getStringList(List<Object?> args) async {
    final key = args[0] as String;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  Future<Object?> _setStringList(List<Object?> args) async {
    final key = args[0] as String;
    final value = _toStringList(args[1]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
    return null;
  }

  // ==================== Utility ====================

  /// Get all keys in storage
  Future<Object?> _getKeys(List<Object?> args) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().toList();
  }

  // ==================== Helpers ====================

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _toBool(Object? value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  List<String> _toStringList(Object? value) {
    if (value is List<String>) return value;
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
