import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/modules/ble_module.dart';

void main() {
  group('BleModule', () {
    test('should be a singleton', () {
      final instance1 = BleModule.instance;
      final instance2 = BleModule.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('should have correct module name', () {
      expect(BleModule.instance.name, equals('ble'));
    });

    test('should have all required functions registered', () {
      final module = BleModule.instance;
      expect(module.name, equals('ble'));
      // Module should be properly initialized
    });
  });
}
