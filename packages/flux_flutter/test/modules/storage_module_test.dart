import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flux_flutter/src/modules/storage_module.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  late StorageModule storageModule;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storageModule = StorageModule();
  });

  group('String Operations', () {
    test('storage.set and get work correctly', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final getFn = storageModule.get('get') as AsyncNativeFunction;

      await setFn.call(['key1', 'value1']);
      final result = await getFn.call(['key1']);
      expect(result, 'value1');
    });

    test('storage.get returns null for missing key', () async {
      final getFn = storageModule.get('get') as AsyncNativeFunction;
      final result = await getFn.call(['nonexistent']);
      expect(result, null);
    });

    test('storage.remove works', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final removeFn = storageModule.get('remove') as AsyncNativeFunction;
      final getFn = storageModule.get('get') as AsyncNativeFunction;

      await setFn.call(['key2', 'value2']);
      await removeFn.call(['key2']);

      final result = await getFn.call(['key2']);
      expect(result, null);
    });

    test('storage.clear works', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final clearFn = storageModule.get('clear') as AsyncNativeFunction;
      final containsFn =
          storageModule.get('containsKey') as AsyncNativeFunction;

      await setFn.call(['key3', 'value3']);
      await clearFn.call([]);

      final result = await containsFn.call(['key3']);
      expect(result, false);
    });

    test('storage.containsKey works', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final containsFn =
          storageModule.get('containsKey') as AsyncNativeFunction;

      expect(await containsFn.call(['myKey']), false);
      await setFn.call(['myKey', 'myValue']);
      expect(await containsFn.call(['myKey']), true);
    });
  });

  group('JSON Operations', () {
    test('storage.setJson and getJson work with Map', () async {
      final setJsonFn = storageModule.get('setJson') as AsyncNativeFunction;
      final getJsonFn = storageModule.get('getJson') as AsyncNativeFunction;

      final data = {'name': 'John', 'age': 30, 'active': true};
      await setJsonFn.call(['user', data]);

      final result = await getJsonFn.call(['user']);
      expect(result, isA<Map>());
      expect((result as Map)['name'], 'John');
      expect(result['age'], 30);
      expect(result['active'], true);
    });

    test('storage.setJson and getJson work with List', () async {
      final setJsonFn = storageModule.get('setJson') as AsyncNativeFunction;
      final getJsonFn = storageModule.get('getJson') as AsyncNativeFunction;

      final data = [1, 2, 3, 'four', true];
      await setJsonFn.call(['items', data]);

      final result = await getJsonFn.call(['items']);
      expect(result, isA<List>());
      expect((result as List).length, 5);
      expect(result[0], 1);
      expect(result[3], 'four');
      expect(result[4], true);
    });

    test('storage.getJson returns null for missing key', () async {
      final getJsonFn = storageModule.get('getJson') as AsyncNativeFunction;
      final result = await getJsonFn.call(['nonexistent']);
      expect(result, null);
    });

    test('storage.getJson returns null for invalid JSON', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final getJsonFn = storageModule.get('getJson') as AsyncNativeFunction;

      await setFn.call(['badJson', 'not valid json {']);
      final result = await getJsonFn.call(['badJson']);
      expect(result, null);
    });

    test('storage.setJson with nested objects', () async {
      final setJsonFn = storageModule.get('setJson') as AsyncNativeFunction;
      final getJsonFn = storageModule.get('getJson') as AsyncNativeFunction;

      final data = {
        'user': {'name': 'Alice', 'email': 'alice@example.com'},
        'settings': {
          'theme': 'dark',
          'notifications': {'email': true, 'push': false}
        }
      };
      await setJsonFn.call(['config', data]);

      final result = await getJsonFn.call(['config']) as Map;
      expect(result['user']['name'], 'Alice');
      expect(result['settings']['notifications']['push'], false);
    });
  });

  group('Integer Operations', () {
    test('storage.setInt and getInt work correctly', () async {
      final setIntFn = storageModule.get('setInt') as AsyncNativeFunction;
      final getIntFn = storageModule.get('getInt') as AsyncNativeFunction;

      await setIntFn.call(['count', 42]);
      final result = await getIntFn.call(['count']);
      expect(result, 42);
    });

    test('storage.getInt returns null for missing key', () async {
      final getIntFn = storageModule.get('getInt') as AsyncNativeFunction;
      final result = await getIntFn.call(['nonexistent']);
      expect(result, null);
    });

    test('storage.setInt handles double input', () async {
      final setIntFn = storageModule.get('setInt') as AsyncNativeFunction;
      final getIntFn = storageModule.get('getInt') as AsyncNativeFunction;

      await setIntFn.call(['fromDouble', 3.7]);
      final result = await getIntFn.call(['fromDouble']);
      expect(result, 3); // Truncated
    });

    test('storage.setInt handles string input', () async {
      final setIntFn = storageModule.get('setInt') as AsyncNativeFunction;
      final getIntFn = storageModule.get('getInt') as AsyncNativeFunction;

      await setIntFn.call(['fromString', '123']);
      final result = await getIntFn.call(['fromString']);
      expect(result, 123);
    });

    test('storage.setInt handles negative numbers', () async {
      final setIntFn = storageModule.get('setInt') as AsyncNativeFunction;
      final getIntFn = storageModule.get('getInt') as AsyncNativeFunction;

      await setIntFn.call(['negative', -100]);
      final result = await getIntFn.call(['negative']);
      expect(result, -100);
    });
  });

  group('Boolean Operations', () {
    test('storage.setBool and getBool work correctly', () async {
      final setBoolFn = storageModule.get('setBool') as AsyncNativeFunction;
      final getBoolFn = storageModule.get('getBool') as AsyncNativeFunction;

      await setBoolFn.call(['enabled', true]);
      expect(await getBoolFn.call(['enabled']), true);

      await setBoolFn.call(['enabled', false]);
      expect(await getBoolFn.call(['enabled']), false);
    });

    test('storage.getBool returns null for missing key', () async {
      final getBoolFn = storageModule.get('getBool') as AsyncNativeFunction;
      final result = await getBoolFn.call(['nonexistent']);
      expect(result, null);
    });

    test('storage.setBool handles int input', () async {
      final setBoolFn = storageModule.get('setBool') as AsyncNativeFunction;
      final getBoolFn = storageModule.get('getBool') as AsyncNativeFunction;

      await setBoolFn.call(['fromInt1', 1]);
      expect(await getBoolFn.call(['fromInt1']), true);

      await setBoolFn.call(['fromInt0', 0]);
      expect(await getBoolFn.call(['fromInt0']), false);
    });

    test('storage.setBool handles string input', () async {
      final setBoolFn = storageModule.get('setBool') as AsyncNativeFunction;
      final getBoolFn = storageModule.get('getBool') as AsyncNativeFunction;

      await setBoolFn.call(['fromStringTrue', 'true']);
      expect(await getBoolFn.call(['fromStringTrue']), true);

      await setBoolFn.call(['fromStringFalse', 'false']);
      expect(await getBoolFn.call(['fromStringFalse']), false);
    });
  });

  group('Double Operations', () {
    test('storage.setDouble and getDouble work correctly', () async {
      final setDoubleFn = storageModule.get('setDouble') as AsyncNativeFunction;
      final getDoubleFn = storageModule.get('getDouble') as AsyncNativeFunction;

      await setDoubleFn.call(['ratio', 3.14159]);
      final result = await getDoubleFn.call(['ratio']);
      expect(result, closeTo(3.14159, 0.00001));
    });

    test('storage.getDouble returns null for missing key', () async {
      final getDoubleFn = storageModule.get('getDouble') as AsyncNativeFunction;
      final result = await getDoubleFn.call(['nonexistent']);
      expect(result, null);
    });

    test('storage.setDouble handles int input', () async {
      final setDoubleFn = storageModule.get('setDouble') as AsyncNativeFunction;
      final getDoubleFn = storageModule.get('getDouble') as AsyncNativeFunction;

      await setDoubleFn.call(['fromInt', 42]);
      final result = await getDoubleFn.call(['fromInt']);
      expect(result, 42.0);
    });

    test('storage.setDouble handles string input', () async {
      final setDoubleFn = storageModule.get('setDouble') as AsyncNativeFunction;
      final getDoubleFn = storageModule.get('getDouble') as AsyncNativeFunction;

      await setDoubleFn.call(['fromString', '2.718']);
      final result = await getDoubleFn.call(['fromString']);
      expect(result, closeTo(2.718, 0.001));
    });
  });

  group('String List Operations', () {
    test('storage.setStringList and getStringList work correctly', () async {
      final setListFn =
          storageModule.get('setStringList') as AsyncNativeFunction;
      final getListFn =
          storageModule.get('getStringList') as AsyncNativeFunction;

      await setListFn.call([
        'tags',
        ['flutter', 'dart', 'flux']
      ]);

      final result = await getListFn.call(['tags']);
      expect(result, isA<List>());
      expect((result as List).length, 3);
      expect(result[0], 'flutter');
      expect(result[1], 'dart');
      expect(result[2], 'flux');
    });

    test('storage.getStringList returns null for missing key', () async {
      final getListFn =
          storageModule.get('getStringList') as AsyncNativeFunction;
      final result = await getListFn.call(['nonexistent']);
      expect(result, null);
    });

    test('storage.setStringList handles mixed types', () async {
      final setListFn =
          storageModule.get('setStringList') as AsyncNativeFunction;
      final getListFn =
          storageModule.get('getStringList') as AsyncNativeFunction;

      // Mixed types should be converted to strings
      await setListFn.call([
        'mixed',
        [1, 'two', 3.0, true]
      ]);

      final result = await getListFn.call(['mixed']);
      expect(result, isA<List>());
      expect((result as List).length, 4);
      expect(result[0], '1');
      expect(result[1], 'two');
      expect(result[2], '3.0');
      expect(result[3], 'true');
    });
  });

  group('Utility Operations', () {
    test('storage.getKeys returns all keys', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final setIntFn = storageModule.get('setInt') as AsyncNativeFunction;
      final getKeysFn = storageModule.get('getKeys') as AsyncNativeFunction;

      await setFn.call(['key1', 'value1']);
      await setFn.call(['key2', 'value2']);
      await setIntFn.call(['key3', 42]);

      final result = await getKeysFn.call([]);
      expect(result, isA<List>());
      expect((result as List).length, 3);
      expect(result, containsAll(['key1', 'key2', 'key3']));
    });

    test('storage.getKeys returns empty list when empty', () async {
      final getKeysFn = storageModule.get('getKeys') as AsyncNativeFunction;
      final result = await getKeysFn.call([]);
      expect(result, isA<List>());
      expect((result as List).length, 0);
    });
  });

  group('Edge Cases', () {
    test('storage operations with empty strings', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final getFn = storageModule.get('get') as AsyncNativeFunction;

      await setFn.call(['emptyValue', '']);
      final result = await getFn.call(['emptyValue']);
      expect(result, '');
    });

    test('storage operations with special characters', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final getFn = storageModule.get('get') as AsyncNativeFunction;

      const specialValue = 'Hello! @#\$%^&*()_+{}|:"<>?~`-=[]\\;\',./\n\t';
      await setFn.call(['special', specialValue]);
      final result = await getFn.call(['special']);
      expect(result, specialValue);
    });

    test('storage operations with unicode characters', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final getFn = storageModule.get('get') as AsyncNativeFunction;

      const unicodeValue = '你好世界 🌍 مرحبا العالم 🎉';
      await setFn.call(['unicode', unicodeValue]);
      final result = await getFn.call(['unicode']);
      expect(result, unicodeValue);
    });

    test('overwriting existing keys', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final getFn = storageModule.get('get') as AsyncNativeFunction;

      await setFn.call(['overwrite', 'first']);
      expect(await getFn.call(['overwrite']), 'first');

      await setFn.call(['overwrite', 'second']);
      expect(await getFn.call(['overwrite']), 'second');
    });

    test('set with null value converts to empty string', () async {
      final setFn = storageModule.get('set') as AsyncNativeFunction;
      final getFn = storageModule.get('get') as AsyncNativeFunction;

      await setFn.call(['nullValue', null]);
      final result = await getFn.call(['nullValue']);
      expect(result, '');
    });
  });
}
