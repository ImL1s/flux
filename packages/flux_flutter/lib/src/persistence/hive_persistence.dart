import 'package:hive_ce/hive.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
    
    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      final fluxDir = Directory('${appDir.path}/flux_persistence');
      if (!await fluxDir.exists()) {
        await fluxDir.create(recursive: true);
      }
      Hive.init(fluxDir.path);
    }
    
    _box = await Hive.openBox(_boxName);
    _initialized = true;
    debugPrint('📦 HivePersistenceDelegate initialized at: ${_box?.path}');
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
