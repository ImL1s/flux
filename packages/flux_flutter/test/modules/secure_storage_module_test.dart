

import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/modules/secure_storage_module.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureStorageModule secureModule;
  late MockFlutterSecureStorage mockStorage;
  late Map<String, String> fakeStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    fakeStorage = {};

    // Mock read
    when(() => mockStorage.read(
          key: any(named: 'key'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((invocation) async {
      final key = invocation.namedArguments[const Symbol('key')] as String;
      return fakeStorage[key];
    });

    // Mock write
    when(() => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((invocation) async {
      final key = invocation.namedArguments[const Symbol('key')] as String;
      final value = invocation.namedArguments[const Symbol('value')] as String;
      fakeStorage[key] = value;
    });

    // Mock delete
    when(() => mockStorage.delete(
          key: any(named: 'key'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((invocation) async {
      final key = invocation.namedArguments[const Symbol('key')] as String;
      fakeStorage.remove(key);
    });

    // Mock deleteAll
    when(() => mockStorage.deleteAll(
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((_) async {
      fakeStorage.clear();
    });

    // Mock containsKey
    when(() => mockStorage.containsKey(
          key: any(named: 'key'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((invocation) async {
      final key = invocation.namedArguments[const Symbol('key')] as String;
      return fakeStorage.containsKey(key);
    });

    // Mock readAll
    when(() => mockStorage.readAll(
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((_) async => Map.from(fakeStorage));

    secureModule = SecureStorageModule(storage: mockStorage);
  });

  group('Basic CRUD', () {
    test('secure.set and get work correctly', () async {
      final setFn = secureModule.get('set') as AsyncNativeFunction;
      final getFn = secureModule.get('get') as AsyncNativeFunction;

      await setFn.call(['apiToken', 'secret_token_123']);
      final result = await getFn.call(['apiToken']);

      expect(result, 'secret_token_123');
    });

    test('secure.get returns null for missing key', () async {
      final getFn = secureModule.get('get') as AsyncNativeFunction;

      final result = await getFn.call(['nonexistent']);
      expect(result, null);
    });

    test('secure.delete removes key', () async {
      final setFn = secureModule.get('set') as AsyncNativeFunction;
      final getFn = secureModule.get('get') as AsyncNativeFunction;
      final deleteFn = secureModule.get('delete') as AsyncNativeFunction;

      await setFn.call(['toDelete', 'value']);
      expect(await getFn.call(['toDelete']), 'value');

      await deleteFn.call(['toDelete']);
      expect(await getFn.call(['toDelete']), null);
    });

    test('secure.deleteAll clears all storage', () async {
      final setFn = secureModule.get('set') as AsyncNativeFunction;
      final deleteAllFn = secureModule.get('deleteAll') as AsyncNativeFunction;
      final getAllKeysFn = secureModule.get('getAllKeys') as AsyncNativeFunction;

      await setFn.call(['key1', 'value1']);
      await setFn.call(['key2', 'value2']);
      await setFn.call(['key3', 'value3']);

      final keysBefore = await getAllKeysFn.call([]) as List;
      expect(keysBefore.length, 3);

      await deleteAllFn.call([]);

      final keysAfter = await getAllKeysFn.call([]) as List;
      expect(keysAfter, isEmpty);
    });

    test('secure.containsKey returns correct status', () async {
      final setFn = secureModule.get('set') as AsyncNativeFunction;
      final containsKeyFn = secureModule.get('containsKey') as AsyncNativeFunction;

      await setFn.call(['exists', 'value']);

      expect(await containsKeyFn.call(['exists']), true);
      expect(await containsKeyFn.call(['notExists']), false);
    });
  });

  group('JSON Operations', () {
    test('secure.setJson and getJson work with Map', () async {
      final setJsonFn = secureModule.get('setJson') as AsyncNativeFunction;
      final getJsonFn = secureModule.get('getJson') as AsyncNativeFunction;

      final credentials = {'username': 'admin', 'password': 'secret123'};
      await setJsonFn.call(['credentials', credentials]);

      final result = await getJsonFn.call(['credentials']);
      expect(result, isA<Map>());
      expect((result as Map)['username'], 'admin');
      expect(result['password'], 'secret123');
    });

    test('secure.setJson and getJson work with List', () async {
      final setJsonFn = secureModule.get('setJson') as AsyncNativeFunction;
      final getJsonFn = secureModule.get('getJson') as AsyncNativeFunction;

      final tokens = ['token1', 'token2', 'token3'];
      await setJsonFn.call(['tokens', tokens]);

      final result = await getJsonFn.call(['tokens']);
      expect(result, isA<List>());
      expect((result as List).length, 3);
    });

    test('secure.setJson and getJson work with primitives', () async {
      final setJsonFn = secureModule.get('setJson') as AsyncNativeFunction;
      final getJsonFn = secureModule.get('getJson') as AsyncNativeFunction;

      await setJsonFn.call(['number', 42]);
      await setJsonFn.call(['boolean', true]);
      await setJsonFn.call(['string', 'hello']);

      expect(await getJsonFn.call(['number']), 42);
      expect(await getJsonFn.call(['boolean']), true);
      expect(await getJsonFn.call(['string']), 'hello');
    });

    test('secure.getJson returns null for missing key', () async {
      final getJsonFn = secureModule.get('getJson') as AsyncNativeFunction;

      final result = await getJsonFn.call(['nonexistent']);
      expect(result, null);
    });

    test('secure.setJson stores nested objects', () async {
      final setJsonFn = secureModule.get('setJson') as AsyncNativeFunction;
      final getJsonFn = secureModule.get('getJson') as AsyncNativeFunction;

      final nestedData = {
        'user': {
          'name': 'Alice',
          'credentials': {'apiKey': 'key123', 'apiSecret': 'secret456'}
        }
      };

      await setJsonFn.call(['nested', nestedData]);
      final result = await getJsonFn.call(['nested']) as Map;

      expect(result['user']['credentials']['apiKey'], 'key123');
    });
  });

  group('Utility', () {
    test('secure.getAllKeys returns all keys', () async {
      final setFn = secureModule.get('set') as AsyncNativeFunction;
      final getAllKeysFn = secureModule.get('getAllKeys') as AsyncNativeFunction;

      await setFn.call(['keyA', 'valueA']);
      await setFn.call(['keyB', 'valueB']);
      await setFn.call(['keyC', 'valueC']);

      final result = await getAllKeysFn.call([]) as List;
      expect(result, containsAll(['keyA', 'keyB', 'keyC']));
    });

    test('secure.getAll returns all key-value pairs', () async {
      final setFn = secureModule.get('set') as AsyncNativeFunction;
      final getAllFn = secureModule.get('getAll') as AsyncNativeFunction;

      await setFn.call(['key1', 'value1']);
      await setFn.call(['key2', 'value2']);

      final result = await getAllFn.call([]) as Map;
      expect(result['key1'], 'value1');
      expect(result['key2'], 'value2');
    });
  });

  group('Edge Cases', () {
    test('secure.set converts non-string values to string', () async {
      final setFn = secureModule.get('set') as AsyncNativeFunction;
      final getFn = secureModule.get('get') as AsyncNativeFunction;

      await setFn.call(['number', 42]);
      await setFn.call(['boolean', true]);

      expect(await getFn.call(['number']), '42');
      expect(await getFn.call(['boolean']), 'true');
    });

    test('secure.set handles null value', () async {
      final setFn = secureModule.get('set') as AsyncNativeFunction;
      final getFn = secureModule.get('get') as AsyncNativeFunction;

      await setFn.call(['nullValue', null]);
      expect(await getFn.call(['nullValue']), '');
    });

    test('secure storage handles unicode data', () async {
      final setFn = secureModule.get('set') as AsyncNativeFunction;
      final getFn = secureModule.get('get') as AsyncNativeFunction;

      await setFn.call(['unicode', '你好世界🎉']);
      expect(await getFn.call(['unicode']), '你好世界🎉');
    });

    test('secure.set overwrites existing key', () async {
      final setFn = secureModule.get('set') as AsyncNativeFunction;
      final getFn = secureModule.get('get') as AsyncNativeFunction;

      await setFn.call(['overwrite', 'first']);
      expect(await getFn.call(['overwrite']), 'first');

      await setFn.call(['overwrite', 'second']);
      expect(await getFn.call(['overwrite']), 'second');
    });
  });
}
