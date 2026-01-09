import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/utils/state_migration.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StateMigration migration;
  late List<int> executedMigrations;

  setUp(() async {
    // Set up fake SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    migration = StateMigration(prefs: prefs);
    executedMigrations = [];
  });

  tearDown(() async {
    migration.clearMigrations();
    await migration.resetVersion();
  });

  group('Registration', () {
    test('register adds migration callbacks', () {
      migration.register(1, () async => executedMigrations.add(1));
      migration.register(2, () async => executedMigrations.add(2));
      migration.register(3, () async => executedMigrations.add(3));

      expect(migration.getRegisteredVersions(), [1, 2, 3]);
    });

    test('register throws for version < 1', () {
      expect(
        () => migration.register(0, () async {}),
        throwsArgumentError,
      );
      expect(
        () => migration.register(-1, () async {}),
        throwsArgumentError,
      );
    });

    test('clearMigrations removes all registered migrations', () {
      migration.register(1, () async {});
      migration.register(2, () async {});

      migration.clearMigrations();
      expect(migration.getRegisteredVersions(), isEmpty);
    });
  });

  group('Version Management', () {
    test('getCurrentVersion returns 0 for fresh state', () async {
      expect(await migration.getCurrentVersion(), 0);
    });

    test('setCurrentVersion updates version', () async {
      await migration.setCurrentVersion(5);
      expect(await migration.getCurrentVersion(), 5);
    });

    test('resetVersion resets to 0', () async {
      await migration.setCurrentVersion(10);
      await migration.resetVersion();
      expect(await migration.getCurrentVersion(), 0);
    });
  });

  group('needsMigration', () {
    test('returns true when current < target', () async {
      expect(await migration.needsMigration(1), true);
    });

    test('returns false when current >= target', () async {
      await migration.setCurrentVersion(5);
      expect(await migration.needsMigration(5), false);
      expect(await migration.needsMigration(3), false);
    });
  });

  group('getPendingMigrations', () {
    test('returns pending migrations between current and target', () async {
      migration.register(1, () async {});
      migration.register(2, () async {});
      migration.register(3, () async {});
      migration.register(5, () async {});

      final pending = await migration.getPendingMigrations(5);
      expect(pending, [1, 2, 3, 5]);
    });

    test('returns only pending migrations after current version', () async {
      await migration.setCurrentVersion(2);

      migration.register(1, () async {});
      migration.register(2, () async {});
      migration.register(3, () async {});
      migration.register(5, () async {});

      final pending = await migration.getPendingMigrations(5);
      expect(pending, [3, 5]);
    });

    test('returns empty list when no pending', () async {
      await migration.setCurrentVersion(5);

      migration.register(1, () async {});
      migration.register(2, () async {});

      final pending = await migration.getPendingMigrations(5);
      expect(pending, isEmpty);
    });
  });

  group('runMigrations', () {
    test('runs migrations in order', () async {
      migration.register(1, () async => executedMigrations.add(1));
      migration.register(2, () async => executedMigrations.add(2));
      migration.register(3, () async => executedMigrations.add(3));

      await migration.runMigrations(3);

      expect(executedMigrations, [1, 2, 3]);
      expect(await migration.getCurrentVersion(), 3);
    });

    test('runs only pending migrations', () async {
      await migration.setCurrentVersion(1);

      migration.register(1, () async => executedMigrations.add(1));
      migration.register(2, () async => executedMigrations.add(2));
      migration.register(3, () async => executedMigrations.add(3));

      await migration.runMigrations(3);

      expect(executedMigrations, [2, 3]);
      expect(await migration.getCurrentVersion(), 3);
    });

    test('returns list of migrated versions', () async {
      migration.register(1, () async => executedMigrations.add(1));
      migration.register(2, () async => executedMigrations.add(2));
      migration.register(3, () async => executedMigrations.add(3));

      final result = await migration.runMigrations(3);
      expect(result, [1, 2, 3]);
    });

    test('skips unregistered versions', () async {
      migration.register(1, () async => executedMigrations.add(1));
      migration.register(3, () async => executedMigrations.add(3));

      await migration.runMigrations(3);

      expect(executedMigrations, [1, 3]);
      expect(await migration.getCurrentVersion(), 3);
    });

    test('returns empty list when no migrations needed', () async {
      await migration.setCurrentVersion(5);

      migration.register(1, () async => executedMigrations.add(1));
      migration.register(2, () async => executedMigrations.add(2));

      final result = await migration.runMigrations(3);

      expect(result, isEmpty);
      expect(executedMigrations, isEmpty);
    });

    test('rethrows migration errors but preserves progress', () async {
      migration.register(1, () async => executedMigrations.add(1));
      migration.register(2, () async {
        throw Exception('Migration failed');
      });
      migration.register(3, () async => executedMigrations.add(3));

      try {
        await migration.runMigrations(3);
        fail('Expected exception to be thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      // Version 1 was completed
      expect(executedMigrations, [1]);
      expect(await migration.getCurrentVersion(), 1);
    });
  });

  group('State Migration Scenarios', () {
    test('simulate app upgrade from v0 to v3', () async {
      var legacyData = {'old_key': 'old_value'};
      var currentData = <String, dynamic>{};

      migration.register(1, () async {
        // v1: Migrate legacy data format
        currentData['new_key'] = legacyData['old_key'];
        legacyData.clear();
      });

      migration.register(2, () async {
        // v2: Add new required field
        currentData['version'] = 2;
      });

      migration.register(3, () async {
        // v3: Restructure data
        currentData = {
          'data': currentData,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        };
      });

      await migration.runMigrations(3);

      expect(legacyData, isEmpty);
      expect(currentData['data']['new_key'], 'old_value');
      expect(currentData['data']['version'], 2);
      expect(currentData.containsKey('timestamp'), true);
    });

    test('incremental migrations work correctly', () async {
      // First app launch
      migration.register(1, () async => executedMigrations.add(1));
      await migration.runMigrations(1);
      expect(executedMigrations, [1]);

      // App update to v2
      migration.register(2, () async => executedMigrations.add(2));
      await migration.runMigrations(2);
      expect(executedMigrations, [1, 2]);

      // App update to v3
      migration.register(3, () async => executedMigrations.add(3));
      await migration.runMigrations(3);
      expect(executedMigrations, [1, 2, 3]);
    });
  });
}
