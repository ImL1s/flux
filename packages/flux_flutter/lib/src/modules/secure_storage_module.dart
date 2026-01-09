import 'dart:convert';

import 'package:flux_vm/flux_vm.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage module for Flux using AES-256 encryption
///
/// Provides encrypted local storage for sensitive data like tokens,
/// credentials, and private keys.
///
/// Basic usage:
/// ```flux
/// // Store sensitive data
/// await secure.set("apiToken", "secret_token_123");
///
/// // Retrieve data
/// var token = await secure.get("apiToken");
///
/// // Delete sensitive data
/// await secure.delete("apiToken");
///
/// // Store JSON securely
/// await secure.setJson("credentials", {username: "user", password: "pass"});
/// ```
class SecureStorageModule extends FluxModule {
  final FlutterSecureStorage _storage;

  /// Storage options for Android (encryption is enabled by default in v10+)
  AndroidOptions get _androidOptions => const AndroidOptions();

  /// Storage options for iOS
  IOSOptions get _iosOptions => const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      );

  /// Create a SecureStorageModule with optional custom storage for testing.
  SecureStorageModule({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super('secure') {
    // Basic CRUD
    register('get', AsyncNativeFunction('secure.get', 1, _get));
    register('set', AsyncNativeFunction('secure.set', 2, _set));
    register('delete', AsyncNativeFunction('secure.delete', 1, _delete));
    register(
        'deleteAll', AsyncNativeFunction('secure.deleteAll', 0, _deleteAll));
    register('containsKey',
        AsyncNativeFunction('secure.containsKey', 1, _containsKey));

    // JSON operations
    register('getJson', AsyncNativeFunction('secure.getJson', 1, _getJson));
    register('setJson', AsyncNativeFunction('secure.setJson', 2, _setJson));

    // Utility
    register(
        'getAllKeys', AsyncNativeFunction('secure.getAllKeys', 0, _getAllKeys));
    register('getAll', AsyncNativeFunction('secure.getAll', 0, _getAll));
  }

  // ==================== Basic CRUD ====================

  /// Get a string value from secure storage
  Future<Object?> _get(List<Object?> args) async {
    final key = args[0] as String;
    return await _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  /// Store a string value securely
  Future<Object?> _set(List<Object?> args) async {
    final key = args[0] as String;
    final value = args[1]?.toString() ?? '';
    await _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    return null;
  }

  /// Delete a key from secure storage
  Future<Object?> _delete(List<Object?> args) async {
    final key = args[0] as String;
    await _storage.delete(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    return null;
  }

  /// Delete all data from secure storage
  Future<Object?> _deleteAll(List<Object?> args) async {
    await _storage.deleteAll(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    return null;
  }

  /// Check if a key exists in secure storage
  Future<Object?> _containsKey(List<Object?> args) async {
    final key = args[0] as String;
    return await _storage.containsKey(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  // ==================== JSON Operations ====================

  /// Get a JSON-decoded object from secure storage
  Future<Object?> _getJson(List<Object?> args) async {
    final key = args[0] as String;
    final jsonString = await _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );

    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// Store an object as JSON in secure storage
  Future<Object?> _setJson(List<Object?> args) async {
    final key = args[0] as String;
    final value = args[1];

    try {
      final jsonString = jsonEncode(value);
      await _storage.write(
        key: key,
        value: jsonString,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      throw ArgumentError('Value is not JSON-serializable: $e');
    }
    return null;
  }

  // ==================== Utility ====================

  /// Get all keys from secure storage
  Future<Object?> _getAllKeys(List<Object?> args) async {
    final all = await _storage.readAll(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    return all.keys.toList();
  }

  /// Get all key-value pairs from secure storage (values as strings)
  Future<Object?> _getAll(List<Object?> args) async {
    return await _storage.readAll(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }
}
