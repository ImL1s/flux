import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';

class MockPlugin extends FluxPlugin {
  bool loaded = false;
  bool unloaded = false;

  @override
  String get id => 'test.plugin';
  @override
  String get name => 'Test Plugin';
  @override
  String get version => '1.0.0';

  @override
  void onLoad(VM vm) {
    loaded = true;
    vm.globals['plugin_fn'] = NativeFunction('plugin_fn', 0, (args) => 'hello from plugin');
  }

  @override
  void onUnload(VM vm) {
    unloaded = true;
    vm.globals.remove('plugin_fn');
  }
}

void main() {
  group('Plugin System', () {
    late VM vm;

    setUp(() {
      vm = VM();
    });

    test('registers and loads plugin', () {
      final plugin = MockPlugin();
      vm.pluginRegistry.register(plugin);

      expect(plugin.loaded, isTrue);
      expect(vm.pluginRegistry.get('test.plugin'), equals(plugin));
      expect(vm.globals.containsKey('plugin_fn'), isTrue);
      
      final result = vm.interpret('return plugin_fn();');
      expect(result, equals(InterpretResult.ok));
      expect(vm.stack.last, equals('hello from plugin'));
    });

    test('prevents duplicate registration', () {
      final plugin = MockPlugin();
      vm.pluginRegistry.register(plugin);
      expect(() => vm.pluginRegistry.register(plugin), throwsA(contains('already registered')));
    });

    test('unloads plugin', () {
      final plugin = MockPlugin();
      vm.pluginRegistry.register(plugin);
      vm.pluginRegistry.unregister('test.plugin');

      expect(plugin.unloaded, isTrue);
      expect(vm.pluginRegistry.get('test.plugin'), isNull);
      expect(vm.globals.containsKey('plugin_fn'), isFalse);
    });

    test('lists all plugins', () {
      final plugin = MockPlugin();
      vm.pluginRegistry.register(plugin);
      expect(vm.pluginRegistry.all.length, equals(1));
      expect(vm.pluginRegistry.all.first.id, equals('test.plugin'));
    });
  });
}
