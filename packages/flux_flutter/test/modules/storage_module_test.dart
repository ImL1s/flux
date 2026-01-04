import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flux_flutter/src/modules/storage_module.dart';
import 'package:flux_vm/flux_vm.dart';

// No mockito needed for SharedPreferences as it has a built-in mock mechanism
// via SharedPreferences.setMockInitialValues
void main() {
  late StorageModule storageModule;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storageModule = StorageModule();
  });

  test('storage.set and get work correctly', () async {
    final setFn = storageModule.get('set') as AsyncNativeFunction;
    final getFn = storageModule.get('get') as AsyncNativeFunction;

    // Set value
    await setFn.call(['key1', 'value1']);

    // Get value
    final result = await getFn.call(['key1']);
    expect(result, 'value1');
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
    final containsFn = storageModule.get('containsKey') as AsyncNativeFunction;

    await setFn.call(['key3', 'value3']);
    await clearFn.call([]);

    final result = await containsFn.call(['key3']);
    expect(result, false);
  });
}
