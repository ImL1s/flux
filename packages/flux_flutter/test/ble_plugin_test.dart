import 'package:flutter_test/flutter_test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_flutter/src/plugins/ble_plugin.dart';
import 'package:flux_flutter/src/modules/ble_module.dart';
import 'package:mocktail/mocktail.dart';

class MockVM extends Mock implements VM {}
class MockBleWrapper extends Mock implements BleWrapper {}

void main() {
  late VM vm;
  late PluginRegistry registry;

  setUp(() {
    vm = VM();
    // In real app, registry is part of VM
    registry = vm.pluginRegistry;
  });

  group('BlePlugin Sandboxing', () {
    test('should load BlePlugin when ble permission is allowed', () {
      final allowedPermissions = [FluxPermissions.ble];
      final bleRegistry = PluginRegistry(vm, allowedPermissions: allowedPermissions);
      
      final mockModule = BleModule.test(MockBleWrapper());
      final plugin = BlePlugin(mockModule);
      bleRegistry.register(plugin);
      
      expect(bleRegistry.get(plugin.id), isNotNull);
      expect(vm.getGlobal('ble'), equals(mockModule));
    });

    test('should reject BlePlugin when ble permission is not allowed', () {
      final allowedPermissions = [FluxPermissions.network]; // Different permission
      final bleRegistry = PluginRegistry(vm, allowedPermissions: allowedPermissions);
      
      final plugin = BlePlugin();
      expect(() => bleRegistry.register(plugin), throwsA(contains('Security Error')));
    });
  });
}
