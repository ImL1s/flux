import 'package:hive_ce/hive.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flutter/foundation.dart';
import 'hive_init.dart';

/// Implementation of [PersistenceDelegate] using Hive CE.
///
/// Handles automatic state persistence for Flux widgets.
class HivePersistenceDelegate implements PersistenceDelegate {
  static const String _boxName = 'flux_state_box';
  Box? _box;
  bool _initialized = false;

  /// Initialize Hive and open the state box.
  Future<void> init() async {
    if (_initialized) return;

    await initHivePlatform();

    _box = await Hive.openBox(_boxName);
    _initialized = true;
    debugPrint('📦 HivePersistenceDelegate initialized');
  }

  @override
  Future<dynamic> load(String key) async {
    if (!_initialized) await init();
    return _box?.get(key);
  }

  @override
  Future<void> save(String key, dynamic value) async {
    if (!_initialized) await init();
    await _box?.put(key, value);
    // debugPrint('📦 HivePersistenceDelegate: Saved $key = $value');
  }

  @override
  Future<void> delete(String key) async {
    if (!_initialized) await init();
    await _box?.delete(key);
  }

  @override
  Future<bool> exists(String key) async {
    if (!_initialized) await init();
    return _box?.containsKey(key) ?? false;
  }

  @override
  Future<void> clear() async {
    if (!_initialized) await init();
    await _box?.clear();
  }

  @override
  Future<void> dispose() async {
    if (_initialized) {
      await _box?.close();
      _initialized = false;
    }
  }
}
