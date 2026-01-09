import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/modules/hive_storage_module.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  late HiveStorageModule hiveModule;
  late Directory tempDir;

  setUpAll(() async {
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
  });

  tearDownAll(() async {
    // Clean up temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    // Use testPath to avoid path_provider dependency in tests
    hiveModule = HiveStorageModule(testPath: tempDir.path);
  });

  tearDown(() async {
    // Clean up boxes after each test
    await hiveModule.dispose();
  });

  group('Box Lifecycle', () {
    test('hive.openBox opens a box', () async {
      final openBoxFn = hiveModule.get('openBox') as AsyncNativeFunction;

      final result = await openBoxFn.call(['testBox1']);
      expect(result, true);
    });

    test('hive.isBoxOpen returns correct status', () async {
      final openBoxFn = hiveModule.get('openBox') as AsyncNativeFunction;
      final isBoxOpenFn = hiveModule.get('isBoxOpen') as NativeFunction;

      expect(isBoxOpenFn.call(['unopenedBox']), false);

      await openBoxFn.call(['myBox']);
      expect(isBoxOpenFn.call(['myBox']), true);
    });

    test('hive.closeBox closes a box', () async {
      final openBoxFn = hiveModule.get('openBox') as AsyncNativeFunction;
      final closeBoxFn = hiveModule.get('closeBox') as AsyncNativeFunction;
      final isBoxOpenFn = hiveModule.get('isBoxOpen') as NativeFunction;

      await openBoxFn.call(['boxToClose']);
      expect(isBoxOpenFn.call(['boxToClose']), true);

      await closeBoxFn.call(['boxToClose']);
      expect(isBoxOpenFn.call(['boxToClose']), false);
    });

    test('hive.openBox on already open box returns true', () async {
      final openBoxFn = hiveModule.get('openBox') as AsyncNativeFunction;

      await openBoxFn.call(['doubleOpen']);
      final result = await openBoxFn.call(['doubleOpen']);
      expect(result, true);
    });
  });

  group('CRUD Operations', () {
    test('hive.put and get work with Map', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getFn = hiveModule.get('get') as AsyncNativeFunction;

      final data = {'name': 'Alice', 'age': 25, 'active': true};
      await putFn.call(['users', 'alice', data]);

      final result = await getFn.call(['users', 'alice']);
      expect(result, isA<Map>());
      expect((result as Map)['name'], 'Alice');
      expect(result['age'], 25);
      expect(result['active'], true);
    });

    test('hive.put and get work with List', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getFn = hiveModule.get('get') as AsyncNativeFunction;

      final data = [1, 2, 3, 'four', true];
      await putFn.call(['lists', 'myList', data]);

      final result = await getFn.call(['lists', 'myList']);
      expect(result, isA<List>());
      expect((result as List).length, 5);
    });

    test('hive.put and get work with primitives', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getFn = hiveModule.get('get') as AsyncNativeFunction;

      await putFn.call(['primitives', 'string', 'hello']);
      await putFn.call(['primitives', 'number', 42]);
      await putFn.call(['primitives', 'boolean', true]);
      await putFn.call(['primitives', 'null', null]);

      expect(await getFn.call(['primitives', 'string']), 'hello');
      expect(await getFn.call(['primitives', 'number']), 42);
      expect(await getFn.call(['primitives', 'boolean']), true);
      expect(await getFn.call(['primitives', 'null']), null);
    });

    test('hive.get returns null for missing key', () async {
      final openBoxFn = hiveModule.get('openBox') as AsyncNativeFunction;
      final getFn = hiveModule.get('get') as AsyncNativeFunction;

      await openBoxFn.call(['emptyBox']);
      final result = await getFn.call(['emptyBox', 'nonexistent']);
      expect(result, null);
    });

    test('hive.delete removes a key', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getFn = hiveModule.get('get') as AsyncNativeFunction;
      final deleteFn = hiveModule.get('delete') as AsyncNativeFunction;

      await putFn.call(['deleteBox', 'toDelete', 'value']);
      expect(await getFn.call(['deleteBox', 'toDelete']), 'value');

      await deleteFn.call(['deleteBox', 'toDelete']);
      expect(await getFn.call(['deleteBox', 'toDelete']), null);
    });

    test('hive.clear removes all entries', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final clearFn = hiveModule.get('clear') as AsyncNativeFunction;
      final countFn = hiveModule.get('count') as AsyncNativeFunction;

      await putFn.call(['clearBox', 'key1', 'value1']);
      await putFn.call(['clearBox', 'key2', 'value2']);
      await putFn.call(['clearBox', 'key3', 'value3']);

      expect(await countFn.call(['clearBox']), 3);

      await clearFn.call(['clearBox']);
      expect(await countFn.call(['clearBox']), 0);
    });

    test('hive.put overwrites existing key', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getFn = hiveModule.get('get') as AsyncNativeFunction;

      await putFn.call(['overwrite', 'key', 'first']);
      expect(await getFn.call(['overwrite', 'key']), 'first');

      await putFn.call(['overwrite', 'key', 'second']);
      expect(await getFn.call(['overwrite', 'key']), 'second');
    });
  });

  group('Query Operations', () {
    test('hive.getAll returns all values', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getAllFn = hiveModule.get('getAll') as AsyncNativeFunction;

      await putFn.call([
        'getAllBox',
        'user1',
        {'name': 'Alice'}
      ]);
      await putFn.call([
        'getAllBox',
        'user2',
        {'name': 'Bob'}
      ]);
      await putFn.call([
        'getAllBox',
        'user3',
        {'name': 'Charlie'}
      ]);

      final result = await getAllFn.call(['getAllBox']);
      expect(result, isA<List>());
      expect((result as List).length, 3);

      final names = result.map((e) => (e as Map)['name']).toList();
      expect(names, containsAll(['Alice', 'Bob', 'Charlie']));
    });

    test('hive.getAllKeys returns all keys', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getAllKeysFn = hiveModule.get('getAllKeys') as AsyncNativeFunction;

      await putFn.call(['keysBox', 'keyA', 'valueA']);
      await putFn.call(['keysBox', 'keyB', 'valueB']);
      await putFn.call(['keysBox', 'keyC', 'valueC']);

      final result = await getAllKeysFn.call(['keysBox']);
      expect(result, isA<List>());
      expect(result, containsAll(['keyA', 'keyB', 'keyC']));
    });

    test('hive.containsKey returns correct result', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final containsKeyFn =
          hiveModule.get('containsKey') as AsyncNativeFunction;

      await putFn.call(['containsBox', 'exists', 'value']);

      expect(await containsKeyFn.call(['containsBox', 'exists']), true);
      expect(await containsKeyFn.call(['containsBox', 'notExists']), false);
    });

    test('hive.count returns number of entries', () async {
      final openBoxFn = hiveModule.get('openBox') as AsyncNativeFunction;
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final countFn = hiveModule.get('count') as AsyncNativeFunction;

      await openBoxFn.call(['countBox']);
      expect(await countFn.call(['countBox']), 0);

      await putFn.call(['countBox', 'key1', 'value1']);
      expect(await countFn.call(['countBox']), 1);

      await putFn.call(['countBox', 'key2', 'value2']);
      expect(await countFn.call(['countBox']), 2);
    });
  });

  group('Complex Data', () {
    test('hive stores nested objects correctly', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getFn = hiveModule.get('get') as AsyncNativeFunction;

      final complexData = {
        'user': {
          'name': 'Alice',
          'profile': {
            'bio': 'Developer',
            'social': {'twitter': '@alice', 'github': 'alice'}
          }
        },
        'settings': {
          'theme': 'dark',
          'notifications': {'email': true, 'push': false}
        }
      };

      await putFn.call(['complex', 'nested', complexData]);
      final result = await getFn.call(['complex', 'nested']) as Map;

      expect(result['user']['profile']['social']['github'], 'alice');
      expect(result['settings']['notifications']['push'], false);
    });

    test('hive stores arrays of objects', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getFn = hiveModule.get('get') as AsyncNativeFunction;

      final users = [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
        {'id': 3, 'name': 'Charlie'},
      ];

      await putFn.call(['arrayBox', 'users', users]);
      final result = await getFn.call(['arrayBox', 'users']) as List;

      expect(result.length, 3);
      expect(result[1]['name'], 'Bob');
    });
  });

  group('Edge Cases', () {
    test('special characters in keys', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getFn = hiveModule.get('get') as AsyncNativeFunction;

      await putFn.call(['specialKeys', 'key with spaces', 'value1']);
      await putFn.call(['specialKeys', 'key-with-dashes', 'value2']);
      await putFn.call(['specialKeys', 'key_with_underscores', 'value3']);

      expect(await getFn.call(['specialKeys', 'key with spaces']), 'value1');
      expect(await getFn.call(['specialKeys', 'key-with-dashes']), 'value2');
      expect(
          await getFn.call(['specialKeys', 'key_with_underscores']), 'value3');
    });

    test('unicode data', () async {
      final putFn = hiveModule.get('put') as AsyncNativeFunction;
      final getFn = hiveModule.get('get') as AsyncNativeFunction;

      final unicodeData = {
        'chinese': '你好世界',
        'emoji': '🎉🌍🚀',
        'arabic': 'مرحبا العالم'
      };

      await putFn.call(['unicodeBox', 'data', unicodeData]);
      final result = await getFn.call(['unicodeBox', 'data']) as Map;

      expect(result['chinese'], '你好世界');
      expect(result['emoji'], '🎉🌍🚀');
      expect(result['arabic'], 'مرحبا العالم');
    });

    test('empty box operations', () async {
      final openBoxFn = hiveModule.get('openBox') as AsyncNativeFunction;
      final getAllFn = hiveModule.get('getAll') as AsyncNativeFunction;
      final getAllKeysFn = hiveModule.get('getAllKeys') as AsyncNativeFunction;
      final countFn = hiveModule.get('count') as AsyncNativeFunction;

      await openBoxFn.call(['emptyOpsBox']);

      expect(await getAllFn.call(['emptyOpsBox']), isEmpty);
      expect(await getAllKeysFn.call(['emptyOpsBox']), isEmpty);
      expect(await countFn.call(['emptyOpsBox']), 0);
    });
  });
}
