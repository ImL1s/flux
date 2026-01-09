import 'dart:convert';

import 'package:flux_vm/flux_vm.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Hive-based storage module for Flux
///
/// Provides advanced local storage with boxes (collections) for storing
/// complex objects and collections.
///
/// Basic usage:
/// ```flux
/// // Open a box
/// await hive.openBox("myBox");
///
/// // Store data
/// await hive.put("myBox", "key", {name: "John", age: 30});
///
/// // Retrieve data
/// var data = await hive.get("myBox", "key");
///
/// // Delete data
/// await hive.delete("myBox", "key");
///
/// // Get all values
/// var all = await hive.getAll("myBox");
///
/// // Close box when done
/// await hive.closeBox("myBox");
/// ```
class HiveStorageModule extends FluxModule {
  final Map<String, Box<String>> _openBoxes = {};
  bool _initialized = false;

  /// Optional custom path for testing purposes
  final String? _testPath;

  /// Create a HiveStorageModule with optional test path for unit testing.
  /// When [testPath] is provided, it will be used instead of path_provider.
  HiveStorageModule({String? testPath})
      : _testPath = testPath,
        super('hive') {
    // Box lifecycle
    register('init', AsyncNativeFunction('hive.init', 0, _init));
    register('openBox', AsyncNativeFunction('hive.openBox', 1, _openBox));
    register('closeBox', AsyncNativeFunction('hive.closeBox', 1, _closeBox));
    register('deleteBox', AsyncNativeFunction('hive.deleteBox', 1, _deleteBox));
    register('isBoxOpen', NativeFunction('hive.isBoxOpen', 1, _isBoxOpen));

    // CRUD operations
    register('put', AsyncNativeFunction('hive.put', 3, _put));
    register('get', AsyncNativeFunction('hive.get', 2, _get));
    register('delete', AsyncNativeFunction('hive.delete', 2, _delete));
    register('clear', AsyncNativeFunction('hive.clear', 1, _clear));

    // Query operations
    register('getAll', AsyncNativeFunction('hive.getAll', 1, _getAll));
    register(
        'getAllKeys', AsyncNativeFunction('hive.getAllKeys', 1, _getAllKeys));
    register('containsKey',
        AsyncNativeFunction('hive.containsKey', 2, _containsKey));
    register('count', AsyncNativeFunction('hive.count', 1, _count));
  }

  // ==================== Box Lifecycle ====================

  /// Initialize Hive with the default directory
  Future<Object?> _init(List<Object?> args) async {
    if (_initialized) return true;

    final String path;
    if (_testPath != null) {
      path = _testPath;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      path = directory.path;
    }

    Hive.init(path);
    _initialized = true;
    return true;
  }

  /// Open a named box
  Future<Object?> _openBox(List<Object?> args) async {
    final boxName = args[0] as String;

    // Auto-initialize if needed
    if (!_initialized) {
      await _init([]);
    }

    if (_openBoxes.containsKey(boxName)) {
      return true; // Already open
    }

    final box = await Hive.openBox<String>(boxName);
    _openBoxes[boxName] = box;
    return true;
  }

  /// Close a named box
  Future<Object?> _closeBox(List<Object?> args) async {
    final boxName = args[0] as String;
    final box = _openBoxes.remove(boxName);
    if (box != null) {
      await box.close();
    }
    return null;
  }

  /// Delete a box permanently
  Future<Object?> _deleteBox(List<Object?> args) async {
    final boxName = args[0] as String;

    // Close if open
    await _closeBox([boxName]);

    // Delete the box
    await Hive.deleteBoxFromDisk(boxName);
    return null;
  }

  /// Check if a box is currently open
  Object? _isBoxOpen(List<Object?> args) {
    final boxName = args[0] as String;
    return _openBoxes.containsKey(boxName);
  }

  // ==================== CRUD Operations ====================

  /// Store a value (JSON-serialized)
  Future<Object?> _put(List<Object?> args) async {
    final boxName = args[0] as String;
    final key = args[1] as String;
    final value = args[2];

    final box = await _ensureBoxOpen(boxName);

    try {
      final jsonValue = jsonEncode(value);
      await box.put(key, jsonValue);
    } catch (e) {
      throw ArgumentError('Value is not JSON-serializable: $e');
    }
    return null;
  }

  /// Get a value (JSON-deserialized)
  Future<Object?> _get(List<Object?> args) async {
    final boxName = args[0] as String;
    final key = args[1] as String;

    final box = await _ensureBoxOpen(boxName);
    final jsonValue = box.get(key);

    if (jsonValue == null) return null;

    try {
      return jsonDecode(jsonValue);
    } catch (e) {
      return null;
    }
  }

  /// Delete a key
  Future<Object?> _delete(List<Object?> args) async {
    final boxName = args[0] as String;
    final key = args[1] as String;

    final box = await _ensureBoxOpen(boxName);
    await box.delete(key);
    return null;
  }

  /// Clear all entries in a box
  Future<Object?> _clear(List<Object?> args) async {
    final boxName = args[0] as String;

    final box = await _ensureBoxOpen(boxName);
    await box.clear();
    return null;
  }

  // ==================== Query Operations ====================

  /// Get all values as a list
  Future<Object?> _getAll(List<Object?> args) async {
    final boxName = args[0] as String;

    final box = await _ensureBoxOpen(boxName);
    final results = <Object?>[];

    for (final jsonValue in box.values) {
      try {
        results.add(jsonDecode(jsonValue));
      } catch (e) {
        results.add(null);
      }
    }

    return results;
  }

  /// Get all keys
  Future<Object?> _getAllKeys(List<Object?> args) async {
    final boxName = args[0] as String;

    final box = await _ensureBoxOpen(boxName);
    return box.keys.toList();
  }

  /// Check if a key exists
  Future<Object?> _containsKey(List<Object?> args) async {
    final boxName = args[0] as String;
    final key = args[1] as String;

    final box = await _ensureBoxOpen(boxName);
    return box.containsKey(key);
  }

  /// Get the number of entries
  Future<Object?> _count(List<Object?> args) async {
    final boxName = args[0] as String;

    final box = await _ensureBoxOpen(boxName);
    return box.length;
  }

  // ==================== Helpers ====================

  Future<Box<String>> _ensureBoxOpen(String boxName) async {
    if (!_openBoxes.containsKey(boxName)) {
      await _openBox([boxName]);
    }
    return _openBoxes[boxName]!;
  }

  /// Clean up when the module is disposed
  Future<void> dispose() async {
    for (final box in _openBoxes.values) {
      await box.close();
    }
    _openBoxes.clear();
  }
}
