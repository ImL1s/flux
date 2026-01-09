import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_vm/src/plugin.dart';

class MockPlugin extends FluxPlugin {
  @override
  final String id;
  @override
  final List<String> permissions;

  MockPlugin(this.id, {this.permissions = const []});

  @override
  String get name => 'Mock Plugin';
  @override
  String get version => '1.0.0';

  @override
  void onLoad(VM vm) {}
}

void main() {
  group('Plugin Sandbox', () {
    late VM vm;

    setUp(() {
      vm = VM();
    });

    test('should allow plugin with no permissions', () {
      final registry = PluginRegistry(vm, allowedPermissions: ['flux.permission.NETWORK']);
      final plugin = MockPlugin('com.example.safe');
      
      registry.register(plugin);
      expect(registry.get('com.example.safe'), isNotNull);
    });

    test('should allow plugin with allowed permissions', () {
      final registry = PluginRegistry(vm, allowedPermissions: ['flux.permission.NETWORK']);
      final plugin = MockPlugin('com.example.net', permissions: ['flux.permission.NETWORK']);
      
      registry.register(plugin);
      expect(registry.get('com.example.net'), isNotNull);
    });

    test('should reject plugin with disallowed permissions', () {
      final registry = PluginRegistry(vm, allowedPermissions: ['flux.permission.NETWORK']);
      final plugin = MockPlugin('com.example.fs', permissions: ['flux.permission.FILE_SYSTEM']);
      
      expect(() => registry.register(plugin), throwsA(stringContainsInOrder(['Security Error', 'unauthorized permission'])));
      expect(registry.get('com.example.fs'), isNull);
    });

    test('should reject plugin with mixed permissions (one valid, one invalid)', () {
      final registry = PluginRegistry(vm, allowedPermissions: ['flux.permission.NETWORK']);
      final plugin = MockPlugin('com.example.mixed', permissions: ['flux.permission.NETWORK', 'flux.permission.FILE_SYSTEM']);
      
      expect(() => registry.register(plugin), throwsA(stringContainsInOrder(['Security Error', 'unauthorized permission'])));
    });

    test('should allow all permissions if allowedPermissions is null', () {
      final registry = PluginRegistry(vm, allowedPermissions: null);
      final plugin = MockPlugin('com.example.all', permissions: ['flux.permission.super.admin']);
      
      registry.register(plugin);
      expect(registry.get('com.example.all'), isNotNull);
    });
  });
}
