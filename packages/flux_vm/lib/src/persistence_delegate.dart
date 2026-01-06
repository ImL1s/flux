/// Flux VM - Persistence Delegate Interface
///
/// This interface allows the VM to persist and restore state values.
/// Implementations can use various storage backends (Hive, SharedPreferences, etc.)

import 'dart:async';

/// Abstract interface for state persistence.
///
/// The VM calls these methods when reading/writing persistent state values.
/// Implementations should handle storage, serialization, and encryption.
abstract class PersistenceDelegate {
  /// Load a persisted value by key.
  ///
  /// Returns `null` if the key doesn't exist or loading fails.
  /// The key format is typically: `{widgetName}_{fieldName}`
  FutureOr<dynamic> load(String key);

  /// Save a value with the given key.
  ///
  /// Should handle serialization of common Dart types:
  /// - Primitives (int, double, String, bool)
  /// - Lists and Maps
  /// - Null values
  Future<void> save(String key, dynamic value);

  /// Delete a persisted value.
  ///
  /// Should not throw if the key doesn't exist.
  Future<void> delete(String key);

  /// Check if a key exists.
  Future<bool> exists(String key);

  /// Clear all persisted state.
  ///
  /// Use with caution - this removes all Flux-persisted data.
  Future<void> clear();

  /// Dispose of resources.
  ///
  /// Called when the VM is disposed.
  Future<void> dispose();
}

/// In-memory persistence delegate for testing.
///
/// Does not actually persist data across app restarts.
class InMemoryPersistenceDelegate implements PersistenceDelegate {
  final Map<String, dynamic> _store = {};

  @override
  FutureOr<dynamic> load(String key) async => _store[key];

  @override
  Future<void> save(String key, dynamic value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<bool> exists(String key) async => _store.containsKey(key);

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<void> dispose() async {
    _store.clear();
  }

  /// For testing: get all stored keys
  List<String> get keys => _store.keys.toList();

  /// For testing: get raw store
  Map<String, dynamic> get store => Map.unmodifiable(_store);
}
