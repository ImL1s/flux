import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Migration callback type
typedef MigrationCallback = Future<void> Function();

/// State migration utility for managing versioned app state
///
/// Provides a mechanism to handle state migrations when your app's
/// data schema changes between versions.
///
/// Basic usage:
/// ```dart
/// final migration = StateMigration();
///
/// migration.register(1, () async {
///   // Migration from version 0 to 1
///   await migrateOldKeys();
/// });
///
/// migration.register(2, () async {
///   // Migration from version 1 to 2
///   await updateDataFormat();
/// });
///
/// // Run all pending migrations
/// await migration.runMigrations(2);
/// ```
class StateMigration {
  static const String _versionKey = '_flux_state_version';

  final Map<int, MigrationCallback> _migrations = {};
  final SharedPreferences? _prefs;

  /// Create a StateMigration instance.
  /// Optionally pass a SharedPreferences instance for testing.
  StateMigration({SharedPreferences? prefs}) : _prefs = prefs;

  /// Register a migration for a specific version.
  /// The callback will be executed when migrating TO this version.
  void register(int version, MigrationCallback callback) {
    if (version < 1) {
      throw ArgumentError('Version must be >= 1');
    }
    _migrations[version] = callback;
  }

  /// Get the current state version from SharedPreferences.
  Future<int> getCurrentVersion() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return prefs.getInt(_versionKey) ?? 0;
  }

  /// Set the current state version in SharedPreferences.
  Future<void> setCurrentVersion(int version) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setInt(_versionKey, version);
  }

  /// Run all pending migrations up to the target version.
  /// Returns a list of versions that were migrated.
  Future<List<int>> runMigrations(int targetVersion) async {
    final currentVersion = await getCurrentVersion();
    final migratedVersions = <int>[];

    if (currentVersion >= targetVersion) {
      debugPrint(
          'StateMigration: Already at version $currentVersion, no migrations needed');
      return migratedVersions;
    }

    debugPrint(
        'StateMigration: Migrating from version $currentVersion to $targetVersion');

    // Run migrations in order
    for (var version = currentVersion + 1;
        version <= targetVersion;
        version++) {
      final migration = _migrations[version];
      if (migration != null) {
        debugPrint('StateMigration: Running migration to version $version');
        try {
          await migration();
          migratedVersions.add(version);
        } catch (e) {
          debugPrint(
              'StateMigration: Migration to version $version failed: $e');
          rethrow;
        }
      } else {
        debugPrint(
            'StateMigration: No migration registered for version $version, skipping');
      }

      // Update version after each successful migration
      await setCurrentVersion(version);
    }

    debugPrint(
        'StateMigration: Migration complete. Migrated versions: $migratedVersions');
    return migratedVersions;
  }

  /// Check if migrations are needed to reach the target version.
  Future<bool> needsMigration(int targetVersion) async {
    final currentVersion = await getCurrentVersion();
    return currentVersion < targetVersion;
  }

  /// Get the list of registered migration versions.
  List<int> getRegisteredVersions() {
    return _migrations.keys.toList()..sort();
  }

  /// Clear all registered migrations.
  void clearMigrations() {
    _migrations.clear();
  }

  /// Get pending migration versions between current and target.
  Future<List<int>> getPendingMigrations(int targetVersion) async {
    final currentVersion = await getCurrentVersion();
    final pending = <int>[];

    for (var version = currentVersion + 1;
        version <= targetVersion;
        version++) {
      if (_migrations.containsKey(version)) {
        pending.add(version);
      }
    }

    return pending;
  }

  /// Reset state version to 0 (useful for testing).
  Future<void> resetVersion() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_versionKey);
  }
}
